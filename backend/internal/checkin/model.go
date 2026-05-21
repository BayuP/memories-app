package checkin

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrNotFound  = errors.New("checkin not found")
	ErrForbidden = errors.New("forbidden")
)

// Checkin is the top-level check-in entity.
type Checkin struct {
	ID              uuid.UUID
	TripID          uuid.UUID
	AuthorID        uuid.UUID
	ItineraryItemID *uuid.UUID
	CapturedAt      time.Time
	Lat             *float64
	Lng             *float64
	Kind            string
	Vibe            *string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

// Memory is the shareable layer of a check-in.
type Memory struct {
	ID         uuid.UUID
	CheckinID  uuid.UUID
	Note       *string
	Mood       *string
	SharedWith []string
	CreatedAt  time.Time
	UpdatedAt  time.Time
}

// Logistics is the private cost/booking layer of a check-in.
// PRIVACY: never serialize to public endpoints or AI prompts.
type Logistics struct {
	ID        uuid.UUID
	CheckinID uuid.UUID
	Cost      *float64
	Currency  *string
	Notes     *string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// Recommendation is the publishable tips layer of a check-in.
type Recommendation struct {
	ID        uuid.UUID
	CheckinID uuid.UUID
	Title     string
	Body      string
	Tags      []string
	Rating    *int
	CreatedAt time.Time
	UpdatedAt time.Time
}

// MediaItem is a media file attached to a check-in.
type MediaItem struct {
	ID        uuid.UUID
	CheckinID uuid.UUID
	OwnerID   uuid.UUID
	R2Key     string
	Mime      string
	Width     *int
	Height    *int
	TakenAt   *time.Time
	Lat       *float64
	Lng       *float64
	CreatedAt time.Time
}
