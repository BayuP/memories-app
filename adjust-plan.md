# Adjustment Plan — Design Mockup → Implementation Gap (Memories App)

> Source of truth: design mockup `007BBAC1-B347-4819-A228-34438E2164F5.PNG` (3×3 grid, 9 screens).

## Context

The 9-screen design mockup describes the full target UX for the Memories travel-journaling app. The current Flutter app (Riverpod + GoRouter + Freezed + Dio, Go/Chi/Postgres backend) implements the trip-planning core (home, timeline, create-trip wizard, AI itinerary, check-in form, public view, profile) but is **missing the "memories consumption" half** of the design: map view, story, memories calendar grid, dedicated people page, memory book, a polished memory-detail read view, and a richer feeling/emoji picker.

This plan closes every gap, sequenced by dependency. Most work is pure frontend; only the **Story** feature needs new backend. Decisions made with the user:
- **Scope:** all 9 screens, dependency-sequenced.
- **Map library:** `flutter_map` + `latlong2` (OSM tiles, no API key, no native config).
- **Memory Book:** cover-mock screen + buttons as a stub (no PDF/export yet).
- **Feeling/emoji:** Option A — expand the untyped `checkin_memory.mood` field from 3 → 5 values, **no migration**.

### Key facts about current state (verified)
- Mood is stored in `checkin_memory.mood TEXT` (free text, no DB constraint). Frontend writes only `love | neutral | sad`. The separate `checkins.vibe` enum (`loved|ok|meh`) exists in DB but is **unused** by Flutter — leave it alone.
- `_moodEmoji()` in `trip_timeline_page.dart` (~lines 1577-1584) returns **empty strings** — latent bug; fix during the emoji work.
- `lat`/`lng` columns exist on `itinerary_items`, `checkins`, `media`, and flow through DTOs — but the Flutter check-in flow **never sets them** (`createCheckin` called with no coords in `checkin_page.dart` ~line 826). Map pins stay empty until coord capture is added.
- Dead stubs already present to wire: timeline app bar `person_add_outlined` (`onPressed: () {}` ~line 266) and `more_vert` (~line 271); `AppTab.memories` "Coming soon" snackbar in `home_page.dart` (~line 87) and `trip_timeline_page.dart` (~line 201).
- Reusable widgets: `AvatarCircle`/`AvatarStack` (`shared/widgets/avatar_circle.dart`), `AppTripCard` (`app_trip_card.dart`, hero/list — gradient placeholder, no real photos), `AppStateBadge`, `AppEmptyState`/`AppErrorState` (`app_states.dart`), `AppBottomNav` (`app_bottom_nav.dart`). Theme tokens in `core/theme/app_theme.dart` (cream `#F5F3EF`, Playfair Display headings, accentGreen/coral/amber).
- Providers: `tripsProvider`, `tripDetailProvider(tripId)`, `itineraryItemsProvider(tripId)`, `tripCheckinsProvider(tripId)`, `checkinDetailProvider(checkinId)`.

### New routes to add (all in `frontend/lib/core/router/app_router.dart`)
| Route | Page | Screen |
|---|---|---|
| `/memories/:id` | `MemoryDetailPage` | 4 |
| `/memories` | `MemoriesPage` | 7 |
| `/trips/:id/map` | `TripMapPage` | 5 |
| `/trips/:id/people` | `TripPeoplePage` | 8 |
| `/trips/:id/story` | `TripStoryPage` | 6 |
| `/trips/:id/book` | `MemoryBookPage` | 9 |

### Dependencies to add to `frontend/pubspec.yaml`
- `flutter_map`, `latlong2` (map)
- `geolocator` (capture check-in coords)
- (Memory Book is a stub — **no** `pdf`/`printing` needed yet.)

---

## Build sequence

Ordered so each step unlocks the next. Steps 1–4 are pure frontend; step 5 adds backend; step 6 is a stub.

---

### STEP 1 — Feeling/emoji picker (Screen 3) + `_moodEmoji` bug fix

**Goal:** "New Checkpoint" feeling row goes 3 → 5 emojis; fix blank mood emojis everywhere they render.

**Files to modify:**
- `frontend/lib/features/checkin/presentation/pages/checkin_page.dart`
  - Replace the 3 hardcoded `_VibeButton`s (~lines 577-608) with a row generated from a new top-level const:
    ```dart
    const kFeelings = <({String value, String emoji, String label})>[
      (value: 'amazing', emoji: '🤩', label: 'Amazing'),
      (value: 'love',    emoji: '😍', label: 'Loved it'),
      (value: 'good',    emoji: '😊', label: 'Good'),
      (value: 'neutral', emoji: '😐', label: 'Okay'),
      (value: 'sad',     emoji: '😔', label: 'Tough'),
    ];
    ```
    (Confirm exact emojis against the mockup when implementing.)
  - Relabel the section header from "Vibe" → **"How are you feeling?"**.
  - Persistence unchanged: still write the selected `value` into `memory.mood` via the existing `updateMemory(mood:)` path. No DTO/migration change (field is untyped `TEXT`).
  - "What's happening?" → keep mapping to the existing short note field. "Write your thoughts" → keep mapping to `memory.note` (the longer field). Do **not** add a new `caption` column for v1 — single `note` field is enough; revisit only if both must persist independently.
- `frontend/lib/features/trips/presentation/pages/trip_timeline_page.dart`
  - Fill in `_moodEmoji()` (~lines 1577-1584) with all 5 cases from `kFeelings` (extract `kFeelings` to a shared location, e.g. a new `frontend/lib/features/checkin/presentation/feelings.dart`, and import it in both files to avoid duplication). Ensure `_SpontaneousCheckinCard` and any done-card mood rendering use it.

**Reuse:** existing `updateMemory` repo method, `checkinDetailProvider`.
**Backend:** none.

---

### STEP 2 — Memory detail read view (Screen 4)

**Goal:** Tapping a memory opens a polished read-only page (hero photo, Feelings, Thoughts, Photos grid), not the edit form.

**New file:** `frontend/lib/features/checkin/presentation/pages/memory_detail_page.dart`
- `MemoryDetailPage extends ConsumerWidget`, param `checkinId`.
- Watch `checkinDetailProvider(checkinId)`.
- Layout:
  - Hero: `media.first.url` full-width image (fallback to placeholder if no media).
  - **Feelings**: big `_moodEmoji(memory.mood)` + label (reuse `kFeelings` label lookup).
  - **Thoughts**: `memory.note` body (Playfair/Inter per theme).
  - **Photos**: 3-col `GridView` of all `media` URLs; tap → full-screen viewer (simple `Dialog`/`PageView`).
  - App bar **edit** action → push existing edit route `/checkins/$checkinId?tripId=...`.

**Modify:**
- `frontend/lib/core/router/app_router.dart`: add `/memories/:id` → `MemoryDetailPage`.
- `trip_timeline_page.dart` `onTapCheckin` (~lines 529-531): push `/memories/${c.id}` (read view) instead of the edit form. Edit stays reachable from inside the detail page.

**Reuse:** `checkinDetailProvider`, `MediaEntity`, theme, `AppStateBadge` (optional).
**Backend:** none (GET `/checkins/{id}` already returns memory + media).

---

### STEP 3 — Memories calendar grid (Screen 7) + wire Memories nav tab

**Goal:** Memories bottom-nav tab opens a real gallery grouped by month ("May 2024" + photo grid).

**New files:**
- `frontend/lib/features/memories/presentation/providers/memories_provider.dart`
  - `allMemoriesProvider`: fan out over `tripsProvider`, call per-trip `listCheckins`, concatenate, keep ones with media, sort by `captured_at` desc.
  - *(Optional perf later: backend `GET /me/checkins` to avoid N+1 — not required for v1.)*
- `frontend/lib/features/memories/presentation/pages/memories_page.dart`
  - `MemoriesPage`: group `allMemoriesProvider` results by `captured_at` month → section header `"MMMM yyyy"` (intl `DateFormat`) + 3-col `GridView` of thumbnails. Tap thumbnail → `/memories/:id` (Step 2). Empty → `AppEmptyState`.

**Modify:**
- `home_page.dart` (~line 87) and `trip_timeline_page.dart` (~line 201): replace `AppTab.memories` "Coming soon" snackbar with `context.push('/memories')`.
- `app_router.dart`: add `/memories` → `MemoriesPage`.

**Reuse:** `tripsProvider`, per-trip `listCheckins`, `MediaEntity`, `AppEmptyState`, theme, `intl`.
**Backend:** none (month grouping computed client-side from `captured_at`).

---

### STEP 4 — People page (Screen 8) + segmented tabs on timeline (Screen 2)

**Goal:** Dedicated "People in this journey" page (avatar + name + role + remove, "Add People"); add Timeline/Map/People segmented control to the trip screen.

**New shared widget:** `frontend/lib/shared/widgets/app_segmented_tabs.dart`
- `AppSegmentedTabs` (labels `['Timeline','Map','People']`), styled like the existing underline tab selector in `checkin_page.dart` (`_buildTabSelector`). Emits selected index.

**New file:** `frontend/lib/features/trips/presentation/pages/trip_people_page.dart`
- `TripPeoplePage`, param `tripId`. Watch `tripDetailProvider(tripId)`.
- Header "People in this journey" + list: each row = `AvatarCircle` + `displayName` + role chip (`AppStateBadge`, owner/editor) + remove (owner only) → `DELETE /trips/{id}/members/{userId}`.
- "Add People" button → bottom sheet: search user by handle (`GET /users/search?q=`), select → add member.
  - **Verify the add-member payload** in `backend/internal/trips/handler.go` `h.addMember` — it expects `{user_id}` (resolve handle → user via search first) vs `{handle}`. Wire accordingly.

**Modify:**
- `trips_provider.dart` / trips repository: add `addMember(tripId, userId)` / `removeMember(tripId, userId)`; invalidate `tripDetailProvider(tripId)` after each. (Check for existing methods first.)
- `trip_timeline_page.dart`: mount `AppSegmentedTabs` below the app bar subheader. Timeline → current body; Map → `context.push('/trips/$tripId/map')`; People → `context.push('/trips/$tripId/people')`. Also wire the dead `person_add_outlined` button (~line 266) → People page.
- `app_router.dart`: add `/trips/:id/people` → `TripPeoplePage` (and `/trips/:id/map` placeholder used in Step 5).

**Also (Screen 2 polish):** enrich timeline item cards (`_DoneCard`) — replace hardcoded `"0 photos"` (~line 1153) with the real count + a leading thumbnail from the matched check-in's `media.first.url` (the match is already computed via `checkedInItemIds`).

**Reuse:** `AvatarCircle`, `AppStateBadge`, `tripDetailProvider`, user search endpoint, theme.
**Backend:** none new (members CRUD + user search already exist).

---

### STEP 5 — Map view (Screen 5) + coord capture + Story (Screen 6)

#### 5a. Map view (frontend only)

**Add deps:** `flutter_map`, `latlong2`, `geolocator` in `pubspec.yaml`.

**New file:** `frontend/lib/features/trips/presentation/pages/trip_map_page.dart`
- `TripMapPage`, param `tripId`. Watch `tripCheckinsProvider(tripId)` + `itineraryItemsProvider(tripId)`; collect points with non-null `lat`/`lng`.
- `FlutterMap` + OSM `TileLayer` + `MarkerLayer`: each marker = small rounded photo thumbnail (`media.first.url`) or category emoji pin. Optional clustering later (`flutter_map_marker_cluster`).
- Bottom selected-memory card (`_MapMemoryCard`, mirror `_SpontaneousCheckinCard` visuals) → tap pushes `/memories/:id` (Step 2).
- Empty state if no geotagged memories yet.

**Coord capture** (so pins populate): in `checkin_page.dart._save()` (~line 826), obtain device location via `geolocator` and pass `lat`/`lng` into `repo.createCheckin(...)`. Optionally read EXIF GPS from picked images and attach via `repo.attachMedia(..., lat:, lng:)`. Handle permission denial gracefully (skip coords).

**Modify:** `app_router.dart` `/trips/:id/map` → `TripMapPage` (replace placeholder). Entry: Map segmented tab (Step 4).
**Backend:** none (lat/lng already in payloads/responses).

#### 5b. Story "Our Bali Story" (Screen 6) — needs backend

**Backend (new):**
- Migration `backend/internal/migrations/0003_trip_story.up.sql` (+ `.down.sql`):
  ```sql
  CREATE TABLE trip_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID UNIQUE NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    title TEXT,
    body TEXT,
    status TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
  ```
- New package `backend/internal/story/` (handler.go, service.go, dto.go, repo) mounted in `cmd/server/main.go`:
  - `POST /trips/{tripID}/story/generate` → reuse the Claude client from `internal/ai`; feed trip + check-in **memory** notes/moods + recommendations. **Exclude `checkin_logistics`** (marked private). Upsert `trip_stories`, return `{title, body}`.
  - `GET /trips/{tripID}/story` → fetch saved story.
  - `PATCH /trips/{tripID}/story` → manual title/body edits.

**Frontend (new feature folder, clean-arch mirror):** `frontend/lib/features/story/`
- `domain/entities/story_entity.dart`, `domain/repositories/story_repository.dart`
- `data/models/story_model.dart`, `data/datasources/story_remote_datasource.dart`, `data/repositories/story_repository_impl.dart`
- `presentation/providers/story_provider.dart`, `presentation/pages/trip_story_page.dart`
- `TripStoryPage`: polaroid collage (`Wrap`/`Stack` of `Transform.rotate` photo cards from trip media), narrative `body` (Playfair/Inter), action row: regenerate (calls generate, loading state), edit (inline editor → PATCH), share (defer or use system share later).
- **Route:** `app_router.dart` `/trips/:id/story` → `TripStoryPage`. Entry: timeline `more_vert` overflow menu (wire the dead `onPressed: () {}` ~line 271) → "Story".

**Reuse:** Claude client (`internal/ai`), `MediaEntity`, theme.

---

### STEP 6 — Memory Book (Screen 9) — cover-mock stub

**Goal:** Book-cover screen + "Preview Book" / "Customize" buttons as a stub. No PDF/export.

**New file:** `frontend/lib/features/book/presentation/pages/memory_book_page.dart`
- `MemoryBookPage`, param `tripId`. Watch `tripDetailProvider(tripId)`.
- Render a book-cover mock: `Container` with shadow + spine gradient + trip title (Playfair) + cover photo (trip's first media / featured). Use theme tokens + `AppShadows.elevated` (if present, else a `BoxShadow`).
- "Preview Book" → snackbar/placeholder ("Coming soon") for now.
- "Customize" → placeholder sheet (cover photo / title / theme) — stub.

**Modify:**
- `app_router.dart`: add `/trips/:id/book` → `MemoryBookPage`.
- Entry: timeline `more_vert` overflow menu → "Memory Book" (alongside "Story" from Step 5).

**Backend:** none (stub). Server-side PDF export is a future v2 (`POST /trips/{id}/book/export` → R2 URL).

---

## Cross-cutting checklist
- [ ] Extract `kFeelings` to one shared file; import in `checkin_page.dart` + `trip_timeline_page.dart`.
- [ ] Fix `_moodEmoji()` blank cases.
- [ ] All 6 new routes registered in `app_router.dart`.
- [ ] Wire 3 dead stubs: `person_add_outlined` → People; `more_vert` → overflow (Story, Book); `AppTab.memories` → `/memories`.
- [ ] Add segmented Timeline/Map/People tabs to the trip screen.
- [ ] Add `flutter_map`, `latlong2`, `geolocator` to `pubspec.yaml`; run `flutter pub get`.
- [ ] Run codegen if entities/providers use Freezed/Riverpod annotations: `dart run build_runner build --delete-conflicting-outputs`.
- [ ] Backend: create + run migration `0003_trip_story`; mount `internal/story` routes in `cmd/server/main.go`.

## Verification (end-to-end)
1. **Backend:** `cd backend && go build ./... && go test ./...`; apply migration; `curl` the new story endpoints (`POST/GET/PATCH /trips/{id}/story`).
2. **Frontend:** `cd frontend && flutter analyze` (zero new errors) → `flutter run` (or use the `/run` skill).
3. Manual walkthrough vs mockup, screen by screen:
   - Screen 3: open New Checkpoint → 5 emojis render + select + save → reopen shows selected feeling.
   - Screen 4: tap a memory on the timeline → read-only detail (hero, feelings, thoughts, photo grid); edit button reopens the form.
   - Screen 7: Memories nav tab → month-grouped grid; tap thumbnail → detail.
   - Screen 8: trip People tab → list with roles; Add People (handle search) adds a member; remove works.
   - Screen 2: segmented Timeline/Map/People switches views; item cards show real photo count/thumbnail.
   - Screen 5: Map tab → pins for geotagged check-ins; create a check-in with location permission granted → new pin appears; tap pin card → detail.
   - Screen 6: overflow → Story → Generate produces narrative + polaroid collage; edit + regenerate work.
   - Screen 9: overflow → Memory Book → cover mock renders with trip title/photo; buttons show stub placeholders.
4. Confirm private logistics never appears in the generated Story.

## Open decisions deferred to v2
- Real trip cover photos (`trips.cover_media_id` migration + `AppTripCard` image rendering) — currently gradient placeholder.
- `GET /me/checkins` convenience endpoint to avoid N+1 in the Memories grid.
- Memory Book real export (client `pdf`/`printing` or server-side R2 PDF) + Customize functionality.
- Story share (`share_plus`) and marker clustering (`flutter_map_marker_cluster`).
