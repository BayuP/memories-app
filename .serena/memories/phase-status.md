# Phase Status

## Phase 8 — Design Mockup Gap Closure (9-screen mockup) ✅ DONE (2026-06-13)

Source: `adjust-plan.md` + mockup `007BBAC1-...PNG`. Closed the "memories consumption" half of the design. Backend = only Story; rest frontend.

### Backend — Story feature (`internal/story/`, NEW)
- Migration `0004_trip_story.up/.down.sql` (originally authored as 0003, renumbered — see migration-numbering note below): `trip_stories` table (id, `trip_id UNIQUE → trips ON DELETE CASCADE`, title, body, status, timestamps, `set_updated_at` trigger).
- Package files: story.go, model.go (`Story` + `ErrNotFound`/`ErrForbidden`), repository.go (pgxpool, `UpsertStory` INSERT…ON CONFLICT, `FindByTripID`), dto.go, service.go, handler.go.
- Routes (auth + membership-enforced via `tripRepo.IsMember`), mounted in `cmd/server/main.go`:
  - `POST /api/v1/trips/{tripID}/story/generate` — reuses existing Anthropic client via `ai.RefineItinerary(ctx, nil, prompt)`. Prompt fed memory notes/moods + recommendations ONLY.
  - `GET /api/v1/trips/{tripID}/story`
  - `PATCH /api/v1/trips/{tripID}/story`
- **Privacy:** `FindLogistics` never called in story service — `checkin_logistics` excluded from AI prompt (honors existing PRIVACY contract).
- `go build` clean. Pre-existing `go vet` failure in `internal/auth/service_test.go:141` (unrelated).

### Frontend — 6 new screens + cross-cutting
- **Feelings (Screen 3):** `features/checkin/presentation/feelings.dart` — shared `kFeelings` (5: amazing/love/good/neutral/sad), `moodEmoji()`/`moodLabel()`. Fixed blank `_moodEmoji()` in `trip_timeline_page.dart`. checkin header → "How are you feeling?". Persists to untyped `memory.mood` (no migration).
- **Memory detail (Screen 4):** `memory_detail_page.dart` read view (hero + feelings + thoughts + 3-col photo grid + fullscreen PageView). Route `/memories/:id`. Timeline tap → read view (edit reachable from inside).
- **Memories grid (Screen 7):** `features/memories/` — `allMemoriesProvider` (fan-out tripsProvider→listCheckins, media-only, newest-first), `memories_page.dart` month-grouped grid. Nav tab `AptTab.memories` → `/memories`.
- **People (Screen 8):** `trip_people_page.dart` + `shared/widgets/app_segmented_tabs.dart` (Timeline/Map/People). `addMember`(`{user_id}`, confirmed vs backend)/`removeMember` on trips repo+datasource. `_DoneCard` now shows real photo count + thumbnail.
- **Map (Screen 5):** `trip_map_page.dart` (flutter_map + OSM + markers). Coord capture in `checkin_page.dart._save()` via geolocator (graceful denial).
- **Story (Screen 6):** `features/story/` full clean-arch, wired to backend endpoints. Polaroid collage + narrative + generate/regenerate/edit/save. Entry: timeline `more_vert` overflow.
- **Memory Book (Screen 9):** `book/.../memory_book_page.dart` cover-mock STUB (Preview/Customize = placeholders). Entry: overflow menu.
- Deps: `flutter_map ^7`, `latlong2 ^0.9`, `geolocator ^13`. No codegen (hand-written notifiers).
- Native location config: iOS `NSLocationWhenInUseUsageDescription`, Android `ACCESS_FINE/COARSE_LOCATION`.
- `flutter analyze`: zero new issues.

### Migration-numbering fix (committed d45b322)
Two migrations both numbered 0002 (`add_item_category` + `checkins_vibe_items_sort_order`). golang-migrate uses numeric version → shadowed the vibe/sort_order one; it NEVER applied (Phase 6 vibe/reorder code was silently broken vs DB). Renumbered: vibe/sort_order → 0003, trip_story → 0004. Ran `make migrate-up` → DB now at **version 4**; `checkins.vibe`, `itinerary_items.sort_order`, `trip_stories` all present.

### Location autocomplete (Nominatim/OSM) — frontend only, no backend
- `core/location/geocoding_service.dart`: `GeocodingService.search()` + `PlaceSuggestion{displayName,lat,lng,shortLabel}`. Direct Dio to `nominatim.openstreetmap.org/search` (NOT the authed ApiClient). User-Agent `memories-app/1.0 bayupabisa@gmail.com`, ≥3-char guard, `[]` on error. Nominatim sends `lon` (not `lng`).
- `shared/widgets/location_autocomplete_field.dart`: reusable field + overlay dropdown, 400ms debounce. Overlay via `Overlay.of(context).insert` → root navigator overlay → renders ABOVE bottom sheet (verified on iOS sim). Manual-edit keeps last coords; clearing field → `onSelected(null)`.
- Wired: itinerary `_ActivitySheet` location field → stores `_lat`/`_lng`, sends `lat`/`lng` in create+patch item payloads (backend already accepts). `create_trip` destination refactored onto shared widget (coords still discarded — TODO).
- `trip_map_page.dart`: now also renders itinerary items with coords as amber square pins (distinct from check-in photo pins) + `_ItineraryPinCard`; `CameraFit.bounds` across all points.
- Verified: `integration_test/location_autocomplete_test.dart` passes on iOS sim against LIVE Nominatim (suggestion renders above sheet, tap fills field + coords). `integration_test` dev-dep added.

### Deferred to v2
Real trip cover photos; `GET /me/checkins` (N+1 in memories grid); Memory Book real export + Customize; Story share (`share_plus`); marker clustering; persist trip destination coords (geocoded but discarded — needs `trips.dest_lat/dest_lng` migration); check-in manual place field.

## Phase 7 — UX Polish & Frontend Restructure ✅ DONE (2026-05-31)

### Frontend restructure
- Legacy `lib/ui/screens/` + `lib/ui/widgets/` removed. Pages now live under `lib/features/*/presentation/pages/`; shared widgets under `lib/shared/widgets/` (app_bottom_nav, app_state_badge, app_states, app_trip_card, avatar_circle).

### Itinerary review (`itinerary_review_page.dart`)
- Bottom bar redesigned: **two rectangle buttons** via `_AddNextButtons` — `Add activity` (left, outlined) + `Next` (right, elevated). Used by both `_BottomSheet` (AI: chat row above buttons) and `_FinishBar` (manual).
- App-bar `Add` removed (moved to bottom).
- `Next` → `context.push('/trips/:id/itinerary-summary')` (full page, not a modal card). Old `_reviewAndFinish` modal-sheet recap deleted.
- Extracted shared helpers to top-level so the summary page reuses them: `groupItemsByDay`, `dayLabelFor`, `itemEmojiFor` (alongside existing `formatTime`).

### Itinerary summary page (`itinerary_summary_page.dart`, NEW)
- Full-page recap: trip header, `N days · M plans`, day-by-day list (emoji + time + title + location).
- Bottom: `Back to edit` (`context.pop()`) + `Confirm — let's go` (`context.go('/trips/:id/timeline')`).
- Route added in `app_router.dart`: `/trips/:id/itinerary-summary` → `ItinerarySummaryPage(tripId)`.

### Date picker
- Added `datePickerTheme` in `app_theme.dart` (day/weekday/year text `height: 1.0`) — cosmetic tightening.
- Investigated reported day-row "squish": NOT a real layout bug. M3 day-grid tile is hard-fixed at 48px; verified via on-simulator screenshots (real fonts, settled) the picker renders correctly. The screenshot artifact = mid-fade entrance + background form bleeding past the narrower dialog through the scrim + sim bezel.

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

## Phase 6 — Trip Timeline, Check-in & Home Feed Polish ✅ DONE (commit 0be5d2b, May 2026)

### Backend
- `GET /trips/{tripID}/checkins` — list all check-ins per trip (N+1 with memory, acceptable scale)
- User search excludes caller: fixed `_ = userID` bug in handler; `SearchByHandle` now takes `excludeID uuid.UUID`; SQL `AND id != $2`
- Itinerary items: `category` column added (migration 0002)

### Frontend
**Trip Day Timeline (`trip_timeline_page.dart`)**
- Full redesign: semantic card states — done (green), now (amber), upcoming (blue), spontaneous (green dashed)
- Edit/delete/insert activity: pencil + trash icons on cards, `_ActivitySheet` bottom sheet, `_confirmDeleteItem` dialog
- "Add activity here" dashed rows interleaved between items (`itemCount = items.length * 2 + 2`)
- Spontaneous moments: DB-backed via `tripCheckinsProvider`, collapsible `_SpontaneousGroup` (AnimatedSize + AnimatedRotation)
- Check-in button: `context.push<bool>` → `context.pop(true)` → invalidates `tripCheckinsProvider`
- Back button: `canPop()` guard → falls back to `context.go('/')` on root route
- Time display: `_fmtTime()` strips microseconds → `HH:mm`

**Check-in Page (`checkin_page.dart`)**
- View mode: `_loadExisting()` in `initState` populates all fields from `repo.getCheckin()`
- Button label: `isSpont ? 'save moment' : 'check in'`; spinner while saving
- `CheckinMemoryModel.fromJson`: fixed `shared_with` cast (`List<dynamic>` → join to String)

**Home & Journeys (`home_page.dart`)**
- New Journey button pinned to bottom (outside ListView)
- Home tab (0): greeting header + featured own trip + shared preview
- Journeys tab (1): all trips grouped — ongoing (green dot) / upcoming (amber dot) / past (gray dot)
- Trips split by `ownerId == currentUserId`: "Your journeys" vs "Shared with you" (blue badge)

**Create Trip (`create_trip_page.dart`)**
- Trip created on step 0 "looks good — let's go" button (spinner while creating)
- Step 1 becomes invite + AI/manual choice (trip already exists)
- `_createTripNow()` → `_buildItinerary(useAi)` separation

**Auth / Account Switch**
- `currentUserIdProvider`: `FutureProvider<String?>` calling `GET /me`
- Sign-out and sign-in both `ref.invalidate(tripsProvider, profileProvider, currentUserIdProvider)`
- Invite search: frontend filter `u.id != currentUserId` (+ backend exclusion above)

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

## Phase 6 — End-to-End Frontend Wiring ✅ DONE (May 2026)

**Goal:** Replace all mock/demo data with real API calls so app is usable on a real trip.

### Backend additions (done):
- `PATCH /checkins/{checkinID}` — update vibe + captured_at. Dynamic SET clause, returns full CheckinResponse.
- `PATCH /trips/{tripID}/items/reorder` — batch sort_order update. Registered before `{itemID}` wildcard in router.
- Migration `0002_checkins_vibe_items_sort_order.up.sql`: adds `vibe TEXT CHECK (vibe IN ('loved','ok','meh'))` to `checkins`, adds `sort_order INTEGER NOT NULL DEFAULT 0` + index to `itinerary_items`.
- `checkin.Checkin` model now includes `Vibe *string`; `CheckinResponse` exposes it.

### Frontend wiring (done):
- `HomeScreen` → `ConsumerStatefulWidget`, wired to `tripsProvider`. Mock trips removed. Derives UI `TripStatus` (ongoing/upcoming/past) from `startDate`/`endDate`. Deterministic `coverColor` from trip ID hash.
- `HomeScreen` navigation passes `tripId` + `tripTitle` to `TripViewScreen`.
- `TripViewScreen` → `ConsumerStatefulWidget`, accepts `tripId` + `tripTitle` params. Uses `itineraryItemsProvider(tripId)` for real items. Generates `DayItem` list from unique day numbers + trip `startDate`. Derives `TimelineItemState` from time-of-day. Passes `tripId`+`itemId`+`kind` to `CheckInScreen`.
- `CheckInScreen` → `ConsumerStatefulWidget`, accepts `tripId`, `itemId?`, `kind`. Real `image_picker` integration (`pickMultiImage`). Upload flow: `getUploadURL → uploadToR2 → attachMedia`. On submit: creates checkin, uploads files, saves memory layer (note+vibe), pops with `true`.

### Remaining for V1:
- Fix Java 26/Gradle 8.14 conflict for `flutter run` on Android emulator
- Audit Logistics layer privacy enforcement (no explicit handler-level check yet)
- Google OAuth (`POST /auth/google`)
- EXIF `takenAt` read from picked photo and sent on `attachMedia`
- Profile screen wired to real user data (`GET /users/me`)
- SpontaneousBucket wired (shows real spontaneous check-ins per day)
- Push notifications
- Offline draft support
- Crash reporting + store listings

## V1 Success
Used on one real trip with wife + 3 small hangouts, beats WhatsApp + Notes.
