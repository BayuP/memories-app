package ai

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts AI itinerary routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates an AI handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes registers AI routes on a chi router.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Post("/trips/{tripID}/ai/generate", h.generate)
		r.Post("/trips/{tripID}/ai/refine", h.refine)
	}
}

func (h *Handler) generate(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	tripID, err := uuid.Parse(chi.URLParam(r, "tripID"))
	if err != nil {
		httpx.ErrNotFound(w, "trip")
		return
	}

	items, err := h.svc.GenerateItinerary(r.Context(), tripID, callerID)
	if err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		if errors.Is(err, ErrTripNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		h.log.ErrorContext(r.Context(), "ai generate", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) refine(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	tripID, err := uuid.Parse(chi.URLParam(r, "tripID"))
	if err != nil {
		httpx.ErrNotFound(w, "trip")
		return
	}

	var req RefineRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}
	if req.Message == "" {
		httpx.ErrBadRequest(w, "message is required")
		return
	}

	reply, err := h.svc.RefineItinerary(r.Context(), tripID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		if errors.Is(err, ErrRateLimit) {
			httpx.WriteError(w, http.StatusTooManyRequests, "rate_limited", "refinement limit reached")
			return
		}
		h.log.ErrorContext(r.Context(), "ai refine", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, map[string]any{"reply": reply})
}
