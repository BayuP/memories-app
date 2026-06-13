package story

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrNotFound  = errors.New("story not found")
	ErrForbidden = errors.New("forbidden")
)

// Story is the persisted AI-generated narrative for a trip.
type Story struct {
	ID        uuid.UUID
	TripID    uuid.UUID
	Title     *string
	Body      *string
	Status    *string
	CreatedAt time.Time
	UpdatedAt time.Time
}
