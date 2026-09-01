import 'dotenv/config';
import { pool } from './db.js';

const sql = `
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  store_number CHAR(4) NOT NULL,
  store_number_changed_at TIMESTAMPTZ,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE users ADD COLUMN IF NOT EXISTS store_number_changed_at TIMESTAMPTZ;

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
  ('Driver', 50)
ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

CREATE TABLE IF NOT EXISTS posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(30) NOT NULL REFERENCES categories(name),
  title VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  price NUMERIC(12, 2),
  unit VARCHAR(30),
  store_number CHAR(4) NOT NULL,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days'
);

CREATE INDEX IF NOT EXISTS posts_created_at_idx ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS posts_user_id_idx ON posts(user_id);
CREATE INDEX IF NOT EXISTS posts_expires_at_idx ON posts(expires_at);

ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_category_check;
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
