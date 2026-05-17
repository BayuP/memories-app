# Phase Status

## Phase 1 — Foundation ✅ DONE (commit 4e4e099)
- Backend skeleton: config (caarlos0/env), slog logger, pgxpool, chi router, graceful shutdown
- Migration 0001: 9 domain tables + refresh_tokens + extensions (citext, pgcrypto) + updated_at trigger
- Auth: email/password signup/signin + JWT access(15m)/refresh(30d) with rotation, bcrypt cost 12
- Users: GET /me, GET /users/handle/:handle, handle regex validation
- Makefile (migrate/lint/fmt), .golangci.yml, 35 unit tests passing with -race
- Dockerfile + docker-compose.yml (postgres:16-alpine)

## Phase 2 — Trip Capture & AI ✅ DONE (pushed to origin/main)
- **Users enhanced**: PATCH /me (update display_name/avatar_url), GET /users/search?q= (prefix handle search)
- **Trips**: full CRUD + member management (7 endpoints). Auto-enrol owner on create. Permission: members edit, owner-only delete/removeMember.
- **Itinerary**: items CRUD grouped by day, source=ai|user tracking (4 endpoints). BulkCreateAI replaces source=ai items.
- **Check-ins (3-layer)**: create checkin + GET full detail + PUT memory/logistics/recommendation (5 endpoints). Logistics private — member-only, never in public/AI paths.
- **Media**: presigned R2 upload flow. POST /media/upload-url → client uploads to R2 → PATCH /media/:id to attach. DELETE removes R2 + DB row.
- **AI**: POST /trips/:id/ai/generate (claude-sonnet-4-6, structured JSON itinerary), POST /trips/:id/ai/refine (stateless chat, history in body). In-memory rate limit 20 msg/trip/day.
- **R2 adapter**: `adapter/storage/r2` wraps aws-sdk-go-v2 with BaseEndpoint for Cloudflare R2.
- **Anthropic adapter**: `adapter/external/anthropic` wraps anthropic-sdk-go v1.43.0.
- 35 unit tests still pass, go vet clean.
- **Integration tests added** (commit d0eec1b): `internal/testdb` helper (Connect/Truncate/MustCreateUser), trips repo tests (5), itinerary repo tests (5), auth HTTP tests (5), trips HTTP tests (6). Run with `TEST_DATABASE_URL=<url> go test ./...`.

## Phase 3 — Publishing & Public View ✅ DONE (commit 9b793d6)
- POST /trips/:id/publish — owner-only, sets status='published'
- POST /trips/:id/unpublish — owner-only, reverts status='active'
- GET /public/trips/:id — no auth; returns trip + itinerary items + checkin_recommendations; checkin_logistics NEVER queried (SQL-level enforcement)
- New `internal/publish` package (6 files): model, dto, repository, service, handler, publish.go
- Explore feed (GET /public/trips) — V2 scope, deferred
- Postgres RLS on checkin_logistics — V2 defence-in-depth, deferred

## Phase 4 — Frontend (Flutter) 🔄 IN PROGRESS
Flutter app scaffolded with full clean architecture (data/domain/presentation per feature).

**Done:**
- All screens: auth, home, create trip, trip timeline, itinerary review, check-in, public trip, profile
- Core: GoRouter + Riverpod providers + Dio ApiClient with JWT refresh interceptor
- Platform-conditional token storage: flutter_secure_storage (native) / shared_preferences (web)
- Web platform enabled (Chrome). macOS scaffolded (requires full Xcode.app — not CLI tools).
- Dockerfile fixed: golang:1.23 → golang:1.25 (go.mod requires go 1.25)
- Router fixed: root `/` now always redirects (to auth or home) instead of hanging on splash
- Handle `@` prefix stripped on signup; frontend validator matches backend regex `^[a-z0-9_]{3,30}$`

**Blocked:**
- `OperationError` on web signup — under investigation (browser DevTools JS trace needed)
- Backend Docker must be rebuilt (`--no-cache`) before end-to-end testing

**Remaining (V1 Polish):**
- Google OAuth
- POST /auth/logout
- EXIF parsing on spontaneous check-ins
- Push notifications
- Offline draft support
- Crash reporting + store listings

## V1 Success
Used on one real trip with wife + 3 small hangouts, beats WhatsApp + Notes.
