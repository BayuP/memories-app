# API Contracts

Base: /v1 — Auth: Bearer JWT — Errors: { "error": { "code", "message" } } — Timestamps: ISO 8601 UTC

## Auth
POST /auth/register, /auth/login, /auth/google, /auth/refresh, /auth/logout

## Users
GET /users/me, PATCH /users/me, GET /users/search?q=, GET /users/:id

## Trips
GET /trips, POST /trips, GET /trips/:id, PATCH /trips/:id, DELETE /trips/:id
POST /trips/:id/members, DELETE /trips/:id/members/:userId
POST /trips/:id/publish, POST /trips/:id/unpublish

## Itinerary
GET /trips/:id/items, POST /trips/:id/items, PATCH /trips/:id/items/:itemId
DELETE /trips/:id/items/:itemId, PATCH /trips/:id/items/reorder

## Check-ins
POST /trips/:id/items/:itemId/checkin, PATCH /checkins/:checkinId, GET /checkins/:checkinId
PUT /checkins/:checkinId/memory, PUT /checkins/:checkinId/logistics, PUT /checkins/:checkinId/recommendation

## Media
POST /checkins/:checkinId/media/upload-url (presigned S3)
POST /checkins/:checkinId/media, PATCH /media/:mediaId, DELETE /media/:mediaId

## AI
POST /trips/:id/ai/generate, POST /trips/:id/ai/refine

## Public (no auth)
GET /public/trips/:id — recommendation layer ONLY, never joins checkin_logistics
GET /public/trips — explore feed (V2)