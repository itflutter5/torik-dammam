import 'dotenv/config';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import multer from 'multer';
import path from 'node:path';
import { OAuth2Client } from 'google-auth-library';
import { z } from 'zod';
import { createToken, requireAuth } from './auth.js';
import { pool } from './db.js';
import { uploadImage } from './imagekit.js';
import crypto from 'node:crypto';
import { createCode, hashCode, sendVerification } from './verification.js';

const app = express();
const googleClient = new OAuth2Client();
const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? '')
  .split(',').map((value) => value.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins.length ? allowedOrigins : true }));
app.use(express.json({ limit: '1mb' }));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { files: 4, fileSize: 8 * 1024 * 1024 },
});

async function requireAdmin(req, res, next) {
  try {
    const result = await pool.query('SELECT is_admin FROM users WHERE id = $1', [req.auth.sub]);
    if (!result.rows[0]?.is_admin) return res.status(403).json({ error: 'Admin access required' });
    next();
  } catch (error) { next(error); }
}

const phone = z.string().trim().regex(/^\+9665\d{8}$/, 'Use +9665XXXXXXXX');
const registerSchema = z.object({
  name: z.string({ error: 'Name is required' }).trim().min(2, 'Name is required').max(100),
  phone,
  email: z.string({ error: 'Email is required' }).trim().toLowerCase().email('Enter a valid email').max(254),
  password: z.string({ error: 'Password is required' }).min(8, 'Password must be at least 8 characters').max(100),
  storeNumber: z.string({ error: 'Store number is required' }).regex(/^\d{1,4}$/, 'Store number must contain 1 to 4 digits'),
  verificationMethod: z.enum(['phone', 'email'], { error: 'Choose phone or email verification' }),
});
const loginSchema = z.object({ phone, password: z.string().min(1).max(100) });
const postSchema = z.object({
  category: z.string().trim().min(2).max(30),
  title: z.string().trim().min(3).max(150),
  description: z.string().trim().min(10).max(5000),
  price: z.union([z.literal(''), z.coerce.number().nonnegative().max(9999999999)]).optional(),
  unit: z.string().trim().max(30).optional().default(''),
  storeNumber: z.string().regex(/^\d{1,4}$/),
});

const publicUser = (row) => ({
  id: String(row.id), name: row.name, phone: row.phone, email: row.email,
  storeNumber: row.store_number, profileImageUrl: row.profile_image_url,
  storeNumberChangedAt: row.store_number_changed_at,
  isAdmin: row.is_admin === true,
});

app.get('/health', async (_req, res, next) => {
  try { await pool.query('SELECT 1'); res.json({ status: 'ok' }); } catch (error) { next(error); }
});

app.get('/api/config', (_req, res) => {
  res.json({
    googleClientId: process.env.GOOGLE_CLIENT_ID ?? '',
    paymentBdtAmount: Number(process.env.PAYMENT_BDT_AMOUNT ?? 165),
    paymentInstructionsSar: process.env.PAYMENT_INSTRUCTIONS_SAR ?? '',
    paymentInstructionsBdt: process.env.PAYMENT_INSTRUCTIONS_BDT ?? '',
  });
});

app.get('/api/categories', async (_req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT id, name FROM categories WHERE active = TRUE ORDER BY sort_order, name',
    );
    res.json({ categories: result.rows });
  } catch (error) { next(error); }
});

app.post('/api/auth/register/start', async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const duplicate = await pool.query(
      'SELECT 1 FROM users WHERE phone = $1 OR LOWER(email) = $2', [input.phone, input.email],
    );
    if (duplicate.rows[0]) return res.status(409).json({ error: 'Phone or email is already registered' });
    const passwordHash = await bcrypt.hash(input.password, 12);
    const code = createCode();
    const verificationId = crypto.randomUUID();
    await pool.query(
      `INSERT INTO pending_registrations
       (id, name, phone, email, password_hash, store_number,
        verification_method, code_hash, expires_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NOW() + INTERVAL '10 minutes')`,
      [verificationId, input.name, input.phone, input.email, passwordHash,
        input.storeNumber, input.verificationMethod, hashCode(code)],
    );
    const destination = input.verificationMethod === 'email' ? input.email : input.phone;
    try {
      await sendVerification({ method: input.verificationMethod, destination, name: input.name, code });
    } catch (deliveryError) {
      await pool.query('DELETE FROM pending_registrations WHERE id = $1', [verificationId])
        .catch((cleanupError) => console.error('Pending registration cleanup failed', cleanupError));
      throw deliveryError;
    }
    res.status(202).json({ verificationId, destination: input.verificationMethod === 'email' ? input.email : input.phone.replace(/.(?=.{4})/g, '•') });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/register/verify', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const input = z.object({
      verificationId: z.string().uuid(), code: z.string().regex(/^\d{6}$/),
    }).parse(req.body);
    await client.query('BEGIN');
    const pendingResult = await client.query(
      `SELECT * FROM pending_registrations
       WHERE id = $1 AND expires_at > NOW() AND attempts < 5 FOR UPDATE`,
      [input.verificationId],
    );
    const pending = pendingResult.rows[0];
    if (!pending || hashCode(input.code) !== pending.code_hash) {
      if (pending) await client.query(
        'UPDATE pending_registrations SET attempts = attempts + 1 WHERE id = $1',
        [input.verificationId],
      );
      await client.query('COMMIT');
      return res.status(400).json({ error: 'Invalid or expired verification code' });
    }
    const result = await client.query(
      `INSERT INTO users
       (name, phone, email, password_hash, store_number, phone_verified, email_verified)
       VALUES ($1,$2,$3,$4,$5,$6,$7)
       RETURNING id, name, phone, email, store_number,
                 store_number_changed_at, profile_image_url, is_admin`,
      [pending.name, pending.phone, pending.email, pending.password_hash,
        pending.store_number, pending.verification_method === 'phone',
        pending.verification_method === 'email'],
    );
    await client.query('DELETE FROM pending_registrations WHERE id = $1', [input.verificationId]);
    await client.query('COMMIT');
    const user = result.rows[0];
    res.status(201).json({ token: createToken(user), user: publicUser(user) });
  } catch (error) {
    await client.query('ROLLBACK');
    if (error.code === '23505') return res.status(409).json({ error: 'Phone or email is already registered' });
    next(error);
  } finally { client.release(); }
});

app.post('/api/auth/password-reset/start', async (req, res, next) => {
  try {
    const { identifier } = z.object({
      identifier: z.string().trim().min(3).max(254),
    }).parse(req.body);
    const normalized = identifier.toLowerCase();
    const byEmail = normalized.includes('@');
    const result = await pool.query(
      `SELECT id, name, phone, email, phone_verified, email_verified,
              password_changed_at
       FROM users
       WHERE ${byEmail ? 'LOWER(email) = $1' : 'phone = $1'}
         AND password_hash IS NOT NULL`,
      [byEmail ? normalized : identifier],
    );
    const user = result.rows[0];
    if (!user) return res.status(404).json({ error: 'Account not found' });
    const method = byEmail ? 'email' : 'phone';
    if ((byEmail && !user.email_verified) || (!byEmail && !user.phone_verified)) {
      return res.status(400).json({ error: `This ${method} has not been verified` });
    }
    if (user.password_changed_at &&
        new Date(user.password_changed_at).getTime() > Date.now() - 3 * 60 * 60 * 1000) {
      return res.status(429).json({ error: 'Password can only be changed once every 3 hours' });
    }

    const code = createCode();
    const verificationId = crypto.randomUUID();
    await pool.query('DELETE FROM pending_password_resets WHERE user_id = $1', [user.id]);
    await pool.query(
      `INSERT INTO pending_password_resets
       (id, user_id, verification_method, code_hash, expires_at)
       VALUES ($1, $2, $3, $4, NOW() + INTERVAL '10 minutes')`,
      [verificationId, user.id, method, hashCode(code)],
    );
    const destination = byEmail ? user.email : user.phone;
    try {
      await sendVerification({ method, destination, name: user.name, code });
    } catch (deliveryError) {
      await pool.query('DELETE FROM pending_password_resets WHERE id = $1', [verificationId])
        .catch((cleanupError) => console.error('Password reset cleanup failed', cleanupError));
      throw deliveryError;
    }
    res.status(202).json({
      verificationId,
      destination: byEmail ? user.email : user.phone.replace(/.(?=.{4})/g, '•'),
    });
  } catch (error) { next(error); }
});

app.post('/api/auth/password-reset/verify', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const input = z.object({
      verificationId: z.string().uuid(),
      code: z.string().regex(/^\d{6}$/),
      newPassword: z.string().min(8, 'Password must be at least 8 characters').max(100),
    }).parse(req.body);
    await client.query('BEGIN');
    const pendingResult = await client.query(
      `SELECT r.*, u.password_changed_at
       FROM pending_password_resets r JOIN users u ON u.id = r.user_id
       WHERE r.id = $1 AND r.expires_at > NOW() AND r.attempts < 5 FOR UPDATE OF r, u`,
      [input.verificationId],
    );
    const pending = pendingResult.rows[0];
    if (!pending || hashCode(input.code) !== pending.code_hash) {
      if (pending) await client.query(
        'UPDATE pending_password_resets SET attempts = attempts + 1 WHERE id = $1',
        [input.verificationId],
      );
      await client.query('COMMIT');
      return res.status(400).json({ error: 'Invalid or expired verification code' });
    }
    if (pending.password_changed_at &&
        new Date(pending.password_changed_at).getTime() > Date.now() - 3 * 60 * 60 * 1000) {
      await client.query('ROLLBACK');
      return res.status(429).json({ error: 'Password can only be changed once every 3 hours' });
    }
    const passwordHash = await bcrypt.hash(input.newPassword, 12);
    await client.query(
      `UPDATE users SET password_hash = $1, password_changed_at = NOW(), updated_at = NOW()
       WHERE id = $2`,
      [passwordHash, pending.user_id],
    );
    await client.query('DELETE FROM pending_password_resets WHERE user_id = $1', [pending.user_id]);
    await client.query('COMMIT');
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally { client.release(); }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);
    const result = await pool.query('SELECT * FROM users WHERE phone = $1', [input.phone]);
    const user = result.rows[0];
    if (!user || !await bcrypt.compare(input.password, user.password_hash)) {
      return res.status(401).json({ error: 'Incorrect phone number or password' });
    }
    res.json({ token: createToken(user), user: publicUser(user) });
  } catch (error) { next(error); }
});

app.post('/api/auth/admin-login', async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);
    const result = await pool.query(
      'SELECT * FROM users WHERE phone = $1 AND is_admin = TRUE',
      [input.phone],
    );
    const user = result.rows[0];
    if (!user || !await bcrypt.compare(input.password, user.password_hash)) {
      return res.status(401).json({ error: 'Incorrect admin phone number or password' });
    }
    res.json({ token: createToken(user), user: publicUser(user) });
  } catch (error) { next(error); }
});

app.post('/api/auth/google', async (req, res, next) => {
  try {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    if (!clientId) return res.status(503).json({ error: 'Google login is not configured' });
    const { idToken } = z.object({ idToken: z.string().min(100) }).parse(req.body);
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: clientId,
    });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email || payload.email_verified !== true) {
      return res.status(401).json({ error: 'Google account could not be verified' });
    }
    const googleEmail = payload.email.trim().toLowerCase();
    const result = await pool.query(
      `INSERT INTO users
       (name, email, google_sub, profile_image_url, store_number)
       VALUES ($1, $2, $3, $4, '0000')
       ON CONFLICT (google_sub) DO UPDATE SET
         name = EXCLUDED.name,
         email = EXCLUDED.email,
         profile_image_url = EXCLUDED.profile_image_url,
         updated_at = NOW()
       RETURNING id, name, phone, email, store_number,
                 store_number_changed_at, profile_image_url, is_admin`,
      [payload.name ?? googleEmail.split('@')[0], googleEmail,
        payload.sub, payload.picture ?? null],
    );
    const user = result.rows[0];
    res.json({ token: createToken(user), user: publicUser(user) });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({ error: 'This email is linked to another account' });
    }
    next(error);
  }
});

app.get('/api/auth/me', requireAuth, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, name, phone, email, store_number, store_number_changed_at,
              profile_image_url, is_admin
       FROM users WHERE id = $1`,
      [req.auth.sub],
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'User not found' });
    res.json({ user: publicUser(result.rows[0]) });
  } catch (error) { next(error); }
});

app.patch('/api/users/me', requireAuth, async (req, res, next) => {
  try {
    const input = z.object({
      storeNumber: z.string().regex(/^\d{1,4}$/),
    }).parse(req.body);
    const result = await pool.query(
      `UPDATE users
       SET store_number = $1,
           store_number_changed_at = CASE
             WHEN store_number = $1 THEN store_number_changed_at ELSE NOW()
           END,
           updated_at = NOW()
       WHERE id = $2 AND (
         store_number = $1 OR store_number_changed_at IS NULL OR
         store_number_changed_at <= NOW() - INTERVAL '30 days'
       )
       RETURNING id, name, phone, store_number, store_number_changed_at,
                 profile_image_url, is_admin`,
      [input.storeNumber, req.auth.sub],
    );
    if (!result.rows[0]) {
      return res.status(409).json({ error: 'Store number can only be changed every 30 days' });
    }
    res.json({ user: publicUser(result.rows[0]) });
  } catch (error) { next(error); }
});

app.patch('/api/users/me/image', requireAuth, upload.single('image'), async (req, res, next) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'Choose an image' });
    const imageUrl = await uploadImage(req.file, req.auth.sub, 'profiles');
    const result = await pool.query(
      `UPDATE users SET profile_image_url = $1, updated_at = NOW()
       WHERE id = $2
       RETURNING id, name, phone, email, store_number,
                 store_number_changed_at, profile_image_url, is_admin`,
      [imageUrl, req.auth.sub],
    );
    res.json({ user: publicUser(result.rows[0]) });
  } catch (error) { next(error); }
});

app.get('/api/posts', async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT p.*, u.name AS user_name, u.phone,
              u.profile_image_url AS user_profile_image_url
       FROM posts p JOIN users u ON u.id = p.user_id
       WHERE p.expires_at > NOW() AND p.status = 'approved'
       ORDER BY p.created_at DESC LIMIT 100`,
    );
    res.json({ posts: result.rows });
  } catch (error) { next(error); }
});

app.get('/api/posts/mine', requireAuth, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT p.*, u.name AS user_name, u.phone,
              u.profile_image_url AS user_profile_image_url
       FROM posts p JOIN users u ON u.id = p.user_id
       WHERE p.user_id = $1 ORDER BY p.created_at DESC`,
      [req.auth.sub],
    );
    res.json({ posts: result.rows });
  } catch (error) { next(error); }
});

app.get('/api/posts/saved', requireAuth, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT p.*, u.name AS user_name, u.phone,
              u.profile_image_url AS user_profile_image_url,
              TRUE AS is_saved
       FROM saved_posts s
       JOIN posts p ON p.id = s.post_id
       JOIN users u ON u.id = p.user_id
       WHERE s.user_id = $1
       ORDER BY s.created_at DESC`,
      [req.auth.sub],
    );
    res.json({ posts: result.rows });
  } catch (error) { next(error); }
});

app.post('/api/posts/:postId/save', requireAuth, async (req, res, next) => {
  try {
    const postId = z.coerce.number().int().positive().parse(req.params.postId);
    const result = await pool.query(
      `INSERT INTO saved_posts (user_id, post_id) VALUES ($1, $2)
       ON CONFLICT (user_id, post_id) DO NOTHING RETURNING post_id`,
      [req.auth.sub, postId],
    );
    if (!result.rows[0]) {
      const exists = await pool.query('SELECT 1 FROM posts WHERE id = $1', [postId]);
      if (!exists.rows[0]) return res.status(404).json({ error: 'Post not found' });
    }
    res.json({ saved: true });
  } catch (error) {
    if (error.code === '23503') return res.status(404).json({ error: 'Post not found' });
    next(error);
  }
});

app.delete('/api/posts/:postId/save', requireAuth, async (req, res, next) => {
  try {
    const postId = z.coerce.number().int().positive().parse(req.params.postId);
    await pool.query(
      'DELETE FROM saved_posts WHERE user_id = $1 AND post_id = $2',
      [req.auth.sub, postId],
    );
    res.json({ saved: false });
  } catch (error) { next(error); }
});

app.get('/api/posts/quota', requireAuth, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT COUNT(*)::int AS used FROM posts
       WHERE user_id = $1 AND status <> 'rejected'`, [req.auth.sub],
    );
    const used = result.rows[0].used;
    res.json({
      freeRemaining: Math.max(0, 5 - used),
      sarAmount: 5,
      bdtAmount: Number(process.env.PAYMENT_BDT_AMOUNT ?? 165),
      instructionsSar: process.env.PAYMENT_INSTRUCTIONS_SAR ?? '',
      instructionsBdt: process.env.PAYMENT_INSTRUCTIONS_BDT ?? '',
    });
  } catch (error) { next(error); }
});

app.post('/api/posts', requireAuth, upload.fields([
  { name: 'images', maxCount: 3 },
  { name: 'paymentProof', maxCount: 1 },
]), async (req, res, next) => {
  try {
    const input = postSchema.parse(req.body);
    const employmentPost = input.category === 'Need Worker' || input.category === 'Need Job';
    const files = req.files ?? {};
    const imageUrls = await Promise.all((files.images ?? []).map((file) => uploadImage(file, req.auth.sub)));
    const countResult = await pool.query(
      `SELECT COUNT(*)::int AS used FROM posts WHERE user_id = $1 AND status <> 'rejected'`,
      [req.auth.sub],
    );
    const requiresPayment = countResult.rows[0].used >= 5;
    const paymentCurrency = requiresPayment
      ? z.enum(['SAR', 'BDT']).parse(req.body.paymentCurrency)
      : null;
    const proofFile = files.paymentProof?.[0];
    if (requiresPayment && !proofFile) {
      return res.status(402).json({ error: 'Payment proof is required after 5 free posts' });
    }
    const paymentProofUrl = proofFile
      ? await uploadImage(proofFile, req.auth.sub, 'payment-proofs')
      : null;
    const status = requiresPayment ? 'pending' : 'approved';
    const paymentAmount = requiresPayment
      ? (paymentCurrency === 'SAR' ? 5 : Number(process.env.PAYMENT_BDT_AMOUNT ?? 165))
      : null;
    const result = await pool.query(
      `WITH next_post AS (
         SELECT nextval(pg_get_serial_sequence('posts', 'id')) AS id
       )
       INSERT INTO posts
       (id, user_id, category, title, description, price, unit, store_number, image_urls,
        post_number, status, payment_proof_url, payment_currency, payment_amount)
       SELECT id, $1, $2, $3, $4, $5, NULLIF($6, ''), $7, $8::jsonb,
              CASE
                WHEN LENGTH(id::text) < 11 THEN '#' || LPAD(id::text, 11, '0')
                ELSE '#' || id::text
              END,
              $9, $10, $11, $12
       FROM next_post
       RETURNING *`,
      [req.auth.sub, input.category, input.title, input.description,
        input.price === '' ? null : input.price, employmentPost ? '' : input.unit, input.storeNumber,
        JSON.stringify(imageUrls), status, paymentProofUrl, paymentCurrency, paymentAmount],
    );
    res.status(201).json({ post: result.rows[0], pendingApproval: requiresPayment });
  } catch (error) {
    if (error.code === '23503') return res.status(400).json({ error: 'Invalid or inactive category' });
    next(error);
  }
});

app.get('/api/admin/posts', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const status = z.enum(['pending', 'approved', 'rejected']).optional().parse(req.query.status);
    const result = await pool.query(
      `SELECT p.*, u.name AS user_name, u.phone
       FROM posts p JOIN users u ON u.id = p.user_id
       WHERE ($1::text IS NULL OR p.status = $1)
       ORDER BY p.created_at DESC LIMIT 500`,
      [status ?? null],
    );
    res.json({ posts: result.rows });
  } catch (error) { next(error); }
});

app.patch('/api/admin/posts/:postId/review', requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const postId = z.coerce.number().int().positive().parse(req.params.postId);
    const { approved } = z.object({ approved: z.boolean() }).parse(req.body);
    const result = await pool.query(
      `UPDATE posts SET status = $1, reviewed_at = NOW(), reviewed_by = $2
       WHERE id = $3 RETURNING id, status`,
      [approved ? 'approved' : 'rejected', req.auth.sub, postId],
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'Post not found' });
    res.json({ post: result.rows[0] });
  } catch (error) { next(error); }
});

const staticDirectory = process.env.STATIC_DIR ?? path.resolve('public');
app.use('/api', (_req, res) => res.status(404).json({ error: 'Not found' }));
app.get('/refresh', (_req, res) => {
  res.setHeader('Clear-Site-Data', '"cache", "storage"');
  res.setHeader('Cache-Control', 'no-store');
  res.redirect(302, '/?refreshed=1');
});
app.use(express.static(staticDirectory, {
  setHeaders: (res, filePath) => {
    if (filePath.endsWith('index.html') ||
        filePath.endsWith('flutter_bootstrap.js') ||
        filePath.endsWith('flutter_service_worker.js')) {
      res.setHeader('Cache-Control', 'no-store');
    } else {
      res.setHeader('Cache-Control', 'public, max-age=0, must-revalidate');
    }
  },
}));
app.use((req, res, next) => {
  if (req.method !== 'GET') return next();
  res.sendFile(path.join(staticDirectory, 'index.html'));
});

app.use((error, _req, res, _next) => {
  console.error(error.details ?? error);
  if (error instanceof z.ZodError) return res.status(400).json({ error: error.issues[0]?.message ?? 'Invalid data' });
  if (error instanceof multer.MulterError || error.message === 'Only valid images are allowed') {
    return res.status(400).json({ error: error.message });
  }
  if (error.publicMessage && error.statusCode) {
    return res.status(error.statusCode).json({ error: error.publicMessage });
  }
  res.status(500).json({ error: 'Server error' });
});

const port = Number(process.env.PORT ?? 10000);
app.listen(port, '0.0.0.0', () => console.log(`ScrapMarket API listening on ${port}`));
