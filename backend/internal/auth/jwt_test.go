package auth

import (
	"testing"
	"time"

	"github.com/google/uuid"
)

func newTestJWTManager() *JWTManager {
	return NewJWTManager("test-secret-key-32-bytes-long!!", 15*time.Minute, 720*time.Hour)
}

func TestJWTIssueAndVerifyAccessToken(t *testing.T) {
	mgr := newTestJWTManager()
	userID := uuid.New()

	token, err := mgr.IssueAccessToken(userID)
	if err != nil {
		t.Fatalf("IssueAccessToken error: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}

	got, err := mgr.VerifyAccessToken(token)
	if err != nil {
		t.Fatalf("VerifyAccessToken error: %v", err)
	}
	if got != userID.String() {
		t.Errorf("subject mismatch: got %s want %s", got, userID)
	}
}

func TestJWTIssueAndVerifyRefreshToken(t *testing.T) {
	mgr := newTestJWTManager()
	userID := uuid.New()

	token, err := mgr.IssueRefreshToken(userID)
	if err != nil {
		t.Fatalf("IssueRefreshToken error: %v", err)
	}

	got, err := mgr.VerifyRefreshToken(token)
	if err != nil {
		t.Fatalf("VerifyRefreshToken error: %v", err)
	}
	if got != userID.String() {
		t.Errorf("subject mismatch: got %s want %s", got, userID)
	}
}

func TestJWTWrongType(t *testing.T) {
	mgr := newTestJWTManager()
	userID := uuid.New()

	tests := []struct {
		name      string
		issue     func() (string, error)
		verify    func(string) (string, error)
		wantError bool
	}{
		{
			name:      "access token verified as refresh",
			issue:     func() (string, error) { return mgr.IssueAccessToken(userID) },
			verify:    mgr.VerifyRefreshToken,
			wantError: true,
		},
		{
			name:      "refresh token verified as access",
			issue:     func() (string, error) { return mgr.IssueRefreshToken(userID) },
			verify:    mgr.VerifyAccessToken,
			wantError: true,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			token, err := tc.issue()
			if err != nil {
				t.Fatalf("issue error: %v", err)
			}
			_, err = tc.verify(token)
			if tc.wantError && err == nil {
				t.Error("expected error for wrong token type, got nil")
			}
		})
	}
}

func TestJWTExpiredToken(t *testing.T) {
	mgr := NewJWTManager("test-secret-key-32-bytes-long!!", -1*time.Second, 720*time.Hour)
	userID := uuid.New()

	token, err := mgr.IssueAccessToken(userID)
	if err != nil {
		t.Fatalf("IssueAccessToken error: %v", err)
	}

	_, err = mgr.VerifyAccessToken(token)
	if err == nil {
		t.Error("expected error for expired token, got nil")
	}
}

func TestJWTInvalidSignature(t *testing.T) {
	mgr1 := NewJWTManager("secret-one-32-bytes-long-here!!", 15*time.Minute, 720*time.Hour)
	mgr2 := NewJWTManager("secret-two-32-bytes-long-here!!", 15*time.Minute, 720*time.Hour)
	userID := uuid.New()

	token, err := mgr1.IssueAccessToken(userID)
	if err != nil {
		t.Fatalf("IssueAccessToken error: %v", err)
	}

	_, err = mgr2.VerifyAccessToken(token)
	if err == nil {
		t.Error("expected signature mismatch error, got nil")
	}
}
