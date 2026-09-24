import test from 'node:test';
import assert from 'node:assert/strict';
import { getPostSettings, postSettingsSchema, updatePostSettings } from '../src/post_settings.js';

test('post duration accepts whole days without shortening the home window', () => {
  for (const days of [30, 60, 90, 3650]) {
    assert.equal(postSettingsSchema.parse({ retentionDays: days }).retentionDays, days);
  }
  for (const days of [0, 29, 60.5, 3651, '60', null, true]) {
    assert.throws(() => postSettingsSchema.parse({ retentionDays: days }));
  }
});

test('missing settings default to 30 days', async () => {
  assert.deepEqual(await getPostSettings({ query: async () => ({ rows: [] }) }), { retentionDays: 30 });
});

test('failed expiry update rolls back the setting and releases the connection', async () => {
  const queries = [];
  let released = false;
  const client = {
    async query(sql) {
      queries.push(sql);
      if (sql.startsWith('UPDATE posts')) throw new Error('database failure');
      return { rows: [] };
    },
    release() { released = true; },
  };
  await assert.rejects(updatePostSettings({ connect: async () => client }, { retentionDays: 60 }), /database failure/);
  assert.equal(queries.at(-1), 'ROLLBACK');
  assert.ok(!queries.includes('COMMIT'));
  assert.equal(released, true);
});

test('invalid duration never opens a database transaction', async () => {
  await assert.rejects(updatePostSettings({ connect: () => assert.fail('Unexpected connection') }, { retentionDays: 29 }));
});
