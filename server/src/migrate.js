import 'dotenv/config';
import { pool } from './db.js';

const sql = `
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) UNIQUE,
  email VARCHAR(254) UNIQUE,
  google_sub VARCHAR(255) UNIQUE,
  password_hash TEXT,
  store_number VARCHAR(4) NOT NULL DEFAULT '0000',
  store_number_changed_at TIMESTAMPTZ,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS store_number_changed_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(254) UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_sub VARCHAR(255) UNIQUE;
ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;
ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
ALTER TABLE users ALTER COLUMN store_number SET DEFAULT '0000';
ALTER TABLE users ALTER COLUMN store_number TYPE VARCHAR(4) USING TRIM(store_number);
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE users SET email = LOWER(TRIM(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower_unique_idx
  ON users (LOWER(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS users_phone_unique_idx
  ON users (phone) WHERE phone IS NOT NULL;

CREATE TABLE IF NOT EXISTS pending_registrations (
  id UUID PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(254),
  password_hash TEXT NOT NULL,
  store_number VARCHAR(4) NOT NULL,
  verification_method VARCHAR(10) NOT NULL CHECK (verification_method IN ('phone', 'email')),
  code_hash CHAR(64) NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

UPDATE pending_registrations SET email = LOWER(TRIM(email)) WHERE email IS NOT NULL;

CREATE TABLE IF NOT EXISTS categories (
  id SERIAL PRIMARY KEY,
  name VARCHAR(30) NOT NULL UNIQUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO categories (name, sort_order) VALUES
  ('Need Job', 10),
  ('Need Worker', 20),
  ('Buy Scrap', 30),
  ('Sell Scrap', 40),
  ('Driver', 50),
  ('Serviceman', 60),
  ('House Items', 70)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

CREATE TABLE IF NOT EXISTS posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(30) NOT NULL REFERENCES categories(name),
  title VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(12, 2),
  unit VARCHAR(30),
  store_number VARCHAR(4) NOT NULL,
  post_number VARCHAR(13) UNIQUE,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days'
);

CREATE INDEX IF NOT EXISTS posts_created_at_idx ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS posts_user_id_idx ON posts(user_id);
CREATE INDEX IF NOT EXISTS posts_expires_at_idx ON posts(expires_at);

ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_category_check;
ALTER TABLE posts ALTER COLUMN store_number TYPE VARCHAR(4) USING TRIM(store_number);
ALTER TABLE posts ADD COLUMN IF NOT EXISTS post_number VARCHAR(13);
UPDATE posts
SET post_number = '#' || LPAD(id::text, 12, '0')
WHERE post_number IS NULL OR post_number !~ '^#[0-9]{12}$';
ALTER TABLE posts ALTER COLUMN post_number SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS posts_post_number_unique_idx ON posts(post_number);
ALTER TABLE pending_registrations ALTER COLUMN store_number TYPE VARCHAR(4) USING TRIM(store_number);

CREATE TABLE IF NOT EXISTS saved_posts (
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);
CREATE INDEX IF NOT EXISTS saved_posts_user_created_idx
  ON saved_posts(user_id, created_at DESC);
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'posts_category_fkey'
  ) THEN
    ALTER TABLE posts ADD CONSTRAINT posts_category_fkey
      FOREIGN KEY (category) REFERENCES categories(name);
  END IF;
END $$;
`;

try {
  await pool.query(sql);
  console.log('Database schema is ready.');
} finally {
  await pool.end();
}
