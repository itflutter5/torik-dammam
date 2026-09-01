import 'dotenv/config';
import { pool } from './db.js';

const sql = `
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  store_number CHAR(4) NOT NULL,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(30) NOT NULL CHECK (
    category IN ('Need Job', 'Need Worker', 'Buy Scrap', 'Sell Scrap', 'Driver')
  ),
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
`;

try {
  await pool.query(sql);
  console.log('Database schema is ready.');
} finally {
  await pool.end();
}
