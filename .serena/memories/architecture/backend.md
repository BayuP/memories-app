# Backend Architecture — Modular Monolith (Go)

Flat per-module structure. Chose this over clean-architecture: simpler, sufficient for V1. Revisit only if cross-cutting concerns force it.

## Actual Layout
```
backend/
  cmd/server/main.go              # config -> logger -> pgxpool -> modules -> chi router -> http.Server (graceful shutdown SIGINT/SIGTERM); supports -migrate flag
  internal/
    config/                       # caarlos0/env loader from env vars (incl. S3_*, ANTHROPIC_API_KEY, GOOGLE_*)
    logger/                       # log/slog JSON (prod) / text (dev)
    db/                           # pgxpool init + golang-migrate runner
    httpx/                        # chi router setup; middleware: RequestID, Logger, Recover, CORS, Authenticate(TokenVerifier iface); errors.go centralizes JSON error envelope
    auth/                         # email/password signup + signin + refresh
    users/                        # GET /me, PATCH /me, GET /users/search, GET /users/handle/:handle
    trips/                        # trip CRUD + member management
    itinerary/                    # itinerary items CRUD + BulkCreateAI
    checkin/                      # 3-layer check-in: memory / logistics (PRIVATE) / recommendation
    publish/                      # public read-only views (no auth); logistics NEVER read here
    media/                        # presigned R2 upload flow + attach/delete
    ai/                           # AI itinerary generation + chat refinement
    adapter/
      storage/r2/                 # Cloudflare R2 client (aws-sdk-go-v2, BaseEndpoint, presign)
      external/anthropic/         # Anthropic SDK wrapper (generate + refine)
  migrations/0001_init.{up,down}.sql   # all 9 domain tables + refresh_tokens — NO additional migrations needed for Phase 2
```

## Module Conventions
Each domain package owns: `handler.go` (HTTP), `service.go` (business logic), `repository.go` (DB via pgx), `model.go` (domain types), `dto.go` (request/response). Service depends on repo interface for testability. No ORM.

Cross-package membership check via `TripChecker` interface (defined locally in each consuming package, satisfied by `trips.Repository`). Avoids circular imports.

## Privacy Rule — ENFORCED
`checkin_logistics` is member-only. Separate `LogisticsResponse` DTO. Never joined in public endpoints or AI prompt builder. Anthropic adapter never reads from logistics.

## Auth
- Email/password + JWT (access 15m, refresh 30d, rotation, hashed refresh_tokens table)
- Google OAuth: config slots present (GOOGLE_CLIENT_ID/SECRET); NOT implemented. Planned Phase 4.
- Bearer middleware injects user_id into request context via `httpx.UserIDFromContext`

## AI
- `adapter/external/anthropic` wraps `anthropic-sdk-go v1.43.0`
- Model: `claude-sonnet-4-6`
- Generate: structured JSON array itinerary, max_tokens 4096
- Refine: stateless chat (history in request body), rate-limited 20 msg/trip/day in-memory (reset on restart; Redis in V2)

## Media
- `adapter/storage/r2` wraps `aws-sdk-go-v2/service/s3` with `BaseEndpoint` (modern API, no deprecated EndpointResolverWithOptions)
- Upload flow: POST /media/upload-url → presigned PUT (15min TTL) → client uploads → PATCH /media/:id to attach to checkin

## Tests
35 unit tests pass with -race. Coverage: JWT, password, handle regex, auth service (mocked repos), users validate.

Integration tests added (commit d0eec1b):
- `internal/testdb/testdb.go` — Connect(t), Truncate(t, pool), MustCreateUser(t, pool, handle). Skips if `TEST_DATABASE_URL` unset.
- `internal/trips/repository_integration_test.go` — 5 real-DB repo tests
- `internal/itinerary/repository_integration_test.go` — 5 real-DB repo tests
- `internal/integration/auth_test.go` — 5 full-stack HTTP tests (signup/signin/refresh)
- `internal/integration/trips_test.go` — 6 full-stack HTTP tests (CRUD + member isolation)

Run all: `TEST_DATABASE_URL=postgres://memories:memories@localhost:5432/memories_app?sslmode=disable go test ./...`

## Key Dependencies
- `github.com/go-chi/chi/v5` — router
- `github.com/jackc/pgx/v5` — Postgres driver (pgxpool, pgtype.Date for nullable DATE columns)
- `github.com/golang-jwt/jwt/v5` — JWT
- `github.com/golang-migrate/migrate/v4` — DB migrations
- `github.com/aws/aws-sdk-go-v2/service/s3` — R2
- `github.com/anthropics/anthropic-sdk-go v1.43.0` — AI
- `github.com/caarlos0/env/v11` — config
