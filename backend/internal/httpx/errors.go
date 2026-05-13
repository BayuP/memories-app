package httpx

import (
	"encoding/json"
	"net/http"
)

// ErrorBody is the standard JSON error envelope.
type ErrorBody struct {
	Error ErrorDetail `json:"error"`
}

// ErrorDetail carries the machine-readable code and human message.
type ErrorDetail struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// WriteError encodes a structured error response.
func WriteError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(ErrorBody{Error: ErrorDetail{Code: code, Message: message}})
}

// WriteJSON encodes v as JSON with the given status code.
func WriteJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

// Common error helpers.

func ErrBadRequest(w http.ResponseWriter, message string) {
	WriteError(w, http.StatusBadRequest, "bad_request", message)
}

func ErrUnauthorized(w http.ResponseWriter) {
	WriteError(w, http.StatusUnauthorized, "unauthorized", "authentication required")
}

func ErrForbidden(w http.ResponseWriter) {
	WriteError(w, http.StatusForbidden, "forbidden", "access denied")
}

func ErrNotFound(w http.ResponseWriter, resource string) {
	WriteError(w, http.StatusNotFound, "not_found", resource+" not found")
}

func ErrConflict(w http.ResponseWriter, message string) {
	WriteError(w, http.StatusConflict, "conflict", message)
}

func ErrInternal(w http.ResponseWriter) {
	WriteError(w, http.StatusInternalServerError, "internal_error", "an unexpected error occurred")
}
