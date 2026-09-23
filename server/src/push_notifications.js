import { GoogleAuth } from 'google-auth-library';

export function newPostMessage(post) {
  return {
    topic: 'marketplace_new_posts',
    notification: {
      title: 'New post on Torik Dammam',
      body: `${post.category}: ${post.title}`.slice(0, 240),
    },
    data: { type: 'new_post', postId: String(post.id) },
    android: {
      priority: 'HIGH',
      ttl: '3600s',
      notification: { channel_id: 'new_posts', icon: 'ic_notification', tag: `post-${post.id}` },
    },
  };
}

// A transaction lock prevents multiple server instances from sending the same
// queue entry concurrently. FCM delivery remains at least once after a crash.
export async function sendNextPostPush(pool, messaging) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(`
      SELECT p.id, p.title, p.category FROM post_push_queue q
      JOIN posts p ON p.id = q.post_id
      WHERE q.sent_at IS NULL AND q.next_attempt_at <= NOW()
        AND p.status = 'approved' AND p.expires_at > NOW()
        AND q.created_at > NOW() - INTERVAL '24 hours'
      ORDER BY q.created_at LIMIT 1 FOR UPDATE OF q SKIP LOCKED`);
    if (!rows[0]) {
      await client.query('COMMIT');
      return false;
    }
    try {
      await messaging.send(newPostMessage(rows[0]));
      await client.query('UPDATE post_push_queue SET sent_at = NOW() WHERE post_id = $1', [rows[0].id]);
    } catch (error) {
      await client.query(`UPDATE post_push_queue SET attempts = attempts + 1,
        next_attempt_at = NOW() + LEAST(3600, 30 * POWER(2, LEAST(attempts, 7))) * INTERVAL '1 second'
        WHERE post_id = $1`, [rows[0].id]);
      console.warn('Post push failed; queued for retry:', error.code ?? 'send-failed');
    }
    await client.query('COMMIT');
    return true;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export function startPostPushWorker(pool) {
  const credentials = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!credentials) {
    console.log('Post push disabled: FIREBASE_SERVICE_ACCOUNT_JSON is not configured.');
    return;
  }
  let messaging;
  try {
    const serviceAccount = JSON.parse(credentials);
    if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error('Incomplete service account');
    }
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    messaging = {
      async send(message) {
        const client = await auth.getClient();
        await client.request({
          url: `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(serviceAccount.project_id)}/messages:send`,
          method: 'POST', data: { message }, timeout: 15000, retry: false,
        });
      },
    };
  } catch (_) {
    console.warn('Post push disabled: invalid Firebase service account configuration.');
    return;
  }
  let running = false;
  const tick = async () => {
    if (running) return;
    running = true;
    try {
      for (let count = 0; count < 20; count += 1) {
        if (!await sendNextPostPush(pool, messaging)) break;
      }
    } catch (error) {
      console.warn('Post push queue unavailable:', error.code ?? 'queue-error');
    } finally {
      running = false;
    }
  };
  const timer = setInterval(tick, 10000);
  timer.unref();
  void tick();
}
