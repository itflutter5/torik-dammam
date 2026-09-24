import { z } from 'zod';

export const postSettingsSchema = z.object({
  retentionDays: z.number().int().min(30).max(3650),
});

export const postRetentionMigration = `
INSERT INTO app_settings (key, value) VALUES ('post_retention_days', '30')
ON CONFLICT (key) DO NOTHING;
CREATE OR REPLACE FUNCTION set_post_expiration() RETURNS trigger AS $$
BEGIN
  NEW.expires_at := NEW.created_at + COALESCE(
    (SELECT value::integer FROM app_settings WHERE key = 'post_retention_days'), 30
  ) * INTERVAL '1 day';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS posts_set_expiration ON posts;
CREATE TRIGGER posts_set_expiration BEFORE INSERT ON posts
FOR EACH ROW EXECUTE FUNCTION set_post_expiration();
`;

export async function getPostSettings(database) {
  const result = await database.query(
    "SELECT value FROM app_settings WHERE key = 'post_retention_days'",
  );
  return { retentionDays: Number(result.rows[0]?.value ?? 30) };
}

export async function updatePostSettings(pool, body) {
  const settings = postSettingsSchema.parse(body);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // Keep concurrent inserts and duration changes consistent.
    await client.query('LOCK TABLE posts IN SHARE ROW EXCLUSIVE MODE');
    await client.query(
      `INSERT INTO app_settings (key, value, updated_at)
       VALUES ('post_retention_days', $1, NOW())
       ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
      [String(settings.retentionDays)],
    );
    await client.query(
      "UPDATE posts SET expires_at = created_at + $1 * INTERVAL '1 day'",
      [settings.retentionDays],
    );
    await client.query('COMMIT');
    return settings;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
