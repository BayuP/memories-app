package trips

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts trip-related HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates a trips HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes returns a function that registers trip routes on a chi router.
// All routes require authentication.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Post("/trips", h.create)
		r.Get("/trips", h.list)
		r.Get("/trips/{tripID}", h.get)
		r.Patch("/trips/{tripID}", h.update)
		r.Delete("/trips/{tripID}", h.delete)
		r.Post("/trips/{tripID}/members", h.addMember)
		r.Delete("/trips/{tripID}/members/{userID}", h.removeMember)
	}
}

func (h *Handler) create(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	var req CreateTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}
	if req.Title == "" || req.Destination == "" {
		httpx.ErrBadRequest(w, "title and destination are required")
		return
	}
	if req.Vibes == nil {
		req.Vibes = []string{}
	}

	detail, err := h.svc.CreateTrip(r.Context(), callerID, req)
	if err != nil {
		h.log.ErrorContext(r.Context(), "create trip", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, detail)
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
	callerID, ok := httpx.UserIDFromContext(r.Context())
	if !ok {
		httpx.ErrUnauthorized(w)
		return
	}

	trips, err := h.svc.ListTrips(r.Context(), callerID)
	if err != nil {
		h.log.ErrorContext(r.Context(), "list trips", "error", err)
		httpx.ErrInternal(w)
		return
	}

	if trips == nil {
		trips = []*TripResponse{}
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"trips": trips})
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

	detail, err := h.svc.GetTrip(r.Context(), tripID, callerID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "get trip", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, detail)
}

func (h *Handler) update(w http.ResponseWriter, r *http.Request) {
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

	var req UpdateTripRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	detail, err := h.svc.UpdateTrip(r.Context(), tripID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "update trip", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, detail)
}

func (h *Handler) delete(w http.ResponseWriter, r *http.Request) {
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

	if err := h.svc.DeleteTrip(r.Context(), tripID, callerID); err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "delete trip", "error", err)
		httpx.ErrInternal(w)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) addMember(w http.ResponseWriter, r *http.Request) {
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

	var req AddMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	targetID, err := uuid.Parse(req.UserID)
	if err != nil {
		httpx.ErrBadRequest(w, "invalid user_id")
		return
	}

	member, err := h.svc.AddMember(r.Context(), tripID, callerID, targetID)
	if err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		if errors.Is(err, ErrConflict) {
			httpx.ErrConflict(w, "user is already a member")
			return
		}
		h.log.ErrorContext(r.Context(), "add member", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, member)
}

func (h *Handler) removeMember(w http.ResponseWriter, r *http.Request) {
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

	targetID, err := uuid.Parse(chi.URLParam(r, "userID"))
	if err != nil {
		httpx.ErrNotFound(w, "user")
		return
	}

	if err := h.svc.RemoveMember(r.Context(), tripID, callerID, targetID); err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "trip")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "remove member", "error", err)
		httpx.ErrInternal(w)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
