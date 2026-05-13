package auth

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/BayuP/memories-app/backend/internal/users"
)

// ErrInvalidCredentials is returned when email/password do not match.
var ErrInvalidCredentials = errors.New("invalid credentials")

// ErrTokenRevoked is returned when a refresh token has already been revoked.
var ErrTokenRevoked = errors.New("refresh token has been revoked")

// ErrTokenExpired is returned when a refresh token is past its expiry.
var ErrTokenExpired = errors.New("refresh token has expired")

// Service handles auth business logic.
type Service struct {
	repo     Repository
	userRepo users.Repository
	jwt      *JWTManager
}

// NewService wires auth service dependencies.
func NewService(repo Repository, userRepo users.Repository, jwt *JWTManager) *Service {
	return &Service{repo: repo, userRepo: userRepo, jwt: jwt}
}

// SignUp creates a new user and returns a token pair.
func (s *Service) SignUp(ctx context.Context, req SignUpRequest) (*TokenPair, error) {
	hash, err := HashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	user, err := s.userRepo.CreateUser(ctx, users.CreateUserParams{
		Email:        req.Email,
		PasswordHash: hash,
		Handle:       req.Handle,
		DisplayName:  req.DisplayName,
	})
	if err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	return s.issueTokenPair(ctx, user.ID)
}

// SignIn validates credentials and returns a token pair.
func (s *Service) SignIn(ctx context.Context, req SignInRequest) (*TokenPair, error) {
	user, err := s.userRepo.FindByEmail(ctx, req.Email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("find user: %w", err)
	}

	if err := CheckPassword(req.Password, user.PasswordHash); err != nil {
		return nil, ErrInvalidCredentials
	}

	return s.issueTokenPair(ctx, user.ID)
}

// Refresh rotates a refresh token and returns a new token pair.
func (s *Service) Refresh(ctx context.Context, rawRefreshToken string) (*TokenPair, error) {
	userIDStr, err := s.jwt.VerifyRefreshToken(rawRefreshToken)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidCredentials, err)
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	hash := hashToken(rawRefreshToken)
	stored, err := s.repo.FindRefreshToken(ctx, hash)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrInvalidCredentials
		}
		return nil, fmt.Errorf("find refresh token: %w", err)
	}

	if stored.RevokedAt != nil {
		return nil, ErrTokenRevoked
	}

	if time.Now().After(stored.ExpiresAt) {
		return nil, ErrTokenExpired
	}

	if err := s.repo.RevokeRefreshToken(ctx, hash); err != nil {
		return nil, fmt.Errorf("revoke old refresh token: %w", err)
	}

	return s.issueTokenPair(ctx, userID)
}

func (s *Service) issueTokenPair(ctx context.Context, userID uuid.UUID) (*TokenPair, error) {
	access, err := s.jwt.IssueAccessToken(userID)
	if err != nil {
		return nil, fmt.Errorf("issue access token: %w", err)
	}

	refresh, err := s.jwt.IssueRefreshToken(userID)
	if err != nil {
		return nil, fmt.Errorf("issue refresh token: %w", err)
	}

	expiresAt := time.Now().Add(s.jwt.RefreshExpiry())
	if err := s.repo.StoreRefreshToken(ctx, userID, hashToken(refresh), expiresAt); err != nil {
		return nil, fmt.Errorf("store refresh token: %w", err)
	}

	return &TokenPair{AccessToken: access, RefreshToken: refresh}, nil
}

// hashToken returns a SHA-256 hex digest of the token for safe storage.
func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
