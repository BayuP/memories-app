package users

import (
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
