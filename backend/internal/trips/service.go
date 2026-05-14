package trips

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/google/uuid"
)

// Service handles trip business logic and permission enforcement.
type Service struct {
	repo Repository
}

// NewService wires trip service dependencies.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// CreateTrip creates a trip and auto-enrols the owner as a member.
func (s *Service) CreateTrip(ctx context.Context, ownerID uuid.UUID, req CreateTripRequest) (*TripDetailResponse, error) {
	trip, err := s.repo.CreateTrip(ctx, CreateTripParams{
		OwnerID:     ownerID,
		Title:       req.Title,
		Destination: req.Destination,
		StartDate:   parseDate(req.StartDate),
		EndDate:     parseDate(req.EndDate),
		Vibes:       req.Vibes,
	})
	if err != nil {
		return nil, fmt.Errorf("create trip: %w", err)
	}

	owner, err := s.repo.AddMember(ctx, trip.ID, ownerID, "owner")
	if err != nil {
		return nil, fmt.Errorf("add owner member: %w", err)
	}

	return toTripDetail(trip, []*Member{owner}), nil
}

// GetTrip returns full trip detail for a member.
func (s *Service) GetTrip(ctx context.Context, tripID, callerID uuid.UUID) (*TripDetailResponse, error) {
	trip, err := s.repo.FindByID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get trip: %w", err)
	}

	ok, err := s.repo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return nil, fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return nil, ErrForbidden
	}

	members, err := s.repo.ListMembers(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list members: %w", err)
	}

	return toTripDetail(trip, members), nil
}

// ListTrips returns all trips the caller belongs to.
func (s *Service) ListTrips(ctx context.Context, callerID uuid.UUID) ([]*TripResponse, error) {
	trips, err := s.repo.ListByUserID(ctx, callerID)
	if err != nil {
		return nil, fmt.Errorf("list trips: %w", err)
	}

	out := make([]*TripResponse, len(trips))
	for i, t := range trips {
		r := toTripResponse(t)
		out[i] = &r
	}
	return out, nil
}

// UpdateTrip applies partial updates to a trip (members only).
func (s *Service) UpdateTrip(ctx context.Context, tripID, callerID uuid.UUID, req UpdateTripRequest) (*TripDetailResponse, error) {
	trip, err := s.repo.FindByID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("find trip: %w", err)
	}

	ok, err := s.repo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return nil, fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return nil, ErrForbidden
	}

	// Merge patch fields.
	if req.Title != nil {
		trip.Title = *req.Title
	}
	if req.Destination != nil {
		trip.Destination = *req.Destination
	}
	if req.StartDate != nil {
		trip.StartDate = parseDate(req.StartDate)
	}
	if req.EndDate != nil {
		trip.EndDate = parseDate(req.EndDate)
	}
	if req.Vibes != nil {
		trip.Vibes = req.Vibes
	}
	if req.Status != nil {
		trip.Status = *req.Status
	}

	updated, err := s.repo.UpdateTrip(ctx, tripID, UpdateTripParams{
		Title:       trip.Title,
		Destination: trip.Destination,
		StartDate:   trip.StartDate,
		EndDate:     trip.EndDate,
		Vibes:       trip.Vibes,
		Status:      trip.Status,
	})
	if err != nil {
		return nil, fmt.Errorf("update trip: %w", err)
	}

	members, err := s.repo.ListMembers(ctx, tripID)
	if err != nil {
		return nil, fmt.Errorf("list members: %w", err)
	}

	return toTripDetail(updated, members), nil
}

// DeleteTrip removes a trip (owner only).
func (s *Service) DeleteTrip(ctx context.Context, tripID, callerID uuid.UUID) error {
	trip, err := s.repo.FindByID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotFound
		}
		return fmt.Errorf("find trip: %w", err)
	}
	if trip.OwnerID != callerID {
		return ErrForbidden
	}
	return s.repo.DeleteTrip(ctx, tripID)
}

// AddMember adds a user to a trip (any member can invite).
func (s *Service) AddMember(ctx context.Context, tripID, callerID, targetUserID uuid.UUID) (*MemberResponse, error) {
	ok, err := s.repo.IsMember(ctx, tripID, callerID)
	if err != nil {
		return nil, fmt.Errorf("check member: %w", err)
	}
	if !ok {
		return nil, ErrForbidden
	}

	already, err := s.repo.IsMember(ctx, tripID, targetUserID)
	if err != nil {
		return nil, fmt.Errorf("check target member: %w", err)
	}
	if already {
		return nil, ErrConflict
	}

	m, err := s.repo.AddMember(ctx, tripID, targetUserID, "editor")
	if err != nil {
		return nil, fmt.Errorf("add member: %w", err)
	}

	r := toMemberResponse(m)
	return &r, nil
}

// RemoveMember removes a user from a trip (owner only, can't remove self).
func (s *Service) RemoveMember(ctx context.Context, tripID, callerID, targetUserID uuid.UUID) error {
	trip, err := s.repo.FindByID(ctx, tripID)
	if err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotFound
		}
		return fmt.Errorf("find trip: %w", err)
	}
	if trip.OwnerID != callerID {
		return ErrForbidden
	}
	if callerID == targetUserID {
		return fmt.Errorf("cannot remove yourself from trip")
	}
	return s.repo.RemoveMember(ctx, tripID, targetUserID)
}

// IsMember exposes membership check for other packages.
func (s *Service) IsMember(ctx context.Context, tripID, userID uuid.UUID) (bool, error) {
	return s.repo.IsMember(ctx, tripID, userID)
}

func parseDate(s *string) *time.Time {
	if s == nil {
		return nil
	}
	t, err := time.Parse("2006-01-02", *s)
	if err != nil {
		return nil
	}
	return &t
}
