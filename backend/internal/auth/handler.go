package auth

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/BayuP/memories-app/backend/internal/httpx"
)

// Handler mounts auth-related HTTP routes.
type Handler struct {
	svc      *Service
	validate *validator.Validate
	log      *slog.Logger
}

// NewHandler creates an auth HTTP handler.
func NewHandler(svc *Service, log *slog.Logger) *Handler {
	v := validator.New()
	_ = v.RegisterValidation("handle", func(fl validator.FieldLevel) bool {
		return handlePattern.MatchString(fl.Field().String())
	})
	return &Handler{svc: svc, validate: v, log: log}
}

// Routes returns the chi sub-router for auth endpoints.
func (h *Handler) Routes() func(chi.Router) {
	return func(r chi.Router) {
		r.Post("/signup", h.signUp)
		r.Post("/signin", h.signIn)
		r.Post("/refresh", h.refresh)
		r.Post("/logout", h.logout)
	}
}

func (h *Handler) signUp(w http.ResponseWriter, r *http.Request) {
	var req SignUpRequest
	if !decodeBody(w, r, &req) {
		return
	}
	if !h.validateStruct(w, &req) {
		return
	}

	pair, err := h.svc.SignUp(r.Context(), req)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			httpx.ErrConflict(w, "email or handle already in use")
			return
		}
		h.log.ErrorContext(r.Context(), "signup", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusCreated, pair)
}

func (h *Handler) signIn(w http.ResponseWriter, r *http.Request) {
	var req SignInRequest
	if !decodeBody(w, r, &req) {
		return
	}
	if !h.validateStruct(w, &req) {
		return
	}

	pair, err := h.svc.SignIn(r.Context(), req)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			httpx.ErrUnauthorized(w)
			return
		}
		h.log.ErrorContext(r.Context(), "signin", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, pair)
}

func (h *Handler) refresh(w http.ResponseWriter, r *http.Request) {
	var req RefreshRequest
	if !decodeBody(w, r, &req) {
		return
	}
	if !h.validateStruct(w, &req) {
		return
	}

	pair, err := h.svc.Refresh(r.Context(), req.RefreshToken)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) || errors.Is(err, ErrTokenRevoked) || errors.Is(err, ErrTokenExpired) {
			httpx.ErrUnauthorized(w)
			return
		}
		h.log.ErrorContext(r.Context(), "refresh", "error", err)
		httpx.ErrInternal(w)
		return
	}

	httpx.WriteJSON(w, http.StatusOK, pair)
}

func (h *Handler) logout(w http.ResponseWriter, r *http.Request) {
	var req LogoutRequest
	if !decodeBody(w, r, &req) {
		return
	}
	if !h.validateStruct(w, &req) {
		return
	}

	if err := h.svc.Logout(r.Context(), req.RefreshToken); err != nil {
		h.log.ErrorContext(r.Context(), "logout", "error", err)
		httpx.ErrInternal(w)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func decodeBody(w http.ResponseWriter, r *http.Request, dst any) bool {
	if err := json.NewDecoder(r.Body).Decode(dst); err != nil {
		httpx.ErrBadRequest(w, "invalid JSON: "+err.Error())
		return false
	}
	return true
}

func (h *Handler) validateStruct(w http.ResponseWriter, dst any) bool {
	if err := h.validate.Struct(dst); err != nil {
		var ve validator.ValidationErrors
		if errors.As(err, &ve) {
			type fieldErr struct {
				Field   string `json:"field"`
				Message string `json:"message"`
			}
			fields := make([]fieldErr, len(ve))
			for i, e := range ve {
				fields[i] = fieldErr{Field: e.Field(), Message: e.Tag()}
			}
			httpx.WriteError(w, http.StatusBadRequest, "validation_error", "request validation failed")
			return false
		}
		httpx.ErrBadRequest(w, err.Error())
		return false
	}
	return true
}
