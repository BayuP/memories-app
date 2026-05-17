package publish

import (
	"context"
	"errors"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

var ErrNotFound = errors.New("trip not found or not published")

// Service handles public trip read logic.
type Service struct {
	repo Repository
}

// NewService wires publish service dependencies.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// GetPublicTrip returns the public view of a published trip.
func (s *Service) GetPublicTrip(ctx context.Context, tripID uuid.UUID) (*PublicTripDetailResponse, error) {
	trip, err := s.repo.FindPublishedTrip(ctx, tripID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find trip: %w", err)
	}

	items, err := s.repo.ListItemsByTripID(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list items: %w", err)
	}

	checkins, err := s.repo.ListPublicCheckinsByTripID(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list checkins: %w", err)
	}

	itemResponses := make([]PublicItemResponse, len(items))
	for i, item := range items {
		itemResponses[i] = toPublicItemResponse(item)
	}

	checkinResponses := make([]PublicCheckinResponse, len(checkins))
	for i, c := range checkins {
		checkinResponses[i] = toPublicCheckinResponse(c)
	}

	return &PublicTripDetailResponse{
		Trip:     toPublicTripResponse(trip),
		Items:    itemResponses,
		Checkins: checkinResponses,
	}, nil
}
