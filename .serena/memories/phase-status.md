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
- 35 tests still pass, go vet clean.

## Phase 3 — Publishing & Public View (NEXT)
- GET /public/trips/:id — recommendation layer only; checkin_logistics NEVER joined (SQL-level enforcement)
- POST /trips/:id/publish / unpublish (toggle trip_status to 'published')
- Explore feed (GET /public/trips) — V2 scope
- Postgres RLS on checkin_logistics as defence-in-depth (V2)

## Phase 4 — Polish & V1 Launch
- Google OAuth (config slots present, flow not implemented)
- POST /auth/logout (refresh token revocation endpoint)
- EXIF parsing on spontaneous check-ins
- Push notifications
- Offline draft support
- Crash reporting + store listings

## V1 Success
Used on one real trip with wife + 3 small hangouts, beats WhatsApp + Notes.
