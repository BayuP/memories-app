package httpx

import (
	"log/slog"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
)

// RouterConfig carries the dependencies needed to build the application router.
type RouterConfig struct {
	Log      *slog.Logger
	Verifier TokenVerifier
}

// NewRouter builds the chi router with global middleware applied.
func NewRouter(cfg RouterConfig) chi.Router {
	r := chi.NewRouter()

	r.Use(RequestID)
	r.Use(Logger(cfg.Log))
	r.Use(Recover(cfg.Log))
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"},
		ExposedHeaders:   []string{"X-Request-ID"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		WriteJSON(w, http.StatusOK, map[string]string{"status": "ok"})
	})

	return r
}

// AuthMiddleware returns the Authenticate middleware bound to the given verifier.
func AuthMiddleware(verifier TokenVerifier) func(http.Handler) http.Handler {
	return Authenticate(verifier)
}
