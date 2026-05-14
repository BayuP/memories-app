package ai

import (
	"context"
	"errors"
	"fmt"
	"sync"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	anthropicadapter "github.com/BayuP/memories-app/backend/internal/adapter/external/anthropic"
	"github.com/BayuP/memories-app/backend/internal/itinerary"
	"github.com/BayuP/memories-app/backend/internal/trips"
)

// itineraryCreator is the subset of itinerary.Service used by the AI service.
type itineraryCreator interface {
	BulkCreateAI(ctx context.Context, tripID uuid.UUID, inputs []itinerary.AIItemInput) ([]itinerary.ItemResponse, error)
}

var (
	ErrForbidden   = errors.New("forbidden")
	ErrTripNotFound = errors.New("trip not found")
	ErrRateLimit   = errors.New("rate limit exceeded")
)

// RefineRequest is the POST /trips/:id/ai/refine body.
type RefineRequest struct {
	Message string                          `json:"message"`
	History []anthropicadapter.ChatMessage  `json:"history"`
}

// Service handles AI itinerary generation and refinement.
type Service struct {
	tripRepo trips.Repository
	itnSvc   itineraryCreator
	ai       *anthropicadapter.Client

	mu          sync.Mutex
	refineCount map[string]int
}

// NewService wires AI service dependencies.
func NewService(tripRepo trips.Repository, itnSvc *itinerary.Service, ai *anthropicadapter.Client) *Service {
	return &Service{
		tripRepo:    tripRepo,
		itnSvc:      itnSvc,
		ai:          ai,
		refineCount: make(map[string]int),
	}
}

// GenerateItinerary generates AI itinerary items for a trip, replacing existing AI items.
func (s *Service) GenerateItinerary(ctx context.Context, tripID, callerID uuid.UUID) ([]itinerary.ItemResponse, error) {
	trip, err := s.tripRepo.FindByID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrTripNotFound
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

	input := anthropicadapter.GenerateItineraryInput{
		Title:       trip.Title,
		Destination: trip.Destination,
		Vibes:       trip.Vibes,
	}
	if trip.StartDate != nil {
		input.StartDate = trip.StartDate.Format("2006-01-02")
	}
	if trip.EndDate != nil {
		input.EndDate = trip.EndDate.Format("2006-01-02")
	}

	generated, err := s.ai.GenerateItinerary(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("generate itinerary: %w", err)
	}

	// Convert and bulk-save.
	inputs := make([]itinerary.AIItemInput, 0, len(generated))
	for _, g := range generated {
		if g.Day < 1 || g.Title == "" {
			continue
		}
		inputs = append(inputs, itinerary.AIItemInput{
			Day:          g.Day,
			Title:        g.Title,
			Description:  g.Description,
			StartTime:    g.StartTime,
			LocationName: g.LocationName,
			Lat:          g.Lat,
			Lng:          g.Lng,
		})
	}

	items, err := s.itnSvc.BulkCreateAI(ctx, tripID, inputs)
	if err != nil {
		return nil, fmt.Errorf("save ai items: %w", err)
	}
	return items, nil
}

// RefineItinerary sends a refinement message to Claude and returns its reply.
func (s *Service) RefineItinerary(ctx context.Context, tripID, callerID uuid.UUID, req RefineRequest) (string, error) {
	ok, err := s.tripRepo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return "", fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return "", ErrForbidden
	}

	key := tripID.String()
	s.mu.Lock()
	if s.refineCount[key] >= 20 {
		s.mu.Unlock()
		return "", ErrRateLimit
	}
	s.refineCount[key]++
	s.mu.Unlock()

	reply, err := s.ai.RefineItinerary(ctx, req.History, req.Message)
	if err != nil {
		return "", fmt.Errorf("refine: %w", err)
	}
	return reply, nil
}
