package logger

import (
	"log/slog"
	"os"
)

// New returns a slog.Logger configured for the given environment.
// JSON handler is used in production; text handler is used otherwise.
func New(env string) *slog.Logger {
	var handler slog.Handler
	opts := &slog.HandlerOptions{Level: slog.LevelInfo}

	if env == "production" {
		handler = slog.NewJSONHandler(os.Stdout, opts)
	} else {
		handler = slog.NewTextHandler(os.Stdout, opts)
	}

	return slog.New(handler)
}
