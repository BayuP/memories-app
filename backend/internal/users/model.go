package users

import (
	"time"

	"github.com/google/uuid"
)

// User is the domain entity for an application user.
type User struct {
	ID           uuid.UUID
	Email        string
	PasswordHash string
	Handle       string
	DisplayName  string
	AvatarURL    *string
	CreatedAt    time.Time
	UpdatedAt    time.Time
}
