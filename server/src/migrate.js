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
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  suspended_until TIMESTAMPTZ,
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
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_until TIMESTAMPTZ;
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

CREATE TABLE IF NOT EXISTS pending_password_resets (
  id UUID PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  verification_method VARCHAR(10) NOT NULL CHECK (verification_method IN ('phone', 'email')),
  code_hash CHAR(64) NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS pending_password_resets_user_idx
  ON pending_password_resets(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS visitor_days (
  visitor_hash CHAR(64) NOT NULL,
  visited_on DATE NOT NULL DEFAULT CURRENT_DATE,
  visit_count INTEGER NOT NULL DEFAULT 1,
  country_code VARCHAR(2),
  country VARCHAR(100),
  region VARCHAR(100),
  city VARCHAR(100),
  timezone VARCHAR(100),
  source VARCHAR(200),
  first_visited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_visited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (visitor_hash, visited_on)
);
ALTER TABLE visitor_days ADD COLUMN IF NOT EXISTS country_code VARCHAR(2);
ALTER TABLE visitor_days ADD COLUMN IF NOT EXISTS country VARCHAR(100);
ALTER TABLE visitor_days ADD COLUMN IF NOT EXISTS region VARCHAR(100);
ALTER TABLE visitor_days ADD COLUMN IF NOT EXISTS city VARCHAR(100);
ALTER TABLE visitor_days ADD COLUMN IF NOT EXISTS timezone VARCHAR(100);
ALTER TABLE visitor_days ADD COLUMN IF NOT EXISTS source VARCHAR(200);
CREATE INDEX IF NOT EXISTS visitor_days_visited_on_idx ON visitor_days(visited_on DESC);

CREATE TABLE IF NOT EXISTS app_settings (
  key VARCHAR(50) PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
  post_number VARCHAR(30) UNIQUE,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  status VARCHAR(20) NOT NULL DEFAULT 'approved',
  payment_proof_url TEXT,
  payment_currency VARCHAR(3),
  payment_amount NUMERIC(12, 2),
  reviewed_at TIMESTAMPTZ,
  reviewed_by BIGINT REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days'
);

CREATE INDEX IF NOT EXISTS posts_created_at_idx ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS posts_user_id_idx ON posts(user_id);
CREATE INDEX IF NOT EXISTS posts_expires_at_idx ON posts(expires_at);

ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_category_check;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'approved';
ALTER TABLE posts ADD COLUMN IF NOT EXISTS payment_proof_url TEXT;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS payment_currency VARCHAR(3);
ALTER TABLE posts ADD COLUMN IF NOT EXISTS payment_amount NUMERIC(12, 2);
ALTER TABLE posts ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS reviewed_by BIGINT REFERENCES users(id);
UPDATE posts SET status = 'approved' WHERE status IS NULL;
ALTER TABLE posts ALTER COLUMN store_number TYPE VARCHAR(4) USING TRIM(store_number);
ALTER TABLE posts ADD COLUMN IF NOT EXISTS post_number VARCHAR(30);
ALTER TABLE posts ALTER COLUMN post_number TYPE VARCHAR(30);
UPDATE posts
SET post_number = CASE
  WHEN LENGTH(id::text) < 11 THEN '#' || LPAD(id::text, 11, '0')
  ELSE '#' || id::text
END
WHERE post_number IS NULL OR post_number !~ '^#[0-9]{11,}$';
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
  const adminPhone = process.env.ADMIN_PHONE?.trim();
  if (adminPhone) {
    await pool.query('UPDATE users SET is_admin = (phone = $1)', [adminPhone]);
  }
  const defaultSettings = [
    ['payment_number_sar', process.env.PAYMENT_INSTRUCTIONS_SAR ?? ''],
    ['payment_number_bdt', process.env.PAYMENT_INSTRUCTIONS_BDT ?? ''],
    ['payment_bdt_amount', process.env.PAYMENT_BDT_AMOUNT ?? '165'],
  ];
  for (const [key, value] of defaultSettings) {
    await pool.query(
      `INSERT INTO app_settings (key, value) VALUES ($1, $2)
       ON CONFLICT (key) DO NOTHING`,
      [key, value],
    );
  }
  console.log('Database schema is ready.');
} finally {
  await pool.end();
}
