# Phase Status

## Phase 1 — Foundation ✅ DONE (commit on origin/main)
- Backend skeleton: config (caarlos0/env), slog logger, pgxpool, chi router, graceful shutdown
- Migration 0001: 9 domain tables + refresh_tokens + extensions (citext, pgcrypto) + updated_at trigger
- Auth: email/password signup/signin + JWT access(15m)/refresh(30d) with rotation, bcrypt cost 12
- Users: GET /me, GET /users/handle/:handle, handle regex validation
- Makefile (migrate/lint/fmt), .golangci.yml, 35 unit tests passing with -race
- Dockerfile + docker-compose.yml (postgres:16-alpine)

## Phase 2 — Trip Creation & AI Itinerary (NEXT)
- Trip CRUD + ownership checks
- Anthropic Claude integration (claude-sonnet + web search)
- POST /trips/:id/ai/generate, POST /refine
- Itinerary item CRUD + reorder
- Also: wire Google OAuth (decision: keep both auth methods)

## Phase 3 — Collaboration
trip_members CRUD, invite by @handle, concurrent edit semantics (TBD CRDT vs last-write-wins)

## Phase 4 — Check-in & Media
3-layer check-in flow, R2 presigned uploads, EXIF parsing for spontaneous bucket, logistics access guards

## Phase 5 — Publishing & Discovery
Public trip view (recommendation layer only), privacy audit confirming checkin_logistics never serialized

## Phase 6 — Polish & V1 Launch
Empty/error/loading states, push notifications, offline drafts, crash reporting, store listings

## V1 Success
Used on one real trip with wife + 3 small hangouts, beats WhatsApp + Notes.
