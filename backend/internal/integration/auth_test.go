package integration_test

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/BayuP/memories-app/backend/internal/auth"
	"github.com/BayuP/memories-app/backend/internal/testdb"
	"github.com/BayuP/memories-app/backend/internal/users"
)

func newAuthServer(t *testing.T, pool *pgxpool.Pool) http.Handler {
	t.Helper()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	jwtMgr := auth.NewJWTManager("test-secret-32-bytes-long-key!!", 15*time.Minute, 720*time.Hour)
	userRepo := users.NewRepository(pool)
	authRepo := auth.NewRepository(pool)
	authSvc := auth.NewService(authRepo, userRepo, jwtMgr)
	h := auth.NewHandler(authSvc, log)
	r := chi.NewRouter()
	r.Route("/auth", h.Routes())
	return r
}

func postJSON(t *testing.T, srv http.Handler, path string, body any) *httptest.ResponseRecorder {
	t.Helper()
	b, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, path, bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	srv.ServeHTTP(rr, req)
	return rr
}

func decodeJSON(t *testing.T, rr *httptest.ResponseRecorder, dst any) {
	t.Helper()
	if err := json.NewDecoder(rr.Body).Decode(dst); err != nil {
		t.Fatalf("decode response: %v", err)
	}
}

func TestSignUp_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv := newAuthServer(t, pool)

	rr := postJSON(t, srv, "/auth/signup", map[string]string{
		"email":        "signup@test.com",
		"password":     "testpass1",
		"handle":       "signupuser",
		"display_name": "Signup User",
	})
	if rr.Code != http.StatusCreated {
		t.Fatalf("status: got %d, want %d — body: %s", rr.Code, http.StatusCreated, rr.Body)
	}

	var pair auth.TokenPair
	decodeJSON(t, rr, &pair)
	if pair.AccessToken == "" {
		t.Error("expected non-empty access_token")
	}
	if pair.RefreshToken == "" {
		t.Error("expected non-empty refresh_token")
	}
}

func TestSignUp_Duplicate(t *testing.T) {
	pool := testdb.Connect(t)
	srv := newAuthServer(t, pool)

	body := map[string]string{
		"email":        "dup@test.com",
		"password":     "testpass1",
		"handle":       "dupuser",
		"display_name": "Dup User",
	}
	rr := postJSON(t, srv, "/auth/signup", body)
	if rr.Code != http.StatusCreated {
		t.Fatalf("first signup: got %d, want %d", rr.Code, http.StatusCreated)
	}

	rr2 := postJSON(t, srv, "/auth/signup", body)
	if rr2.Code != http.StatusConflict {
		t.Errorf("duplicate signup: got %d, want %d — body: %s", rr2.Code, http.StatusConflict, rr2.Body)
	}
}

func TestSignIn_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv := newAuthServer(t, pool)

	rr := postJSON(t, srv, "/auth/signup", map[string]string{
		"email":        "signin@test.com",
		"password":     "testpass2",
		"handle":       "signinuser",
		"display_name": "Sign In User",
	})
	if rr.Code != http.StatusCreated {
		t.Fatalf("signup: got %d, want %d", rr.Code, http.StatusCreated)
	}

	rr2 := postJSON(t, srv, "/auth/signin", map[string]string{
		"email":    "signin@test.com",
		"password": "testpass2",
	})
	if rr2.Code != http.StatusOK {
		t.Fatalf("signin: got %d, want %d — body: %s", rr2.Code, http.StatusOK, rr2.Body)
	}

	var pair auth.TokenPair
	decodeJSON(t, rr2, &pair)
	if pair.AccessToken == "" {
		t.Error("expected non-empty access_token")
	}
	if pair.RefreshToken == "" {
		t.Error("expected non-empty refresh_token")
	}
}

func TestSignIn_WrongPassword(t *testing.T) {
	pool := testdb.Connect(t)
	srv := newAuthServer(t, pool)

	rr := postJSON(t, srv, "/auth/signup", map[string]string{
		"email":        "wrongpw@test.com",
		"password":     "correctpass",
		"handle":       "wrongpwuser",
		"display_name": "Wrong PW User",
	})
	if rr.Code != http.StatusCreated {
		t.Fatalf("signup: got %d", rr.Code)
	}

	rr2 := postJSON(t, srv, "/auth/signin", map[string]string{
		"email":    "wrongpw@test.com",
		"password": "wrongpassword",
	})
	if rr2.Code != http.StatusUnauthorized {
		t.Errorf("wrong password: got %d, want %d", rr2.Code, http.StatusUnauthorized)
	}
}

func TestRefresh_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv := newAuthServer(t, pool)

	rr := postJSON(t, srv, "/auth/signup", map[string]string{
		"email":        "refresh@test.com",
		"password":     "testpass3",
		"handle":       "refreshuser",
		"display_name": "Refresh User",
	})
	if rr.Code != http.StatusCreated {
		t.Fatalf("signup: got %d", rr.Code)
	}

	var pair auth.TokenPair
	decodeJSON(t, rr, &pair)

	rr2 := postJSON(t, srv, "/auth/refresh", map[string]string{
		"refresh_token": pair.RefreshToken,
	})
	if rr2.Code != http.StatusOK {
		t.Fatalf("refresh: got %d, want %d — body: %s", rr2.Code, http.StatusOK, rr2.Body)
	}

	var newPair auth.TokenPair
	decodeJSON(t, rr2, &newPair)
	if newPair.AccessToken == "" {
		t.Error("expected non-empty access_token after refresh")
	}
	if newPair.RefreshToken == "" {
		t.Error("expected non-empty refresh_token after refresh")
	}
}
