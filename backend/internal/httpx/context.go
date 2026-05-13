package httpx

import (
	"context"

	"github.com/google/uuid"
)

type contextKey string

const (
	contextKeyUserID    contextKey = "user_id"
	contextKeyRequestID contextKey = "request_id"
)

// WithUserID stores the authenticated user's ID in the context.
func WithUserID(ctx context.Context, id uuid.UUID) context.Context {
	return context.WithValue(ctx, contextKeyUserID, id)
}

// UserIDFromContext retrieves the authenticated user's ID. Returns zero UUID if absent.
func UserIDFromContext(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(contextKeyUserID).(uuid.UUID)
	return id, ok
}

// WithRequestID stores a request ID in the context.
func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, contextKeyRequestID, id)
}

// RequestIDFromContext retrieves the request ID.
func RequestIDFromContext(ctx context.Context) string {
	id, _ := ctx.Value(contextKeyRequestID).(string)
	return id
}
