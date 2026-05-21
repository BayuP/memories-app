package itinerary

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts itinerary HTTP routes.
type Handler struct {
	svc *Service
	log *slog.Logger
}

// NewHandler creates an itinerary HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	return &Handler{svc: svc, log: log}
}

// Routes registers itinerary item routes on a chi router.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Get("/trips/{tripID}/items", h.list)
		r.Post("/trips/{tripID}/items", h.create)
		// reorder must be registered before the {itemID} wildcard route so chi
		// matches the literal "reorder" segment first.
		r.Patch("/trips/{tripID}/items/reorder", h.reorder)
		r.Patch("/trips/{tripID}/items/{itemID}", h.update)
		r.Delete("/trips/{tripID}/items/{itemID}", h.delete)
	}
}

func (h *Handler) list(w http.ResponseWriter, r *http.Request) {
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

	items, err := h.svc.ListItems(r.Context(), tripID, callerID)
	if err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "list items", "error", err)
		httpx.ErrInternal(w)
		return
	}

	if items == nil {
		items = []ItemResponse{}
	}
	httpx.WriteJSON(w, http.StatusOK, map[string]any{"items": items})
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

	var req CreateItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	item, err := h.svc.CreateItem(r.Context(), tripID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		httpx.ErrBadRequest(w, err.Error())
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, item)
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

	itemID, err := uuid.Parse(chi.URLParam(r, "itemID"))
	if err != nil {
		httpx.ErrNotFound(w, "item")
		return
	}

	var req UpdateItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	item, err := h.svc.UpdateItem(r.Context(), tripID, itemID, callerID, req)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "item")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "update item", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, item)
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

	itemID, err := uuid.Parse(chi.URLParam(r, "itemID"))
	if err != nil {
		httpx.ErrNotFound(w, "item")
		return
	}

	if err := h.svc.DeleteItem(r.Context(), tripID, itemID, callerID); err != nil {
		if errors.Is(err, ErrNotFound) {
			httpx.ErrNotFound(w, "item")
			return
		}
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "delete item", "error", err)
		httpx.ErrInternal(w)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) reorder(w http.ResponseWriter, r *http.Request) {
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

	var req ReorderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		httpx.ErrBadRequest(w, "invalid request body")
		return
	}

	if err := h.svc.ReorderItems(r.Context(), tripID, callerID, req); err != nil {
		if errors.Is(err, ErrForbidden) {
			httpx.ErrForbidden(w)
			return
		}
		h.log.ErrorContext(r.Context(), "reorder items", "error", err)
		httpx.ErrInternal(w)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
