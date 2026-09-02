import crypto from 'node:crypto';

const brevoUrl = 'https://api.brevo.com/v3';

class VerificationDeliveryError extends Error {
  constructor(message, { cause, details } = {}) {
    super(message, { cause });
    this.name = 'VerificationDeliveryError';
    this.statusCode = 503;
    this.publicMessage = message;
    this.details = details;
  }
}

export function createCode() {
  return String(crypto.randomInt(100000, 1000000));
}

export function hashCode(code) {
  return crypto.createHmac('sha256', process.env.JWT_SECRET).update(code).digest('hex');
}

async function brevoRequest(path, body) {
  const apiKey = process.env.BREVO_API_KEY?.trim();
  if (!apiKey) {
    throw new VerificationDeliveryError('Verification service is not configured');
  }

  let response;
  try {
    response = await fetch(`${brevoUrl}${path}`, {
      method: 'POST',
      headers: { 'api-key': apiKey, 'content-type': 'application/json', accept: 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(15000),
    });
  } catch (error) {
    throw new VerificationDeliveryError('Could not contact the verification service. Please try again.', { cause: error });
  }

  if (!response.ok) {
    const details = await response.text();
    throw new VerificationDeliveryError('Verification message could not be sent. Please try again.', {
      details: `Brevo ${response.status}: ${details}`,
    });
  }

  return response.json().catch(() => ({}));
}

export async function sendVerification({ method, destination, name, code }) {
  if (method === 'email') {
    const senderEmail = (
      process.env.BREVO_SENDER_EMAIL ??
      process.env.BREVO_FROM_EMAIL ??
      process.env.EMAIL_FROM ??
      ''
    ).trim().toLowerCase();
    if (!senderEmail) {
      throw new VerificationDeliveryError('Email verification is not configured');
    }
    return brevoRequest('/smtp/email', {
      sender: { name: process.env.BREVO_SENDER_NAME?.trim() || 'Torik-Dammam', email: senderEmail },
      to: [{ email: destination.trim().toLowerCase(), name: name.trim() }],
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
