package checkin

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// TripChecker verifies trip membership without importing the trips package.
type TripChecker interface {
	IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
}

// Service handles check-in business logic.
type Service struct {
	repo    Repository
	tripChk TripChecker
}

// NewService wires checkin service dependencies.
func NewService(repo Repository, tripChk TripChecker) *Service {
	return &Service{repo: repo, tripChk: tripChk}
}

// CreateCheckin creates a new check-in on a trip.
func (s *Service) CreateCheckin(ctx context.Context, tripID, callerID uuid.UUID, req CreateCheckinRequest) (*CheckinResponse, error) {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return nil, err
	}

	capturedAt, err := time.Parse(time.RFC3339, req.CapturedAt)
	if err != nil {
		capturedAt = time.Now().UTC()
	}

	kind := req.Kind
	if kind == "" {
		kind = "spontaneous"
	}

	params := CreateCheckinParams{
		TripID:     tripID,
		AuthorID:   callerID,
		CapturedAt: capturedAt,
		Lat:        req.Lat,
		Lng:        req.Lng,
		Kind:       kind,
	}
	if req.ItineraryItemID != nil {
		id, err := uuid.Parse(*req.ItineraryItemID)
		if err == nil {
			params.ItineraryItemID = &id
		}
	}

	c, err := s.repo.CreateCheckin(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("create checkin: %w", err)
	}

	resp := toCheckinResponse(c, nil, nil, nil, nil)
	return &resp, nil
}

// GetCheckin returns the full check-in with all layers and media.
func (s *Service) GetCheckin(ctx context.Context, checkinID, callerID uuid.UUID) (*CheckinResponse, error) {
	c, err := s.repo.FindByID(ctx, checkinID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find checkin: %w", err)
	}

	if err := s.checkMember(ctx, c.TripID, callerID); err != nil {
		return nil, err
	}

	mem, _ := s.repo.FindMemory(ctx, checkinID)
	log, _ := s.repo.FindLogistics(ctx, checkinID)
	rec, _ := s.repo.FindRecommendation(ctx, checkinID)
	media, _ := s.repo.ListMediaByCheckinID(ctx, checkinID)

	resp := toCheckinResponse(c, mem, log, rec, media)
	return &resp, nil
}

// UpdateCheckin updates the vibe and/or captured_at fields of a check-in.
func (s *Service) UpdateCheckin(ctx context.Context, checkinID, callerID uuid.UUID, req UpdateCheckinRequest) (*CheckinResponse, error) {
	_, err := s.findAndCheckMember(ctx, checkinID, callerID)
	if err != nil {
		return nil, err
	}

	params := UpdateCheckinParams{}
	if req.Vibe != nil {
		params.Vibe = req.Vibe
	}
	if req.CapturedAt != nil {
		t, err := time.Parse(time.RFC3339, *req.CapturedAt)
		if err != nil {
			return nil, fmt.Errorf("invalid captured_at: %w", err)
		}
		params.CapturedAt = &t
	}

	c, err := s.repo.UpdateCheckin(ctx, checkinID, params)
	if err != nil {
		return nil, fmt.Errorf("update checkin: %w", err)
	}

	mem, _ := s.repo.FindMemory(ctx, checkinID)
	log, _ := s.repo.FindLogistics(ctx, checkinID)
	rec, _ := s.repo.FindRecommendation(ctx, checkinID)
	media, _ := s.repo.ListMediaByCheckinID(ctx, checkinID)

	resp := toCheckinResponse(c, mem, log, rec, media)
	return &resp, nil
}

// UpsertMemory creates or updates the memory layer.
func (s *Service) UpsertMemory(ctx context.Context, checkinID, callerID uuid.UUID, req UpsertMemoryRequest) (*MemoryResponse, error) {
	c, err := s.findAndCheckMember(ctx, checkinID, callerID)
	if err != nil {
		return nil, err
	}
	_ = c

	mem, err := s.repo.UpsertMemory(ctx, checkinID, UpsertMemoryParams{
		Note:       req.Note,
		Mood:       req.Mood,
		SharedWith: req.SharedWith,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert memory: %w", err)
	}

	return &MemoryResponse{
		ID:         mem.ID.String(),
		Note:       mem.Note,
		Mood:       mem.Mood,
		SharedWith: mem.SharedWith,
	}, nil
}

// UpsertLogistics creates or updates the private logistics layer.
// PRIVACY: caller must be a trip member; never exposed to public endpoints.
func (s *Service) UpsertLogistics(ctx context.Context, checkinID, callerID uuid.UUID, req UpsertLogisticsRequest) (*LogisticsResponse, error) {
	_, err := s.findAndCheckMember(ctx, checkinID, callerID)
	if err != nil {
		return nil, err
	}

	l, err := s.repo.UpsertLogistics(ctx, checkinID, UpsertLogisticsParams{
		Cost:     req.Cost,
		Currency: req.Currency,
		Notes:    req.Notes,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert logistics: %w", err)
	}

	return &LogisticsResponse{
		ID:       l.ID.String(),
		Cost:     l.Cost,
		Currency: l.Currency,
		Notes:    l.Notes,
	}, nil
}

// UpsertRecommendation creates or updates the recommendation layer.
func (s *Service) UpsertRecommendation(ctx context.Context, checkinID, callerID uuid.UUID, req UpsertRecommendationRequest) (*RecommendResponse, error) {
	_, err := s.findAndCheckMember(ctx, checkinID, callerID)
	if err != nil {
		return nil, err
	}

	tags := req.Tags
	if tags == nil {
		tags = []string{}
	}

	rec, err := s.repo.UpsertRecommendation(ctx, checkinID, UpsertRecommendationParams{
		Title:  req.Title,
		Body:   req.Body,
		Tags:   tags,
		Rating: req.Rating,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert recommendation: %w", err)
	}

	return &RecommendResponse{
		ID:     rec.ID.String(),
		Title:  rec.Title,
		Body:   rec.Body,
		Tags:   rec.Tags,
		Rating: rec.Rating,
	}, nil
}

// ListCheckins returns all check-ins for a trip (caller must be a member).
func (s *Service) ListCheckins(ctx context.Context, tripID, callerID uuid.UUID) ([]CheckinResponse, error) {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return nil, err
	}
	checkins, err := s.repo.ListByTripID(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list checkins: %w", err)
	}
	out := make([]CheckinResponse, len(checkins))
	for i, c := range checkins {
		mem, _ := s.repo.FindMemory(ctx, c.ID)
		out[i] = toCheckinResponse(c, mem, nil, nil, nil)
	}
	return out, nil
}

func (s *Service) findAndCheckMember(ctx context.Context, checkinID, callerID uuid.UUID) (*Checkin, error) {
	c, err := s.repo.FindByID(ctx, checkinID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find checkin: %w", err)
	}
	if err := s.checkMember(ctx, c.TripID, callerID); err != nil {
		return nil, err
	}
	return c, nil
}

func (s *Service) checkMember(ctx context.Context, tripID, callerID uuid.UUID) error {
	ok, err := s.tripChk.IsMember(ctx, tripID, callerID)
	if err != nil {
		return fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return ErrForbidden
	}
	return nil
}
