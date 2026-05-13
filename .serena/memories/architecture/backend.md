# Backend Architecture — Modular Monolith (Go)

Phase 1 implemented. Layout diverged from earlier clean-architecture plan: chose simpler per-module flat structure (handler/service/repository/model/dto inside each domain package). Revisit only if cross-cutting concerns force it.

## Actual Layout
```
backend/
  cmd/server/main.go              # config -> logger -> pgxpool -> modules -> chi router -> http.Server (graceful shutdown SIGINT/SIGTERM); supports -migrate flag
  internal/
    config/                       # caarlos0/env loader from env vars
    logger/                       # log/slog JSON (prod) / text (dev)
    db/                           # pgxpool init + golang-migrate runner
    httpx/                        # chi router setup; middleware: RequestID, Logger, Recover, CORS, Authenticate(TokenVerifier iface); errors.go centralizes JSON error envelope
    auth/                         # email/password signup + signin + refresh
        jwt.go                    # JWTManager HS256, access ~15m + refresh ~30d
        password.go               # bcrypt cost 12
        repository.go             # refresh_tokens table (hashed, rotation, revoke)
        service.go                # SignUp / SignIn / Refresh (rotates refresh)
        handler.go                # /auth/signup /auth/signin /auth/refresh
        handle.go                 # handle regex shared
    users/                        # profile + @handle lookup (GET /me, GET /users/handle/:handle)
    trips/ itinerary/ checkin/ media/   # package-doc stubs only (Phase 2+)
  migrations/0001_init.{up,down}.sql
  Makefile                        # build/run/test/migrate-up/migrate-down/lint/fmt
  .golangci.yml                   # errcheck, govet, staticcheck, ineffassign, gofmt, revive
  Dockerfile + ../docker-compose.yml (postgres:16-alpine + backend)
```

## Module Conventions
Each domain package owns: `handler.go` (HTTP), `service.go` (business logic), `repository.go` (DB via pgx), `model.go` (domain types), `dto.go` (request/response). Service depends on repo interface for testability. No ORM.

## Privacy Rule
checkin_logistics carries inline SQL comment "PRIVATE — never serialize to public/AI". Compiler-level enforcement (separate DTOs/sub-packages) deferred to Phase 2+.

## Auth
- Email/password + JWT (access 15m, refresh 30d, rotation, hashed refresh_tokens table)
- Google OAuth: config slots present (GOOGLE_CLIENT_ID/SECRET); flow NOT implemented. Decision: keep both methods. Add Google ID-token verify + upsert flow in Phase 2/3.
- Bearer middleware injects user_id into request context

## Tests
35 unit tests pass with -race. Coverage: JWT issue/verify/expiry/wrong-type/bad-sig, password hash/check, handle regex, service SignUp/SignIn/Refresh (mocked repos).
