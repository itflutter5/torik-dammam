import test from 'node:test';
import assert from 'node:assert/strict';
import { newPostMessage, sendNextPostPush } from '../src/push_notifications.js';

const post = { id: 42, category: 'Scrap', title: 'Steel for sale' };

function database(rows) {
  const queries = [];
  let released = false;
  const client = {
    async query(sql, args) {
      queries.push({ sql, args });
      return { rows: sql.includes('SELECT p.id') ? rows : [] };
    },
    release() { released = true; },
  };
  return { pool: { connect: async () => client }, queries, released: () => released };
}

test('public topic messages contain only public post information', () => {
  const message = newPostMessage(post);
  assert.equal(message.topic, 'marketplace_new_posts');
  assert.equal(message.data.postId, '42');
  assert.equal(message.notification.body, 'Scrap: Steel for sale');
  assert.equal(message.android.notification.channel_id, 'new_posts');
  assert.equal(message.android.notification.tag, 'post-42');
});

test('successful sends mark the queued post sent and release the database connection', async () => {
  const db = database([post]);
  const sent = [];
  assert.equal(await sendNextPostPush(db.pool, { send: async (message) => sent.push(message) }), true);
  assert.equal(sent.length, 1);
  assert.ok(db.queries.some(({ sql }) => sql.includes('SET sent_at = NOW()')));
  assert.equal(db.queries.at(-1).sql, 'COMMIT');
  assert.equal(db.released(), true);
});

test('failed sends schedule a retry without marking delivery', async () => {
  const db = database([post]);
  await sendNextPostPush(db.pool, { send: async () => { throw { code: 'messaging/server-unavailable' }; } });
  assert.ok(db.queries.some(({ sql }) => sql.includes('attempts = attempts + 1')));
  assert.ok(!db.queries.some(({ sql }) => sql.includes('SET sent_at = NOW()')));
  assert.equal(db.released(), true);
});

test('empty eligible queue sends nothing', async () => {
  const db = database([]);
  assert.equal(await sendNextPostPush(db.pool, { send: async () => assert.fail('Unexpected send') }), false);
  const selection = db.queries.find(({ sql }) => sql.includes('SELECT p.id')).sql;
  assert.ok(selection.includes("p.status = 'approved'"));
  assert.ok(selection.includes('p.expires_at > NOW()'));
  assert.ok(selection.includes('SKIP LOCKED'));
  assert.equal(db.released(), true);
});
