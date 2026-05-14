package itinerary

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

var (
	ErrNotFound  = errors.New("item not found")
	ErrForbidden = errors.New("forbidden")
)

// Item is an itinerary entry within a trip.
type Item struct {
	ID           uuid.UUID
	TripID       uuid.UUID
	Day          int
	StartTime    *string
	EndTime      *string
	Title        string
	Description  *string
	LocationName *string
	Lat          *float64
	Lng          *float64
	Source       string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
