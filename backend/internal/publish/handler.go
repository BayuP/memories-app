package publish

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts public trip HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates a publish HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes are public — no auth middleware needed. Mount at root.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Get("/public/trips/{tripID}", h.getTrip)
	}
}

func (h *Handler) getTrip(w http.ResponseWriter, r *http.Request) {
	tripID, err := uuid.Parse(chi.URLParam(r, "tripID"))
	if err != nil {
		httpx.ErrNotFound(w, "trip")
		return
	}

	detail, err := h.svc.GetPublicTrip(r.Context(), tripID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		h.log.ErrorContext(r.Context(), "get public trip", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, detail)
}
