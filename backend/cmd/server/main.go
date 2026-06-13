package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"

	anthropicadapter "github.com/BayuP/memories-app/backend/internal/adapter/external/anthropic"
	"github.com/BayuP/memories-app/backend/internal/adapter/storage/r2"
	"github.com/BayuP/memories-app/backend/internal/ai"
	"github.com/BayuP/memories-app/backend/internal/auth"
	"github.com/BayuP/memories-app/backend/internal/checkin"
	"github.com/BayuP/memories-app/backend/internal/config"
	"github.com/BayuP/memories-app/backend/internal/db"
	"github.com/BayuP/memories-app/backend/internal/httpx"
	"github.com/BayuP/memories-app/backend/internal/itinerary"
	"github.com/BayuP/memories-app/backend/internal/logger"
	"github.com/BayuP/memories-app/backend/internal/media"
	"github.com/BayuP/memories-app/backend/internal/publish"
	"github.com/BayuP/memories-app/backend/internal/story"
	"github.com/BayuP/memories-app/backend/internal/trips"
	"github.com/BayuP/memories-app/backend/internal/users"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "fatal: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	migrateFlag := flag.Bool("migrate", false, "run DB migrations on startup")
	flag.Parse()

	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}

	log := logger.New(cfg.Env)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if *migrateFlag {
		migrationsDir := migrationsDirPath()
		log.Info("running migrations", "dir", migrationsDir)
		if err := db.RunMigrations(cfg.DatabaseURL, migrationsDir); err != nil {
			return fmt.Errorf("migrations: %w", err)
		}
		log.Info("migrations complete")
	}

	pool, err := db.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("connect db: %w", err)
	}
	defer pool.Close()
	log.Info("database connected")

	// Wire dependencies.
	jwtManager := auth.NewJWTManager(cfg.JWTSecret, cfg.JWTAccessExpiry, cfg.JWTRefreshExpiry)

	userRepo := users.NewRepository(pool)
	authRepo := auth.NewRepository(pool)
	tripRepo := trips.NewRepository(pool)
	itnRepo := itinerary.NewRepository(pool)
	checkinRepo := checkin.NewRepository(pool)
	mediaRepo := media.NewRepository(pool)

	r2Client := r2.NewClient(r2.Config{
		Endpoint:  cfg.S3Endpoint,
		Bucket:    cfg.S3Bucket,
		AccessKey: cfg.S3AccessKey,
		SecretKey: cfg.S3SecretKey,
		Region:    cfg.S3Region,
	})
	anthropicClient := anthropicadapter.NewClient(cfg.AnthropicAPIKey)

	authSvc := auth.NewService(authRepo, userRepo, jwtManager)
	userSvc := users.NewService(userRepo)
	tripSvc := trips.NewService(tripRepo)
	itnSvc := itinerary.NewService(itnRepo, tripRepo)
	checkinSvc := checkin.NewService(checkinRepo, tripRepo)
	mediaSvc := media.NewService(mediaRepo, r2Client, tripRepo)
	aiSvc := ai.NewService(tripRepo, itnSvc, anthropicClient)

	storyRepo := story.NewRepository(pool)
	storySvc := story.NewService(storyRepo, tripRepo, checkinRepo, anthropicClient)
	storyHandler := story.NewHandler(storySvc, log)

	publishRepo := publish.NewRepository(pool)
	publishSvc := publish.NewService(publishRepo)
	publishHandler := publish.NewHandler(publishSvc, log)

	authHandler := auth.NewHandler(authSvc, log)
	userHandler := users.NewHandler(userSvc, log)
	tripHandler := trips.NewHandler(tripSvc, log)
	itnHandler := itinerary.NewHandler(itnSvc, log)
	checkinHandler := checkin.NewHandler(checkinSvc, log)
	mediaHandler := media.NewHandler(mediaSvc, log)
	aiHandler := ai.NewHandler(aiSvc, log)

	authMiddleware := httpx.AuthMiddleware(jwtManager)

	router := httpx.NewRouter(httpx.RouterConfig{Log: log, Verifier: jwtManager})

	router.Route("/api/v1", func(r chi.Router) {
		r.Route("/auth", authHandler.Routes())
		r.Group(userHandler.Routes(authMiddleware))
		r.With(authMiddleware).Group(tripHandler.Routes())
		r.With(authMiddleware).Group(itnHandler.Routes())
		r.With(authMiddleware).Group(checkinHandler.Routes())
		r.With(authMiddleware).Group(mediaHandler.Routes())
		r.With(authMiddleware).Group(aiHandler.Routes())
		r.With(authMiddleware).Group(storyHandler.Routes())
		r.With(authMiddleware).Get("/home", func(w http.ResponseWriter, r *http.Request) {
				callerID, ok := httpx.UserIDFromContext(r.Context())
				if !ok {
					httpx.ErrUnauthorized(w)
					return
				}
				ts, err := tripSvc.ListTrips(r.Context(), callerID)
				if err != nil {
					log.ErrorContext(r.Context(), "home list trips", "error", err)
					httpx.ErrInternal(w)
					return
				}
				if ts == nil {
					ts = []*trips.TripResponse{}
				}
				httpx.WriteJSON(w, http.StatusOK, map[string]any{"trips": ts})
			})
		r.Group(publishHandler.Routes())
	})

	addr := fmt.Sprintf(":%d", cfg.Port)
	srv := &http.Server{
		Addr:         addr,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	go func() {
		log.Info("server starting", "addr", addr, "env", cfg.Env)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Error("server error", "error", err)
		}
	}()

	<-ctx.Done()
	log.Info("shutting down")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("graceful shutdown: %w", err)
	}

	log.Info("server stopped")
	return nil
}


// migrationsDirPath returns the path to the migrations directory.
// In production the binary is typically co-located with the migrations/ dir.
func migrationsDirPath() string {
	if dir, ok := os.LookupEnv("MIGRATIONS_DIR"); ok {
		return dir
	}
	exe, err := os.Executable()
	if err != nil {
		return "migrations"
	}
	_ = exe
	return "migrations"
}

