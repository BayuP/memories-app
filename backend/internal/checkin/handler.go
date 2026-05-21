package checkin

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts check-in HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates a checkin HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes registers check-in routes on a chi router.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Post("/trips/{tripID}/checkins", h.create)
		r.Get("/checkins/{checkinID}", h.get)
		r.Patch("/checkins/{checkinID}", h.update)
		r.Put("/checkins/{checkinID}/memory", h.upsertMemory)
		r.Put("/checkins/{checkinID}/logistics", h.upsertLogistics)
		r.Put("/checkins/{checkinID}/recommendation", h.upsertRecommendation)
	}
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
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

	var req CreateCheckinRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	checkin, err := h.svc.CreateCheckin(r.Context(), tripID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "create checkin", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, checkin)
}

func (h *Handler) get(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	checkinID, err := uuid.Parse(chi.URLParam(r, "checkinID"))
	if err != nil {
		httpx.ErrNotFound(w, "checkin")
		return
	}

	checkin, err := h.svc.GetCheckin(r.Context(), checkinID, callerID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "checkin")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "get checkin", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, checkin)
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	checkinID, err := uuid.Parse(chi.URLParam(r, "checkinID"))
	if err != nil {
		httpx.ErrNotFound(w, "checkin")
		return
	}

	var req UpdateCheckinRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	checkin, err := h.svc.UpdateCheckin(r.Context(), checkinID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "checkin")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "update checkin", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, checkin)
}

func (h *Handler) upsertMemory(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	checkinID, err := uuid.Parse(chi.URLParam(r, "checkinID"))
	if err != nil {
		httpx.ErrNotFound(w, "checkin")
		return
	}

	var req UpsertMemoryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	mem, err := h.svc.UpsertMemory(r.Context(), checkinID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "checkin")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "upsert memory", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, mem)
}

func (h *Handler) upsertLogistics(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	checkinID, err := uuid.Parse(chi.URLParam(r, "checkinID"))
	if err != nil {
		httpx.ErrNotFound(w, "checkin")
		return
	}

	var req UpsertLogisticsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	l, err := h.svc.UpsertLogistics(r.Context(), checkinID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "checkin")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "upsert logistics", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, l)
}

func (h *Handler) upsertRecommendation(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	checkinID, err := uuid.Parse(chi.URLParam(r, "checkinID"))
	if err != nil {
		httpx.ErrNotFound(w, "checkin")
		return
	}

	var req UpsertRecommendationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	rec, err := h.svc.UpsertRecommendation(r.Context(), checkinID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "checkin")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "upsert recommendation", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, rec)
}
