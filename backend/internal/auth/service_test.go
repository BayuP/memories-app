package auth

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/BayuP/memories-app/backend/internal/users"
)

// --- mock implementations ---

type mockAuthRepo struct {
	tokens map[string]*RefreshToken
}

func newMockAuthRepo() *mockAuthRepo {
	return &mockAuthRepo{tokens: make(map[string]*RefreshToken)}
}

func (m *mockAuthRepo) StoreRefreshToken(_ context.Context, userID uuid.UUID, tokenHash string, expiresAt time.Time) error {
	m.tokens[tokenHash] = &RefreshToken{
		ID:        uuid.New(),
		UserID:    userID,
		TokenHash: tokenHash,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
	}
	return nil
}

func (m *mockAuthRepo) FindRefreshToken(_ context.Context, tokenHash string) (*RefreshToken, error) {
	rt, ok := m.tokens[tokenHash]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	return rt, nil
}

func (m *mockAuthRepo) RevokeRefreshToken(_ context.Context, tokenHash string) error {
	rt, ok := m.tokens[tokenHash]
	if !ok {
		return errors.New("not found")
	}
	now := time.Now()
	rt.RevokedAt = &now
	return nil
}

type mockUserRepo struct {
	byEmail map[string]*users.User
	byID    map[uuid.UUID]*users.User
}

func newMockUserRepo() *mockUserRepo {
	return &mockUserRepo{
		byEmail: make(map[string]*users.User),
		byID:    make(map[uuid.UUID]*users.User),
	}
}

func (m *mockUserRepo) CreateUser(_ context.Context, p users.CreateUserParams) (*users.User, error) {
	u := &users.User{
		ID:           uuid.New(),
		Email:        p.Email,
		PasswordHash: p.PasswordHash,
		Handle:       p.Handle,
		DisplayName:  p.DisplayName,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	m.byEmail[u.Email] = u
	m.byID[u.ID] = u
	return u, nil
}

func (m *mockUserRepo) FindByID(_ context.Context, id uuid.UUID) (*users.User, error) {
	u, ok := m.byID[id]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	return u, nil
}

func (m *mockUserRepo) FindByEmail(_ context.Context, email string) (*users.User, error) {
	u, ok := m.byEmail[email]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	return u, nil
}

func (m *mockUserRepo) FindByHandle(_ context.Context, handle string) (*users.User, error) {
	for _, u := range m.byID {
		if u.Handle == handle {
			return u, nil
		}
	}
	return nil, pgx.ErrNoRows
}

func (m *mockUserRepo) UpdateUser(_ context.Context, id uuid.UUID, p users.UpdateUserParams) (*users.User, error) {
	u, ok := m.byID[id]
	if !ok {
		return nil, pgx.ErrNoRows
	}
	if p.DisplayName != nil {
		u.DisplayName = *p.DisplayName
	}
	if p.AvatarURL != nil {
		u.AvatarURL = p.AvatarURL
	}
	return u, nil
}

func (m *mockUserRepo) SearchByHandle(_ context.Context, prefix string, limit int) ([]*users.User, error) {
	var out []*users.User
	for _, u := range m.byID {
		if len(u.Handle) >= len(prefix) && u.Handle[:len(prefix)] == prefix {
			out = append(out, u)
			if len(out) >= limit {
				break
			}
		}
	}
	return out, nil
}

// --- helpers ---

func newTestService() (*Service, *mockAuthRepo, *mockUserRepo) {
	mgr := NewJWTManager("test-secret-key-32-bytes-long!!", 15*time.Minute, 720*time.Hour)
	authRepo := newMockAuthRepo()
	userRepo := newMockUserRepo()
	svc := NewService(authRepo, userRepo, mgr)
	return svc, authRepo, userRepo
}

func hashStr(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}

// --- tests ---

func TestSignUp(t *testing.T) {
	svc, _, _ := newTestService()

	pair, err := svc.SignUp(context.Background(), SignUpRequest{
		Email:       "alice@example.com",
		Password:    "securepass",
		Handle:      "alice",
		DisplayName: "Alice",
	})
	if err != nil {
		t.Fatalf("SignUp error: %v", err)
	}
	if pair.AccessToken == "" || pair.RefreshToken == "" {
		t.Error("expected non-empty token pair")
	}
}

func TestSignIn_ValidCredentials(t *testing.T) {
	svc, _, _ := newTestService()

	_, err := svc.SignUp(context.Background(), SignUpRequest{
		Email:       "bob@example.com",
		Password:    "mypassword",
		Handle:      "bob",
		DisplayName: "Bob",
	})
	if err != nil {
		t.Fatalf("SignUp error: %v", err)
	}

	pair, err := svc.SignIn(context.Background(), SignInRequest{
		Email:    "bob@example.com",
		Password: "mypassword",
	})
	if err != nil {
		t.Fatalf("SignIn error: %v", err)
	}
	if pair.AccessToken == "" {
		t.Error("expected access token")
	}
}

func TestSignIn_InvalidPassword(t *testing.T) {
	svc, _, _ := newTestService()

	_, _ = svc.SignUp(context.Background(), SignUpRequest{
		Email:       "carol@example.com",
		Password:    "correctpass",
		Handle:      "carol",
		DisplayName: "Carol",
	})

	_, err := svc.SignIn(context.Background(), SignInRequest{
		Email:    "carol@example.com",
		Password: "wrongpass",
	})
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Errorf("want ErrInvalidCredentials, got %v", err)
	}
}

func TestSignIn_UnknownEmail(t *testing.T) {
	svc, _, _ := newTestService()

	_, err := svc.SignIn(context.Background(), SignInRequest{
		Email:    "nobody@example.com",
		Password: "anything",
	})
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Errorf("want ErrInvalidCredentials, got %v", err)
	}
}

func TestRefresh_Rotation(t *testing.T) {
	svc, authRepo, _ := newTestService()

	pair1, err := svc.SignUp(context.Background(), SignUpRequest{
		Email:       "dave@example.com",
		Password:    "testpass1",
		Handle:      "dave",
		DisplayName: "Dave",
	})
	if err != nil {
		t.Fatalf("SignUp error: %v", err)
	}

	// Verify old token is in repo.
	oldHash := hashStr(pair1.RefreshToken)
	if _, ok := authRepo.tokens[oldHash]; !ok {
		t.Fatal("expected old refresh token in repo")
	}

	pair2, err := svc.Refresh(context.Background(), pair1.RefreshToken)
	if err != nil {
		t.Fatalf("Refresh error: %v", err)
	}
	if pair2.AccessToken == "" || pair2.RefreshToken == "" {
		t.Error("expected non-empty token pair after refresh")
	}

	// Old token should be revoked.
	if authRepo.tokens[oldHash].RevokedAt == nil {
		t.Error("old refresh token should be revoked after rotation")
	}

	// New token should be stored.
	newHash := hashStr(pair2.RefreshToken)
	if _, ok := authRepo.tokens[newHash]; !ok {
		t.Error("new refresh token should be stored in repo")
	}
}

func TestRefresh_RevokedToken(t *testing.T) {
	svc, authRepo, _ := newTestService()

	pair, err := svc.SignUp(context.Background(), SignUpRequest{
		Email:       "eve@example.com",
		Password:    "testpass2",
		Handle:      "eve",
		DisplayName: "Eve",
	})
	if err != nil {
		t.Fatalf("SignUp error: %v", err)
	}

	// Manually revoke the token.
	hash := hashStr(pair.RefreshToken)
	now := time.Now()
	authRepo.tokens[hash].RevokedAt = &now

	_, err = svc.Refresh(context.Background(), pair.RefreshToken)
	if !errors.Is(err, ErrTokenRevoked) {
		t.Errorf("want ErrTokenRevoked, got %v", err)
	}
}

func TestRefresh_ExpiredToken(t *testing.T) {
	// Use a manager with -1s refresh expiry so the JWT itself is already expired.
	mgr := NewJWTManager("test-secret-key-32-bytes-long!!", 15*time.Minute, -1*time.Second)
	authRepo := newMockAuthRepo()
	userRepo := newMockUserRepo()

	// Manually create user and issue an expired refresh token.
	u, _ := userRepo.CreateUser(context.Background(), users.CreateUserParams{
		Email: "frank@example.com", PasswordHash: "x", Handle: "frank", DisplayName: "Frank",
	})
	expiredToken, _ := mgr.IssueRefreshToken(u.ID)
	hash := hashStr(expiredToken)
	// Store as if not revoked but already expired.
	authRepo.tokens[hash] = &RefreshToken{
		ID:        uuid.New(),
		UserID:    u.ID,
		TokenHash: hash,
		ExpiresAt: time.Now().Add(-time.Hour),
		CreatedAt: time.Now(),
	}

	// Use a normal mgr for the service — VerifyRefreshToken will fail on JWT expiry first.
	svc := NewService(authRepo, userRepo, mgr)
	_, err := svc.Refresh(context.Background(), expiredToken)
	if err == nil {
		t.Error("expected error for expired refresh token, got nil")
	}
}
