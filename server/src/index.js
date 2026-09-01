import 'dotenv/config';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import multer from 'multer';
import path from 'node:path';
import { z } from 'zod';
import { createToken, requireAuth } from './auth.js';
import { pool } from './db.js';
import { uploadImage } from './imagekit.js';

const app = express();
const allowedOrigins = (process.env.ALLOWED_ORIGINS ?? '')
  .split(',').map((value) => value.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins.length ? allowedOrigins : true }));
app.use(express.json({ limit: '1mb' }));

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { files: 3, fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => callback(
    file.mimetype.startsWith('image/') ? null : new Error('Only images are allowed'),
    file.mimetype.startsWith('image/'),
  ),
});

const phone = z.string().regex(/^\+9665\d{8}$/, 'Use +9665XXXXXXXX');
const registerSchema = z.object({
  name: z.string().trim().min(2).max(100),
  phone,
  password: z.string().min(8).max(100),
  storeNumber: z.string().regex(/^\d{4}$/),
});
const loginSchema = z.object({ phone, password: z.string().min(1).max(100) });
const postSchema = z.object({
  category: z.string().trim().min(2).max(30),
  title: z.string().trim().min(3).max(150),
  description: z.string().trim().min(10).max(5000),
  price: z.union([z.literal(''), z.coerce.number().nonnegative().max(9999999999)]).optional(),
  unit: z.string().trim().max(30).optional().default(''),
  storeNumber: z.string().regex(/^\d{4}$/),
});

const publicUser = (row) => ({
  id: String(row.id), name: row.name, phone: row.phone,
  storeNumber: row.store_number, profileImageUrl: row.profile_image_url,
});

app.get('/health', async (_req, res, next) => {
  try { await pool.query('SELECT 1'); res.json({ status: 'ok' }); } catch (error) { next(error); }
});

app.get('/api/categories', async (_req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT id, name FROM categories WHERE active = TRUE ORDER BY sort_order, name',
    );
    res.json({ categories: result.rows });
  } catch (error) { next(error); }
});

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const passwordHash = await bcrypt.hash(input.password, 12);
    const result = await pool.query(
      `INSERT INTO users (name, phone, password_hash, store_number)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, phone, store_number, profile_image_url`,
      [input.name, input.phone, passwordHash, input.storeNumber],
    );
    const user = result.rows[0];
    res.status(201).json({ token: createToken(user), user: publicUser(user) });
  } catch (error) {
    if (error.code === '23505') return res.status(409).json({ error: 'Phone number is already registered' });
    next(error);
  }
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

app.get('/api/posts', async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT p.*, u.name AS user_name, u.phone
       FROM posts p JOIN users u ON u.id = p.user_id
       WHERE p.expires_at > NOW() ORDER BY p.created_at DESC LIMIT 100`,
    );
    res.json({ posts: result.rows });
  } catch (error) { next(error); }
});

app.get('/api/posts/mine', requireAuth, async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT * FROM posts WHERE user_id = $1 ORDER BY created_at DESC', [req.auth.sub],
    );
    res.json({ posts: result.rows });
  } catch (error) { next(error); }
});

app.post('/api/posts', requireAuth, upload.array('images', 3), async (req, res, next) => {
  try {
    const input = postSchema.parse(req.body);
    const imageUrls = await Promise.all((req.files ?? []).map((file) => uploadImage(file, req.auth.sub)));
    const result = await pool.query(
      `INSERT INTO posts
       (user_id, category, title, description, price, unit, store_number, image_urls)
       VALUES ($1, $2, $3, $4, $5, NULLIF($6, ''), $7, $8::jsonb) RETURNING *`,
      [req.auth.sub, input.category, input.title, input.description,
        input.price === '' ? null : input.price, input.unit, input.storeNumber, JSON.stringify(imageUrls)],
    );
    res.status(201).json({ post: result.rows[0] });
  } catch (error) {
    if (error.code === '23503') return res.status(400).json({ error: 'Invalid or inactive category' });
    next(error);
  }
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
  console.error(error);
  if (error instanceof z.ZodError) return res.status(400).json({ error: error.issues[0]?.message ?? 'Invalid data' });
  if (error instanceof multer.MulterError || error.message === 'Only images are allowed') {
    return res.status(400).json({ error: error.message });
  }
  res.status(500).json({ error: 'Server error' });
});

const port = Number(process.env.PORT ?? 10000);
app.listen(port, '0.0.0.0', () => console.log(`ScrapMarket API listening on ${port}`));
