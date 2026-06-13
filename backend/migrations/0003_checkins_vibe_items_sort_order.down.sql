DROP INDEX IF EXISTS idx_itinerary_items_sort_order;
ALTER TABLE itinerary_items DROP COLUMN IF EXISTS sort_order;
ALTER TABLE checkins DROP COLUMN IF EXISTS vibe;
