package story

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	anthropicadapter "github.com/BayuP/memories-app/backend/internal/adapter/external/anthropic"
	"github.com/BayuP/memories-app/backend/internal/checkin"
	"github.com/BayuP/memories-app/backend/internal/trips"
)

// TripChecker verifies trip membership without a circular import.
type TripChecker interface {
	IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
}

// Service handles story business logic.
type Service struct {
	repo        Repository
	tripRepo    trips.Repository
	checkinRepo checkin.Repository
	ai          *anthropicadapter.Client
}

// NewService wires story service dependencies.
func NewService(repo Repository, tripRepo trips.Repository, checkinRepo checkin.Repository, ai *anthropicadapter.Client) *Service {
	return &Service{
		repo:        repo,
		tripRepo:    tripRepo,
		checkinRepo: checkinRepo,
		ai:          ai,
	}
}

// GenerateStory builds an AI narrative for a trip from memory notes, moods,
// and recommendations — never logistics — then upserts and returns it.
func (s *Service) GenerateStory(ctx context.Context, tripID, callerID uuid.UUID) (*StoryResponse, error) {
	trip, err := s.tripRepo.FindByID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find trip: %w", err)
	}

	ok, err := s.tripRepo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return nil, fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return nil, ErrForbidden
	}

	checkins, err := s.checkinRepo.ListByTripID(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list checkins: %w", err)
	}

	// Build the prompt context from memory + recommendations only.
	// Logistics are intentionally excluded — they are private data.
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Trip: %s\nDestination: %s\n", trip.Title, trip.Destination))
	if trip.StartDate != nil {
		sb.WriteString(fmt.Sprintf("Start: %s\n", trip.StartDate.Format("2006-01-02")))
	}
	if trip.EndDate != nil {
		sb.WriteString(fmt.Sprintf("End: %s\n", trip.EndDate.Format("2006-01-02")))
	}
	if len(trip.Vibes) > 0 {
		sb.WriteString(fmt.Sprintf("Vibes: %s\n", strings.Join(trip.Vibes, ", ")))
	}

	sb.WriteString("\n--- Check-in Memories & Recommendations ---\n")
	hasContent := false
	for i, c := range checkins {
		mem, _ := s.checkinRepo.FindMemory(ctx, c.ID)
		rec, _ := s.checkinRepo.FindRecommendation(ctx, c.ID)
		// NOTE: FindLogistics is deliberately NOT called here.

		memNote := ""
		memMood := ""
		if mem != nil {
			if mem.Note != nil {
				memNote = *mem.Note
			}
			if mem.Mood != nil {
				memMood = *mem.Mood
			}
		}

		recTitle := ""
		recBody := ""
		if rec != nil {
			recTitle = rec.Title
			recBody = rec.Body
		}

		// Only include check-ins that have at least some content.
		if memNote == "" && memMood == "" && recTitle == "" && recBody == "" {
			continue
		}

		hasContent = true
		sb.WriteString(fmt.Sprintf("\nCheck-in %d:\n", i+1))
		if c.Vibe != nil {
			sb.WriteString(fmt.Sprintf("  Vibe: %s\n", *c.Vibe))
		}
		if memMood != "" {
			sb.WriteString(fmt.Sprintf("  Mood: %s\n", memMood))
		}
		if memNote != "" {
			sb.WriteString(fmt.Sprintf("  Note: %s\n", memNote))
		}
		if recTitle != "" {
			sb.WriteString(fmt.Sprintf("  Recommendation: %s", recTitle))
			if recBody != "" {
				sb.WriteString(fmt.Sprintf(" — %s", recBody))
			}
			sb.WriteString("\n")
		}
	}

	if !hasContent {
		sb.WriteString("(No memory notes or recommendations recorded yet.)\n")
	}

	prompt := sb.String() + "\n\n" +
		"Write a vivid, first-person travel narrative for this trip. " +
		"The story should be 2-4 paragraphs, warmly personal, and capture the mood and highlights. " +
		"Return a JSON object with exactly two fields: \"title\" (a short evocative trip title, 5-10 words) " +
		"and \"body\" (the full narrative text). Return ONLY the JSON object, no markdown, no preamble."

	// Reuse the existing anthropic client via RefineItinerary which accepts free-form prompts.
	// We send it as a single user message to get a prose+JSON response back.
	raw, err := s.ai.RefineItinerary(ctx, nil, prompt)
	if err != nil {
		return nil, fmt.Errorf("generate story: %w", err)
	}

	title, body := parseStoryJSON(raw)

	status := "generated"
	story, err := s.repo.UpsertStory(ctx, tripID, UpsertStoryParams{
		Title:  &title,
		Body:   &body,
		Status: &status,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert story: %w", err)
	}

	resp := toStoryResponse(story)
	return &resp, nil
}

// GetStory returns the saved story for a trip (member only).
func (s *Service) GetStory(ctx context.Context, tripID, callerID uuid.UUID) (*StoryResponse, error) {
	ok, err := s.tripRepo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return nil, fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return nil, ErrForbidden
	}

	story, err := s.repo.FindByTripID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find story: %w", err)
	}

	resp := toStoryResponse(story)
	return &resp, nil
}

// PatchStory applies manual edits to a story's title and/or body (member only).
func (s *Service) PatchStory(ctx context.Context, tripID, callerID uuid.UUID, req PatchStoryRequest) (*StoryResponse, error) {
	ok, err := s.tripRepo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return nil, fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return nil, ErrForbidden
	}

	// Load current story to apply partial patch.
	current, err := s.repo.FindByTripID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find story: %w", err)
	}

	params := UpsertStoryParams{
		Title:  current.Title,
		Body:   current.Body,
		Status: current.Status,
	}
	if req.Title != nil {
		params.Title = req.Title
	}
	if req.Body != nil {
		params.Body = req.Body
	}
	// Mark as edited once manually modified.
	edited := "edited"
	params.Status = &edited

	story, err := s.repo.UpsertStory(ctx, tripID, params)
	if err != nil {
		return nil, fmt.Errorf("patch story: %w", err)
	}

	resp := toStoryResponse(story)
	return &resp, nil
}

// parseStoryJSON extracts title and body from the Claude JSON response.
// Falls back gracefully if the response is not well-formed JSON.
func parseStoryJSON(raw string) (title, body string) {
	// Trim any accidental markdown code fences.
	raw = strings.TrimSpace(raw)
	raw = strings.TrimPrefix(raw, "```json")
	raw = strings.TrimPrefix(raw, "```")
	raw = strings.TrimSuffix(raw, "```")
	raw = strings.TrimSpace(raw)

	// Simple manual extraction to avoid an extra import.
	// Looks for "title": "..." and "body": "..."
	title = extractJSONString(raw, "title")
	body = extractJSONString(raw, "body")
	if title == "" {
		title = "My Trip Story"
	}
	if body == "" {
		body = raw // store the raw response if parsing fails
	}
	return title, body
}

// extractJSONString extracts the value of a simple top-level JSON string field.
func extractJSONString(src, field string) string {
	key := `"` + field + `"`
	idx := strings.Index(src, key)
	if idx < 0 {
		return ""
	}
	rest := src[idx+len(key):]
	// Skip whitespace and colon.
	rest = strings.TrimLeft(rest, " \t\n\r:")
	if len(rest) == 0 || rest[0] != '"' {
		return ""
	}
	rest = rest[1:] // skip opening quote
	var out strings.Builder
	escaped := false
	for _, ch := range rest {
		if escaped {
			switch ch {
			case 'n':
				out.WriteRune('\n')
			case 't':
				out.WriteRune('\t')
			case '"':
				out.WriteRune('"')
			case '\\':
				out.WriteRune('\\')
			default:
				out.WriteRune(ch)
			}
			escaped = false
			continue
		}
		if ch == '\\' {
			escaped = true
			continue
		}
		if ch == '"' {
			break
		}
		out.WriteRune(ch)
	}
	return out.String()
}
