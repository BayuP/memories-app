package media

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrNotFound  = errors.New("media not found")
	ErrForbidden = errors.New("forbidden")
)

// Media is a photo or video file attached (or pending attachment) to a check-in.
type Media struct {
	ID        uuid.UUID
	CheckinID *uuid.UUID
	OwnerID   uuid.UUID
	R2Key     string
	Mime      string
	Width     *int
	Height    *int
	TakenAt   *time.Time
	Lat       *float64
	Lng       *float64
	CreatedAt time.Time
	UpdatedAt time.Time
}
