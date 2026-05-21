package itinerary

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// TripChecker verifies trip membership without importing the trips package.
type TripChecker interface {
	IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error)
}

// Service handles itinerary business logic.
type Service struct {
	repo    Repository
	tripChk TripChecker
}

// NewService wires itinerary service dependencies.
func NewService(repo Repository, tripChk TripChecker) *Service {
	return &Service{repo: repo, tripChk: tripChk}
}

// ListItems returns all items for a trip, grouped by day in the response.
func (s *Service) ListItems(ctx context.Context, tripID, callerID uuid.UUID) ([]ItemResponse, error) {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return nil, err
	}

	items, err := s.repo.ListByTripID(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list items: %w", err)
	}

	out := make([]ItemResponse, len(items))
	for i, item := range items {
		out[i] = toItemResponse(item)
	}
	return out, nil
}

// CreateItem adds a new itinerary item.
func (s *Service) CreateItem(ctx context.Context, tripID, callerID uuid.UUID, req CreateItemRequest) (*ItemResponse, error) {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return nil, err
	}
	if req.Title == "" {
		return nil, fmt.Errorf("title is required")
	}
	if req.Day < 1 {
		return nil, fmt.Errorf("day must be >= 1")
	}

	item, err := s.repo.CreateItem(ctx, CreateItemParams{
		TripID:       tripID,
		Day:          req.Day,
		StartTime:    req.StartTime,
		EndTime:      req.EndTime,
		Title:        req.Title,
		Description:  req.Description,
		LocationName: req.LocationName,
		Lat:          req.Lat,
		Lng:          req.Lng,
		Source:       "user",
	})
	if err != nil {
		return nil, fmt.Errorf("create item: %w", err)
	}

	r := toItemResponse(item)
	return &r, nil
}

// UpdateItem applies partial updates to an itinerary item.
func (s *Service) UpdateItem(ctx context.Context, tripID, itemID, callerID uuid.UUID, req UpdateItemRequest) (*ItemResponse, error) {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return nil, err
	}

	existing, err := s.repo.FindByID(ctx, itemID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find item: %w", err)
	}
	if existing.TripID != tripID {
		return nil, ErrNotFound
	}

	// Merge patch.
	if req.Day != nil {
		existing.Day = *req.Day
	}
	if req.Title != nil {
		existing.Title = *req.Title
	}
	if req.StartTime != nil {
		existing.StartTime = req.StartTime
	}
	if req.EndTime != nil {
		existing.EndTime = req.EndTime
	}
	if req.Description != nil {
		existing.Description = req.Description
	}
	if req.LocationName != nil {
		existing.LocationName = req.LocationName
	}
	if req.Lat != nil {
		existing.Lat = req.Lat
	}
	if req.Lng != nil {
		existing.Lng = req.Lng
	}

	updated, err := s.repo.UpdateItem(ctx, itemID, UpdateItemParams{
		Day:          existing.Day,
		StartTime:    existing.StartTime,
		EndTime:      existing.EndTime,
		Title:        existing.Title,
		Description:  existing.Description,
		LocationName: existing.LocationName,
		Lat:          existing.Lat,
		Lng:          existing.Lng,
	})
	if err != nil {
		return nil, fmt.Errorf("update item: %w", err)
	}

	r := toItemResponse(updated)
	return &r, nil
}

// DeleteItem removes an itinerary item.
func (s *Service) DeleteItem(ctx context.Context, tripID, itemID, callerID uuid.UUID) error {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return err
	}

	existing, err := s.repo.FindByID(ctx, itemID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotFound
		}
		return fmt.Errorf("find item: %w", err)
	}
	if existing.TripID != tripID {
		return ErrNotFound
	}

	return s.repo.DeleteItem(ctx, itemID)
}

// ReorderItems batch-updates sort_order for itinerary items within a trip.
func (s *Service) ReorderItems(ctx context.Context, tripID, callerID uuid.UUID, req ReorderRequest) error {
	if err := s.checkMember(ctx, tripID, callerID); err != nil {
		return err
	}

	params := make([]ReorderItemParam, 0, len(req.Items))
	for _, item := range req.Items {
		id, err := uuid.Parse(item.ID)
		if err != nil {
			return fmt.Errorf("invalid item id %q: %w", item.ID, err)
		}
		params = append(params, ReorderItemParam{ID: id, SortOrder: item.SortOrder})
	}

	if err := s.repo.ReorderItems(ctx, tripID, params); err != nil {
		return fmt.Errorf("reorder items: %w", err)
	}
	return nil
}

// BulkCreateAI replaces all AI-generated items with new ones.
func (s *Service) BulkCreateAI(ctx context.Context, tripID uuid.UUID, inputs []AIItemInput) ([]ItemResponse, error) {
	if err := s.repo.DeleteByTripIDAndSource(ctx, tripID, "ai"); err != nil {
		return nil, fmt.Errorf("delete ai items: %w", err)
	}

	items := make([]ItemResponse, 0, len(inputs))
	for _, inp := range inputs {
		desc := inp.Description
		loc := inp.LocationName
		lat := inp.Lat
		lng := inp.Lng
		item, err := s.repo.CreateItem(ctx, CreateItemParams{
			TripID:       tripID,
			Day:          inp.Day,
			StartTime:    inp.StartTime,
			Title:        inp.Title,
			Description:  &desc,
			LocationName: &loc,
			Lat:          &lat,
			Lng:          &lng,
			Source:       "ai",
		})
		if err != nil {
			return nil, fmt.Errorf("bulk create ai item: %w", err)
		}
		items = append(items, toItemResponse(item))
	}
	return items, nil
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
