# Trip Memory App

Plan, capture, and remember shared experiences. Flutter mobile app + Go backend.

## Stack

- **Mobile:** Flutter (iOS + Android)
- **Backend:** Go modular monolith
- **Database:** PostgreSQL 16
- **Storage:** Cloudflare R2
- **AI:** Anthropic Claude (Sonnet) with web search

## Core Concepts

- **Trip** is the unit — full itinerary from departure to return.
- **3-layer check-in:**
  - **Memory** — shared with collaborators
  - **Logistics** — private, never sent to AI or public
  - **Recommendation** — publishable
- **AI itinerary generation** from destination, dates, vibes. Chat refinement.
- **Spontaneous bucket** — unplanned moments, EXIF time slot-in.
- **Collaborators** — Notion-style full edit access, invite by `@handle`.

## Privacy Rule

`checkin_logistics` never leaves the DB for AI calls, public endpoints, or published views. Enforced at the code level.

## Repository Layout

```
backend/    Go modular monolith (auth, trips, itinerary, checkin, profile)
frontend/   Flutter app (lib/core, lib/features, lib/shared)
```

---

## Development Phases

### Phase 1 — Foundation

**Goal:** Project scaffolding, auth, and base data model.

- [ ] Repo structure, CI, lint, formatting
- [ ] PostgreSQL schema + migrations (9 tables)
- [ ] Go backend skeleton: config, logger, DB pool, HTTP router
- [ ] Flutter app skeleton: routing, theme, state management
- [ ] Auth: sign up / sign in, JWT, session
- [ ] User profile + `@handle` uniqueness

**Exit criteria:** New user can sign up, log in, and view empty home screen.

---

### Phase 2 — Trip Creation & Itinerary

**Goal:** Create a trip and generate an AI itinerary.

- [ ] Create trip 3-step flow (destination, dates, vibes)
- [ ] Trips table CRUD + ownership
- [ ] Anthropic API integration (server-side)
- [ ] AI itinerary generation endpoint
- [ ] Itinerary review screen (accept / edit / regenerate)
- [ ] Chat refinement loop

**Exit criteria:** User creates trip, receives AI itinerary, edits it, saves it.

---

### Phase 3 — Collaboration

**Goal:** Multi-user editing on a trip.

- [ ] `trip_members` table + role model
- [ ] Invite by `@handle`
- [ ] Notion-style concurrent edit semantics (last-write-wins or CRDT — TBD)
- [ ] Activity feed (optional)
- [ ] Permission checks on every trip endpoint

**Exit criteria:** Two users collaboratively edit the same itinerary.

---

### Phase 4 — Check-in & Media

**Goal:** Capture moments during the trip.

- [ ] Check-in flow with 3 layers (Memory, Logistics, Recommendation)
- [ ] Media upload to Cloudflare R2 (presigned URLs)
- [ ] EXIF parsing → spontaneous bucket time slot-in
- [ ] Trip timeline screen (planned + spontaneous interleaved)
- [ ] Logistics encryption / access guards

**Exit criteria:** User checks in with photo + notes, timeline updates correctly.

---

### Phase 5 — Publishing & Discovery

**Goal:** Share trips publicly.

- [ ] Published trip view (Recommendation layer only)
- [ ] Public URL / share sheet
- [ ] Privacy audit: confirm `checkin_logistics` never serialized to public payloads
- [ ] Discovery feed (basic)

**Exit criteria:** A published trip is viewable on web with no private data leakage.

---

### Phase 6 — Polish & V1 Launch

**Goal:** Real-world usability for V1 success criterion.

- [ ] Empty / error / loading states across 9 screens
- [ ] Push notifications (trip updates, collab activity)
- [ ] Offline draft for check-ins
- [ ] Crash reporting + analytics
- [ ] App Store + Play Store listings

**V1 success:** Used on one real trip with wife + three small hangouts, beats WhatsApp + Notes.

---

## Getting Started

### Backend

```bash
cd backend
cp .env.example .env
make migrate
make run
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

## License

MIT — see [LICENSE](LICENSE).
