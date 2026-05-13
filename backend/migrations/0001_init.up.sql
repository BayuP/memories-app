-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

-- updated_at auto-update trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- users
CREATE TABLE users (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email        CITEXT      NOT NULL UNIQUE,
  password_hash TEXT        NOT NULL,
  handle       CITEXT      NOT NULL UNIQUE CHECK (handle ~ '^[a-z0-9_]{3,30}$'),
  display_name TEXT        NOT NULL,
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_users_email  ON users (email);
CREATE INDEX idx_users_handle ON users (handle);

-- refresh_tokens
CREATE TABLE refresh_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash TEXT        NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens (token_hash);

-- trips
CREATE TYPE trip_status AS ENUM ('draft', 'planned', 'active', 'completed', 'published');

CREATE TABLE trips (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  destination TEXT        NOT NULL,
  start_date  DATE,
  end_date    DATE,
  vibes       TEXT[]      NOT NULL DEFAULT '{}',
  status      trip_status NOT NULL DEFAULT 'draft',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trips_updated_at BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_trips_owner_id ON trips (owner_id);

-- trip_members
CREATE TYPE member_role AS ENUM ('owner', 'editor');

CREATE TABLE trip_members (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id    UUID        NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  role       member_role NOT NULL DEFAULT 'editor',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (trip_id, user_id)
);
CREATE TRIGGER trip_members_updated_at BEFORE UPDATE ON trip_members
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_trip_members_trip_id ON trip_members (trip_id);
CREATE INDEX idx_trip_members_user_id ON trip_members (user_id);

-- itinerary_items
CREATE TYPE itinerary_source AS ENUM ('ai', 'user');

CREATE TABLE itinerary_items (
  id            UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id       UUID             NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  day           INTEGER          NOT NULL CHECK (day >= 1),
  start_time    TIME,
  end_time      TIME,
  title         TEXT             NOT NULL,
  description   TEXT,
  location_name TEXT,
  lat           NUMERIC(9, 6),
  lng           NUMERIC(9, 6),
  source        itinerary_source NOT NULL DEFAULT 'user',
  created_at    TIMESTAMPTZ      NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ      NOT NULL DEFAULT now()
);
CREATE TRIGGER itinerary_items_updated_at BEFORE UPDATE ON itinerary_items
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_itinerary_items_trip_id ON itinerary_items (trip_id);

-- checkins
CREATE TYPE checkin_kind AS ENUM ('planned', 'spontaneous');

CREATE TABLE checkins (
  id                UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id           UUID         NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  author_id         UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  itinerary_item_id UUID         REFERENCES itinerary_items (id) ON DELETE SET NULL,
  captured_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
  lat               NUMERIC(9, 6),
  lng               NUMERIC(9, 6),
  kind              checkin_kind NOT NULL DEFAULT 'spontaneous',
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE TRIGGER checkins_updated_at BEFORE UPDATE ON checkins
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_checkins_trip_id   ON checkins (trip_id);
CREATE INDEX idx_checkins_author_id ON checkins (author_id);

-- checkin_memory (shareable layer)
CREATE TABLE checkin_memory (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  checkin_id   UUID        NOT NULL UNIQUE REFERENCES checkins (id) ON DELETE CASCADE,
  note         TEXT,
  mood         TEXT,
  shared_with  TEXT[]      NOT NULL DEFAULT '{}',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER checkin_memory_updated_at BEFORE UPDATE ON checkin_memory
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- checkin_logistics (PRIVATE — never serialize to public/AI endpoints or published views)
CREATE TABLE checkin_logistics (
  id         UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  checkin_id UUID           NOT NULL UNIQUE REFERENCES checkins (id) ON DELETE CASCADE,
  cost       NUMERIC(12, 2),
  currency   CHAR(3),
  notes      TEXT,
  created_at TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE TRIGGER checkin_logistics_updated_at BEFORE UPDATE ON checkin_logistics
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- checkin_recommendations
CREATE TABLE checkin_recommendations (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  checkin_id UUID        NOT NULL UNIQUE REFERENCES checkins (id) ON DELETE CASCADE,
  title      TEXT        NOT NULL,
  body       TEXT        NOT NULL,
  tags       TEXT[]      NOT NULL DEFAULT '{}',
  rating     INTEGER     CHECK (rating BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER checkin_recommendations_updated_at BEFORE UPDATE ON checkin_recommendations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- media
CREATE TABLE media (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  checkin_id UUID        REFERENCES checkins (id) ON DELETE SET NULL,
  owner_id   UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  r2_key     TEXT        NOT NULL,
  mime       TEXT        NOT NULL,
  width      INTEGER,
  height     INTEGER,
  taken_at   TIMESTAMPTZ,
  lat        NUMERIC(9, 6),
  lng        NUMERIC(9, 6),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER media_updated_at BEFORE UPDATE ON media
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE INDEX idx_media_checkin_id ON media (checkin_id);
CREATE INDEX idx_media_owner_id   ON media (owner_id);
