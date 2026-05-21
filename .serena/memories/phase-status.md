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

## Phase 5 — UI Design System Alignment ✅ DONE (commit 76b19ab, May 2026)
- HTML prototype built (10 screens): warm cream #F5F3EF, Playfair Display italic headings, near-black #1A1815 CTAs
- Flutter theme rebuilt: single source at core/theme/app_theme.dart — teal/coral removed, warm cream palette locked
- AppTheme extended: coral (#B5715A), coralLight, amber (#B8893D), amberLight, accentGreenDark color tokens added
- All feature pages migrated: auth, checkin, profile, create_trip, home, itinerary_review, public_trip, trip_timeline + trip_card widget
- 10 Flutter screens + 9 widgets (lib/ui/screens/, lib/ui/widgets/) updated to new theme imports
- Conflicting ui/theme/app_theme.dart deleted
- Design direction approved: warm cream (not pure B&W, not terracotta)

## Phase 4 — Frontend (Flutter) ✅ DONE (commit 7c7f367 + android platform added)
Flutter app scaffolded with full clean architecture (data/domain/presentation per feature).

**Done:**
- All screens: auth, home, create trip, trip timeline, itinerary review, check-in, public trip, profile
- Core: GoRouter + Riverpod providers + Dio ApiClient with JWT refresh interceptor
- Platform-conditional token storage: flutter_secure_storage (native) / shared_preferences (web)
- Android platform added via `flutter create --platforms=android .` — `android/` dir committed
- Web platform enabled (Chrome). macOS scaffolded (requires full Xcode.app — not CLI tools).
- iOS platform added (commit 5d3be1d): Runner, xcodeproj, xcworkspace, Flutter xcconfig, RunnerTests committed
- macOS CocoaPods: Podfile + Podfile.lock committed for reproducible dependency resolution
- Dockerfile fixed: golang:1.23 → golang:1.25 (go.mod requires go 1.25)
- Router fixed: root `/` now always redirects (to auth or home) instead of hanging on splash
- Handle `@` prefix stripped on signup; frontend validator matches backend regex `^[a-z0-9_]{3,30}$`

**Android emulator setup (local dev machine):**
- Android SDK at `/usr/local/share/android-commandlinetools` (via `brew install --cask android-commandlinetools`)
- AVD `Pixel8` created: `system-images;android-35;google_apis;x86_64`
- Java 26 installed — conflicts with Gradle 8.14. Fix: `brew install --cask temurin@21` + `flutter config --jdk-dir=...`
- Launch emulator: `flutter emulators --launch Pixel8`

**Remaining (V1 Polish):**
- Fix Java 26/Gradle 8.14 conflict for `flutter run` on emulator
- `backend/cmd/server/main.go:156` home feed with real trip data
- Audit Logistics layer privacy enforcement (no explicit handler-level check yet)
- Google OAuth
- POST /auth/logout
- EXIF parsing on spontaneous check-ins
- Push notifications
- Offline draft support
- Crash reporting + store listings

## V1 Success
Used on one real trip with wife + 3 small hangouts, beats WhatsApp + Notes.
