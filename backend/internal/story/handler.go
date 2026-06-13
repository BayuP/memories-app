package story

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts story-related HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates a story HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes returns a function that registers story routes on a chi router.
// All routes require authentication (enforced by the caller via authMiddleware).
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Post("/trips/{tripID}/story/generate", h.generate)
		r.Get("/trips/{tripID}/story", h.get)
		r.Patch("/trips/{tripID}/story", h.patch)
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

	resp, err := h.svc.GenerateStory(r.Context(), tripID, callerID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "generate story", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
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

	resp, err := h.svc.GetStory(r.Context(), tripID, callerID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "story")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "get story", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) patch(w http.ResponseWriter, r *http.Request) {
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

	var req PatchStoryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	resp, err := h.svc.PatchStory(r.Context(), tripID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "story")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "patch story", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, resp)
}
