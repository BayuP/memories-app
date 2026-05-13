package httpx

import (
	"net/http"
	"strings"

	"github.com/google/uuid"
)

// TokenVerifier is implemented by the auth package to avoid a circular import.
type TokenVerifier interface {
	VerifyAccessToken(token string) (userID string, err error)
}

// Authenticate validates a Bearer JWT and injects the user ID into the request
// context. Responds with 401 for missing or invalid tokens.
func Authenticate(verifier TokenVerifier) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")
			if !strings.HasPrefix(header, "Bearer ") {
				ErrUnauthorized(w)
				return
			}

			token := strings.TrimPrefix(header, "Bearer ")
			userIDStr, err := verifier.VerifyAccessToken(token)
			if err != nil {
				ErrUnauthorized(w)
				return
			}

			uid, err := uuid.Parse(userIDStr)
			if err != nil {
				ErrUnauthorized(w)
				return
			}

			next.ServeHTTP(w, r.WithContext(WithUserID(r.Context(), uid)))
		})
	}
}
