# API Contracts

Base: `/api/v1` (implementation diverged from earlier `/v1` draft)
Auth: `Authorization: Bearer <access>`
Error envelope: `{"error": {"code": "...", "message": "..."}}`
Success: plain JSON object
Timestamps: ISO 8601 UTC

## Implemented (Phase 1)
- POST `/api/v1/auth/signup` — {email, password, handle, display_name} -> TokenPair
- POST `/api/v1/auth/signin` — {email, password} -> TokenPair
- POST `/api/v1/auth/refresh` — {refresh_token} -> TokenPair (rotates)
- GET  `/api/v1/me` — auth required -> ProfileResponse
- GET  `/api/v1/users/handle/:handle` — public -> PublicProfileResponse
- GET  `/api/v1/home` — auth required -> `{"trips": []}` (placeholder, Phase 2)
- GET  `/healthz` — liveness

TokenPair: `{access_token, refresh_token, access_expires_at, refresh_expires_at}`

## Planned (Phase 2+)
### Auth
- POST `/api/v1/auth/google` — Google ID token -> TokenPair (upsert user)
- POST `/api/v1/auth/logout`

### Trips
GET/POST `/api/v1/trips`, GET/PATCH/DELETE `/api/v1/trips/:id`
POST/DELETE `/api/v1/trips/:id/members`
POST `/api/v1/trips/:id/publish` / `/unpublish`

### Itinerary
GET/POST `/api/v1/trips/:id/items`, PATCH/DELETE `/api/v1/trips/:id/items/:itemId`, PATCH `/reorder`

### Check-ins (3-layer)
POST `/api/v1/trips/:id/items/:itemId/checkin`
PUT `/api/v1/checkins/:id/memory|logistics|recommendation`

### Media
POST `/api/v1/checkins/:id/media/upload-url` (R2 presigned)
POST `/api/v1/checkins/:id/media`

### AI
POST `/api/v1/trips/:id/ai/generate`, POST `/refine`

### Public (no auth)
GET `/api/v1/public/trips/:id` — recommendation layer only; checkin_logistics never joined
