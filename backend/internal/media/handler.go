package media

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts media HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates a media HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes registers media routes on a chi router.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Post("/media/upload-url", h.uploadURL)
		r.Patch("/media/{mediaID}", h.attach)
		r.Delete("/media/{mediaID}", h.delete)
	}
}

func (h *Handler) uploadURL(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	var req UploadURLRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	resp, err := h.svc.GetUploadURL(r.Context(), callerID, req)
	if err != nil {
		httpx.ErrBadRequest(w, err.Error())
		return
	}

	httpx.WriteJSON(w, http.StatusOK, resp)
}

func (h *Handler) attach(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	mediaID, err := uuid.Parse(chi.URLParam(r, "mediaID"))
	if err != nil {
		httpx.ErrNotFound(w, "media")
		return
	}

	var req AttachRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	m, err := h.svc.AttachMedia(r.Context(), mediaID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "media")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "attach media", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, m)
}

func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	mediaID, err := uuid.Parse(chi.URLParam(r, "mediaID"))
	if err != nil {
		httpx.ErrNotFound(w, "media")
		return
	}

	if err := h.svc.DeleteMedia(r.Context(), mediaID, callerID); err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "media")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "delete media", "error", err)
		httpx.ErrInternal(w)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
