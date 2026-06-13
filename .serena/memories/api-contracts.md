# API Contracts

Base: `/api/v1`
Auth: `Authorization: Bearer <access>`
Error envelope: `{"error": {"code": "...", "message": "..."}}`
Success: plain JSON object
Timestamps: ISO 8601 UTC
Dates: `"YYYY-MM-DD"` string

## Implemented (Phase 1 + Phase 2) — all on origin/main

### Auth
- POST `/api/v1/auth/signup` — {email, password, handle, display_name} → TokenPair
- POST `/api/v1/auth/signin` — {email, password} → TokenPair (rotates refresh)
- POST `/api/v1/auth/refresh` — {refresh_token} → TokenPair

### Users (auth required unless noted)
- GET  `/api/v1/me` → ProfileResponse (with email)
- PATCH `/api/v1/me` — {display_name?, avatar_url?} → ProfileResponse
- GET  `/api/v1/users/search?q=<prefix>` → {users: [PublicProfileResponse]}
- GET  `/api/v1/users/handle/:handle` — **public** → PublicProfileResponse

### Trips (all auth required)
- POST   `/api/v1/trips` — {title, destination, start_date?, end_date?, vibes?} → TripDetailResponse
- GET    `/api/v1/trips` → {trips: [TripResponse]}
- GET    `/api/v1/trips/:id` → TripDetailResponse (trip + members[])
- PATCH  `/api/v1/trips/:id` — {title?, destination?, start_date?, end_date?, vibes?, status?} → TripDetailResponse
- DELETE `/api/v1/trips/:id` — owner only → 204
- POST   `/api/v1/trips/:id/members` — {user_id} → MemberResponse; member can invite
- DELETE `/api/v1/trips/:id/members/:userId` — owner only, can't remove self → 204

### Itinerary (auth required, trip-member only)
- GET    `/api/v1/trips/:id/items` → {items: [ItemResponse]} (ordered by day, start_time)
- POST   `/api/v1/trips/:id/items` — {day, title, start_time?, end_time?, description?, location_name?, lat?, lng?} → ItemResponse
- PATCH  `/api/v1/trips/:id/items/:itemId` — partial update → ItemResponse
- DELETE `/api/v1/trips/:id/items/:itemId` → 204

### Check-ins (auth required, trip-member only)
- POST `/api/v1/trips/:id/checkins` — {kind, captured_at, itinerary_item_id?, lat?, lng?} → CheckinResponse
- GET  `/api/v1/checkins/:id` → CheckinResponse (all 3 layers + media[])
- PUT  `/api/v1/checkins/:id/memory` — {note?, mood?, shared_with?} → MemoryResponse
- PUT  `/api/v1/checkins/:id/logistics` — {cost?, currency?, notes?} → LogisticsResponse (**PRIVATE — member only, never public**)
- PUT  `/api/v1/checkins/:id/recommendation` — {title, body, tags?, rating?} → RecommendResponse

### Media (auth required)
- POST   `/api/v1/media/upload-url` — {mime} → {media_id, upload_url, r2_key}; client PUT to upload_url then calls PATCH
- PATCH  `/api/v1/media/:id` — {checkin_id?, width?, height?, taken_at?, lat?, lng?} → MediaResponse
- DELETE `/api/v1/media/:id` — owner only; deletes R2 object + DB row → 204

### AI (auth required, trip-member only)
- POST `/api/v1/trips/:id/ai/generate` → {items: [ItemResponse]}; replaces source='ai' items
- POST `/api/v1/trips/:id/ai/refine` — {message, history: [{role, content}]} → {reply: string}; rate-limit 20/trip/day

### Story (Phase 8 — auth required, trip-member only)
- POST `/api/v1/trips/:tripID/story/generate` → {title, body, ...}; reuses Claude client; upserts trip_stories. Feeds memory notes/moods + recommendations ONLY — checkin_logistics excluded.
- GET  `/api/v1/trips/:tripID/story` → StoryResponse
- PATCH `/api/v1/trips/:tripID/story` — {title?, body?} → StoryResponse

### Infra
- GET `/healthz` — public → {status: "ok"}
- GET `/api/v1/home` — auth → {trips: []} (stub, replaced by GET /trips)

## Planned (Phase 3+)
- GET  `/api/v1/public/trips/:id` — **no auth**; recommendation layer only; checkin_logistics NEVER joined
- POST `/api/v1/trips/:id/publish` / `/unpublish`
- POST `/api/v1/auth/google` — Google ID token → TokenPair
- POST `/api/v1/auth/logout` — revoke refresh token
