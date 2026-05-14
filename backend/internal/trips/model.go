package trips

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrNotFound  = errors.New("trip not found")
	ErrForbidden = errors.New("forbidden")
	ErrConflict  = errors.New("already a member")
)

// Trip is the core trip entity.
type Trip struct {
	ID          uuid.UUID
	OwnerID     uuid.UUID
	Title       string
	Destination string
	StartDate   *time.Time
	EndDate     *time.Time
	Vibes       []string
	Status      string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// Member is a user–trip membership record.
type Member struct {
	ID        uuid.UUID
	TripID    uuid.UUID
	UserID    uuid.UUID
	Role      string
	CreatedAt time.Time
	UpdatedAt time.Time
}
