# Data Model — 9 Tables

## users
id (uuid PK), handle (unique), display_name, email (unique), password_hash, google_sub (unique), avatar_url, created_at

## trips
id (uuid PK), creator_id (FK users), name, destination, dest_lat, dest_lng, start_date, end_date, cover_photo_url, vibes (text[]), status (planning|active|completed), is_published (bool), created_at

## trip_members
id (uuid PK), trip_id (FK trips CASCADE), user_id (FK users), role (owner|collaborator), joined_at. UNIQUE(trip_id, user_id)

## itinerary_items
id (uuid PK), trip_id (FK trips CASCADE), created_by (FK users), type (flight|hotel|activity|restaurant|transit|other), name, notes, day_number, event_time, sort_order, is_spontaneous, lat, lng, created_at, updated_at

## checkins
id (uuid PK), item_id (FK itinerary_items CASCADE), user_id (FK users), event_time, logged_at, vibe (loved|ok|meh)

## checkin_memory
id (uuid PK), checkin_id (FK checkins CASCADE), note. UNIQUE(checkin_id)

## checkin_logistics — PRIVATE: never in publish queries, never sent to AI
id (uuid PK), checkin_id (FK checkins CASCADE), booking_ref, confirmation_code, cost, currency, private_notes. UNIQUE(checkin_id)

## checkin_recommendations
id (uuid PK), checkin_id (FK checkins CASCADE), would_recommend, tips, public_caption. UNIQUE(checkin_id)

## media
id (uuid PK), checkin_id (FK checkins CASCADE), uploaded_by (FK users), type (photo|video), storage_url, thumbnail_url, duration_sec, exif_taken_at, is_cover, sort_order, created_at