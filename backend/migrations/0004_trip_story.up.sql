CREATE TABLE trip_stories (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id    UUID        UNIQUE NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  title      TEXT,
  body       TEXT,
  status     TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER set_trip_stories_updated_at
  BEFORE UPDATE ON trip_stories
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
