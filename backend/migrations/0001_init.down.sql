DROP TABLE IF EXISTS media;
DROP TABLE IF EXISTS checkin_recommendations;
DROP TABLE IF EXISTS checkin_logistics;
DROP TABLE IF EXISTS checkin_memory;
DROP TABLE IF EXISTS checkins;
DROP TABLE IF EXISTS itinerary_items;
DROP TABLE IF EXISTS trip_members;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS users;

DROP TYPE IF EXISTS checkin_kind;
DROP TYPE IF EXISTS itinerary_source;
DROP TYPE IF EXISTS member_role;
DROP TYPE IF EXISTS trip_status;

DROP FUNCTION IF EXISTS set_updated_at();

DROP EXTENSION IF EXISTS "citext";
DROP EXTENSION IF EXISTS "pgcrypto";
