import jwt from 'jsonwebtoken';

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

export function requireAuth(req, res, next) {
  const header = req.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Authentication required' });

  try {
    req.auth = jwt.verify(token, jwtSecret());
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired login' });
  }
}
