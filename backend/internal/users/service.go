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

// UpdateMe applies partial profile updates for the authenticated user.
func (s *Service) UpdateMe(ctx context.Context, userID uuid.UUID, params UpdateUserParams) (*User, error) {
	user, err := s.repo.UpdateUser(ctx, userID, params)
	if err != nil {
		return nil, fmt.Errorf("update me: %w", err)
	}
	return user, nil
}

// SearchByHandle finds users whose handle starts with the given prefix, excluding the caller.
func (s *Service) SearchByHandle(ctx context.Context, prefix string, excludeID uuid.UUID) ([]*User, error) {
	if prefix == "" {
		return nil, nil
	}
	users, err := s.repo.SearchByHandle(ctx, prefix, excludeID, 20)
	if err != nil {
		return nil, fmt.Errorf("search by handle: %w", err)
	}
	return users, nil
}
