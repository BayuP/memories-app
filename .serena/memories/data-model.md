# Data Model — Phase 1 Migration

Implemented in `backend/migrations/0001_init.up.sql`. Extensions: citext, pgcrypto. All tables: `id uuid PK default gen_random_uuid()`, `created_at`, `updated_at` (trigger). Field names differ from earlier draft — implementation is source of truth.

## users
id, email (citext UNIQUE), password_hash, handle (citext UNIQUE, `^[a-z0-9_]{3,30}$`), display_name, avatar_url nullable

## refresh_tokens (Phase 1 addition for JWT rotation)
id, user_id FK users, token_hash, expires_at, revoked_at nullable

## trips
id, owner_id FK users, title, destination, start_date date, end_date date, vibes text[], status enum(draft|planned|active|completed|published)

## trip_members
id, trip_id FK trips, user_id FK users, role enum(owner|editor), UNIQUE(trip_id,user_id)

## itinerary_items
id, trip_id FK trips, day int, start_time time, end_time time, title, description, location_name, lat numeric nullable, lng numeric nullable, source enum(ai|user)

## checkins
id, trip_id FK trips, author_id FK users, itinerary_item_id FK itinerary_items nullable, captured_at, lat nullable, lng nullable, kind enum(planned|spontaneous)

## checkin_memory
id, checkin_id FK checkins UNIQUE, note, mood, shared_with text[]   -- placeholder ACL

## checkin_logistics — PRIVATE (SQL comment in migration)
id, checkin_id FK checkins UNIQUE, cost numeric(12,2), currency char(3), notes
Never serialized to public endpoints, AI calls, or published views.

## checkin_recommendations
id, checkin_id FK checkins UNIQUE, title, body, tags text[], rating int CHECK 1..5

## checkin_recommendations.media — not separate table
## media
id, checkin_id FK checkins nullable, owner_id FK users, r2_key, mime, width, height, taken_at, lat nullable, lng nullable

## Indexes
FKs + users.handle, users.email, refresh_tokens.user_id, refresh_tokens.expires_at
