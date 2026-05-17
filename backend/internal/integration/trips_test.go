package integration_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/BayuP/memories-app/backend/internal/auth"
	"github.com/BayuP/memories-app/backend/internal/httpx"
	"github.com/BayuP/memories-app/backend/internal/testdb"
	"github.com/BayuP/memories-app/backend/internal/trips"
	"github.com/BayuP/memories-app/backend/internal/users"
)

func newTripServer(t *testing.T, pool *pgxpool.Pool) (http.Handler, *auth.JWTManager) {
	t.Helper()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	jwtMgr := auth.NewJWTManager("test-secret-32-bytes-long-key!!", 15*time.Minute, 720*time.Hour)
	userRepo := users.NewRepository(pool)
	authRepo := auth.NewRepository(pool)
	tripRepo := trips.NewRepository(pool)
	authSvc := auth.NewService(authRepo, userRepo, jwtMgr)
	tripSvc := trips.NewService(tripRepo)
	authH := auth.NewHandler(authSvc, log)
	tripH := trips.NewHandler(tripSvc, log)
	authMW := httpx.AuthMiddleware(jwtMgr)
	r := chi.NewRouter()
	r.Route("/auth", authH.Routes())
	r.With(authMW).Group(tripH.Routes())
	return r, jwtMgr
}

// signUpAndGetToken signs up a new user and returns the access token.
func signUpAndGetToken(t *testing.T, srv http.Handler, handle string) string {
	t.Helper()
	body := map[string]string{
		"email":        handle + "@test.com",
		"password":     "testpass99",
		"handle":       handle,
		"display_name": handle,
	}
	b, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("signUpAndGetToken marshal: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, "/auth/signup", bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	srv.ServeHTTP(rr, req)
	if rr.Code != http.StatusCreated {
		t.Fatalf("signUpAndGetToken(%q): got %d — %s", handle, rr.Code, rr.Body)
	}

	var pair auth.TokenPair
	if err := json.NewDecoder(rr.Body).Decode(&pair); err != nil {
		t.Fatalf("signUpAndGetToken decode: %v", err)
	}
	return pair.AccessToken
}

func authedRequest(t *testing.T, method, path string, body any, token string) *http.Request {
	t.Helper()
	var r *http.Request
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("authedRequest marshal: %v", err)
		}
		r = httptest.NewRequest(method, path, bytes.NewReader(b))
		r.Header.Set("Content-Type", "application/json")
	} else {
		r = httptest.NewRequest(method, path, nil)
	}
	r.Header.Set("Authorization", "Bearer "+token)
	return r
}

func do(t *testing.T, srv http.Handler, req *http.Request) *httptest.ResponseRecorder {
	t.Helper()
	rr := httptest.NewRecorder()
	srv.ServeHTTP(rr, req)
	return rr
}

func TestCreateTrip_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv, _ := newTripServer(t, pool)

	token := signUpAndGetToken(t, srv, "tripcreathttp")

	req := authedRequest(t, http.MethodPost, "/trips", map[string]any{
		"title":       "My First Trip",
		"destination": "Tokyo, Japan",
		"vibes":       []string{"adventure"},
	}, token)
	rr := do(t, srv, req)

	if rr.Code != http.StatusCreated {
		t.Fatalf("create trip: got %d, want %d — %s", rr.Code, http.StatusCreated, rr.Body)
	}

	var resp trips.TripDetailResponse
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if resp.Trip.ID == "" {
		t.Error("expected non-empty trip.id")
	}
	if resp.Trip.Title != "My First Trip" {
		t.Errorf("title: got %q, want %q", resp.Trip.Title, "My First Trip")
	}
}

func TestListTrips_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv, _ := newTripServer(t, pool)

	token := signUpAndGetToken(t, srv, "triplisthttp")

	for _, title := range []string{"Trip Alpha", "Trip Beta"} {
		req := authedRequest(t, http.MethodPost, "/trips", map[string]any{
			"title":       title,
			"destination": "Anywhere",
		}, token)
		rr := do(t, srv, req)
		if rr.Code != http.StatusCreated {
			t.Fatalf("create %q: got %d", title, rr.Code)
		}
	}

	req := authedRequest(t, http.MethodGet, "/trips", nil, token)
	rr := do(t, srv, req)
	if rr.Code != http.StatusOK {
		t.Fatalf("list trips: got %d, want %d — %s", rr.Code, http.StatusOK, rr.Body)
	}

	var resp struct {
		Trips []trips.TripResponse `json:"trips"`
	}
	if err := json.NewDecoder(rr.Body).Decode(&resp); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(resp.Trips) != 2 {
		t.Errorf("trips len: got %d, want 2", len(resp.Trips))
	}
}

func TestGetTrip_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv, _ := newTripServer(t, pool)

	token := signUpAndGetToken(t, srv, "tripgethttp")

	createReq := authedRequest(t, http.MethodPost, "/trips", map[string]any{
		"title":       "Get Me Trip",
		"destination": "Paris, France",
	}, token)
	createRR := do(t, srv, createReq)
	if createRR.Code != http.StatusCreated {
		t.Fatalf("create trip: got %d", createRR.Code)
	}
	var created trips.TripDetailResponse
	if err := json.NewDecoder(createRR.Body).Decode(&created); err != nil {
		t.Fatalf("decode create: %v", err)
	}

	getReq := authedRequest(t, http.MethodGet, "/trips/"+created.Trip.ID, nil, token)
	getRR := do(t, srv, getReq)
	if getRR.Code != http.StatusOK {
		t.Fatalf("get trip: got %d, want %d — %s", getRR.Code, http.StatusOK, getRR.Body)
	}

	var detail trips.TripDetailResponse
	if err := json.NewDecoder(getRR.Body).Decode(&detail); err != nil {
		t.Fatalf("decode get: %v", err)
	}
	if detail.Trip.ID != created.Trip.ID {
		t.Errorf("id mismatch: got %q, want %q", detail.Trip.ID, created.Trip.ID)
	}
}

func TestGetTrip_NotMember(t *testing.T) {
	pool := testdb.Connect(t)
	srv, _ := newTripServer(t, pool)

	token1 := signUpAndGetToken(t, srv, "tripowner01")
	token2 := signUpAndGetToken(t, srv, "tripguest01")

	createReq := authedRequest(t, http.MethodPost, "/trips", map[string]any{
		"title":       "Private Trip",
		"destination": "Secret Place",
	}, token1)
	createRR := do(t, srv, createReq)
	if createRR.Code != http.StatusCreated {
		t.Fatalf("create trip: got %d", createRR.Code)
	}
	var created trips.TripDetailResponse
	if err := json.NewDecoder(createRR.Body).Decode(&created); err != nil {
		t.Fatalf("decode create: %v", err)
	}

	getReq := authedRequest(t, http.MethodGet, "/trips/"+created.Trip.ID, nil, token2)
	getRR := do(t, srv, getReq)
	if getRR.Code != http.StatusForbidden {
		t.Errorf("non-member GET trip: got %d, want %d", getRR.Code, http.StatusForbidden)
	}
}

func TestUpdateTrip_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv, _ := newTripServer(t, pool)

	token := signUpAndGetToken(t, srv, "tripupdthttp")

	createReq := authedRequest(t, http.MethodPost, "/trips", map[string]any{
		"title":       "Original Title",
		"destination": "Original Dest",
	}, token)
	createRR := do(t, srv, createReq)
	if createRR.Code != http.StatusCreated {
		t.Fatalf("create trip: got %d", createRR.Code)
	}
	var created trips.TripDetailResponse
	if err := json.NewDecoder(createRR.Body).Decode(&created); err != nil {
		t.Fatalf("decode create: %v", err)
	}

	newTitle := "Updated Title"
	patchReq := authedRequest(t, http.MethodPatch, fmt.Sprintf("/trips/%s", created.Trip.ID),
		map[string]any{"title": newTitle}, token)
	patchRR := do(t, srv, patchReq)
	if patchRR.Code != http.StatusOK {
		t.Fatalf("update trip: got %d, want %d — %s", patchRR.Code, http.StatusOK, patchRR.Body)
	}

	var updated trips.TripDetailResponse
	if err := json.NewDecoder(patchRR.Body).Decode(&updated); err != nil {
		t.Fatalf("decode update: %v", err)
	}
	if updated.Trip.Title != newTitle {
		t.Errorf("title: got %q, want %q", updated.Trip.Title, newTitle)
	}
}

func TestDeleteTrip_HTTP(t *testing.T) {
	pool := testdb.Connect(t)
	srv, _ := newTripServer(t, pool)

	token := signUpAndGetToken(t, srv, "tripdelthttp")

	createReq := authedRequest(t, http.MethodPost, "/trips", map[string]any{
		"title":       "To Delete",
		"destination": "Nowhere",
	}, token)
	createRR := do(t, srv, createReq)
	if createRR.Code != http.StatusCreated {
		t.Fatalf("create trip: got %d", createRR.Code)
	}
	var created trips.TripDetailResponse
	if err := json.NewDecoder(createRR.Body).Decode(&created); err != nil {
		t.Fatalf("decode create: %v", err)
	}

	delReq := authedRequest(t, http.MethodDelete, "/trips/"+created.Trip.ID, nil, token)
	delRR := do(t, srv, delReq)
	if delRR.Code != http.StatusNoContent {
		t.Errorf("delete trip: got %d, want %d — %s", delRR.Code, http.StatusNoContent, delRR.Body)
	}
}
