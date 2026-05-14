package users

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts user-related HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates a users HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes returns the chi sub-router for user endpoints.
func (h *Handler) Routes(authMiddleware func(http.Handler) http.Handler) func(chi.Router) {
	return func(r chi.Router) {
		r.With(authMiddleware).Get("/me", h.me)
		r.With(authMiddleware).Patch("/me", h.updateMe)
		r.With(authMiddleware).Get("/users/search", h.search)
		r.Get("/users/handle/{handle}", h.getByHandle)
	}
}

func (h *Handler) me(w http.ResponseWriter, r *http.Request) {
	userID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	user, err := h.svc.Me(r.Context(), userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.ErrNotFound(w, "user")
			return
		}
		h.log.ErrorContext(r.Context(), "me", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, ToProfileResponse(user))
}

func (h *Handler) updateMe(w http.ResponseWriter, r *http.Request) {
	userID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	var req UpdateMeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	user, err := h.svc.UpdateMe(r.Context(), userID, UpdateUserParams{
		DisplayName: req.DisplayName,
		AvatarURL:   req.AvatarURL,
	})
	if err != nil {
		h.log.ErrorContext(r.Context(), "update me", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, ToProfileResponse(user))
}

func (h *Handler) search(w http.ResponseWriter, r *http.Request) {
	userID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}
	_ = userID

	q := r.URL.Query().Get("q")
	if q == "" {
		httpx.WriteJSON(w, http.StatusOK, SearchResponse{Users: []PublicProfileResponse{}})
		return
	}

	users, err := h.svc.SearchByHandle(r.Context(), q)
	if err != nil {
		h.log.ErrorContext(r.Context(), "search", "error", err)
		httpx.ErrInternal(w)
		return
	}

	resp := SearchResponse{Users: make([]PublicProfileResponse, len(users))}
	for i, u := range users {
		resp.Users[i] = ToPublicProfileResponse(u)
	}
	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) getByHandle(w http.ResponseWriter, r *http.Request) {
	handle := chi.URLParam(r, "handle")
	if !ValidHandle(handle) {
		httpx.ErrNotFound(w, "user")
		return
	}

	user, err := h.svc.GetByHandle(r.Context(), handle)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			httpx.ErrNotFound(w, "user")
			return
		}
		h.log.ErrorContext(r.Context(), "get by handle", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, ToPublicProfileResponse(user))
}
