package publish

import (
	"time"

	"github.com/google/uuid"
)

type PublicTrip struct {
	ID          uuid.UUID
	Title       string
	Destination string
	StartDate   *time.Time
	EndDate     *time.Time
	Vibes       []string
	Status      string
}

type PublicItem struct {
	ID           uuid.UUID
	TripID       uuid.UUID
	Day          int
	StartTime    *string
	Title        string
	Description  *string
	LocationName *string
	Lat          *float64
	Lng          *float64
	Source       string
}

type PublicCheckin struct {
	ID         uuid.UUID
	CapturedAt time.Time
	Lat        *float64
	Lng        *float64
	Kind       string
	// recommendation fields (nil if none)
	RecTitle  *string
	RecBody   *string
	RecTags   []string
	RecRating *int
}
