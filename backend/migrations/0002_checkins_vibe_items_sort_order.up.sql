ALTER TABLE checkins
  ADD COLUMN IF NOT EXISTS vibe TEXT CHECK (vibe IN ('loved', 'ok', 'meh'));

ALTER TABLE itinerary_items
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_itinerary_items_sort_order ON itinerary_items (trip_id, day, sort_order);
