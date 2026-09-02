import crypto from 'node:crypto';

const brevoUrl = 'https://api.brevo.com/v3';

export function createCode() {
  return String(crypto.randomInt(100000, 1000000));
}

export function hashCode(code) {
  return crypto.createHmac('sha256', process.env.JWT_SECRET).update(code).digest('hex');
}

async function brevoRequest(path, body) {
  const apiKey = process.env.BREVO_API_KEY;
  if (!apiKey) throw new Error('BREVO_API_KEY is not configured');
  const response = await fetch(`${brevoUrl}${path}`, {
    method: 'POST',
    headers: { 'api-key': apiKey, 'content-type': 'application/json', accept: 'application/json' },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    const result = await response.text();
    throw new Error(`Brevo delivery failed: ${result}`);
  }
}

export async function sendVerification({ method, destination, name, code }) {
  if (method === 'email') {
    const senderEmail = process.env.BREVO_SENDER_EMAIL;
    if (!senderEmail) throw new Error('BREVO_SENDER_EMAIL is not configured');
    return brevoRequest('/smtp/email', {
      sender: { name: 'Torik-Dammam', email: senderEmail },
      to: [{ email: destination, name }],
      subject: 'Your Torik-Dammam verification code',
      textContent: `Your verification code is ${code}. It expires in 10 minutes.`,
    });
  }
  return brevoRequest('/transactionalSMS/send', {
    sender: process.env.BREVO_SMS_SENDER ?? 'TorikDammam',
    recipient: destination,
    content: `Torik-Dammam verification code: ${code}. Expires in 10 minutes.`,
    type: 'transactional',
  });
}
