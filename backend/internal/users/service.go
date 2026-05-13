package users

import (
	"context"
	"fmt"

	"github.com/google/uuid"
)

// Service handles user business logic.
type Service struct {
	repo Repository
}

// NewService wires user service dependencies.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// Me returns the authenticated user's profile.
func (s *Service) Me(ctx context.Context, userID uuid.UUID) (*User, error) {
	user, err := s.repo.FindByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("get me: %w", err)
	}
	return user, nil
}

// GetByHandle returns a user by their @handle for the invite lookup flow.
func (s *Service) GetByHandle(ctx context.Context, handle string) (*User, error) {
	user, err := s.repo.FindByHandle(ctx, handle)
	if err != nil {
		return nil, fmt.Errorf("get by handle: %w", err)
	}
	return user, nil
}
