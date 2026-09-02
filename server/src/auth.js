import jwt from 'jsonwebtoken';
import { pool } from './db.js';

function jwtSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.length < 32) {
    throw new Error('JWT_SECRET must contain at least 32 characters');
  }
  return secret;
}

export function createToken(user) {
  return jwt.sign({ sub: String(user.id), phone: user.phone }, jwtSecret(), {
    expiresIn: '30d',
  });
}

export async function requireAuth(req, res, next) {
  const header = req.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Authentication required' });

  try {
    req.auth = jwt.verify(token, jwtSecret());
    const result = await pool.query(
      'SELECT is_admin, suspended_until FROM users WHERE id = $1',
      [req.auth.sub],
    );
    const user = result.rows[0];
    if (!user) return res.status(401).json({ error: 'Account not found' });
    if (!user.is_admin && user.suspended_until && new Date(user.suspended_until) > new Date()) {
      return res.status(403).json({
        error: `Account restricted until ${new Date(user.suspended_until).toISOString()}`,
      });
    }
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Invalid or expired login' });
    }
    next(error);
  }
}
