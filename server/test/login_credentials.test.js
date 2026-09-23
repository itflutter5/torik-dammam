import test from 'node:test';
import assert from 'node:assert/strict';
import { passwordLoginSchema } from '../src/login_credentials.js';

test('email login trims and normalizes email without changing the password', () => {
  assert.deepEqual(passwordLoginSchema.parse({
    email: ' Person@Example.com ', password: ' secret ',
  }), { email: 'person@example.com', password: ' secret ' });
});

test('existing Saudi phone login remains supported', () => {
  assert.deepEqual(passwordLoginSchema.parse({
    phone: '+966512345678', password: 'secret',
  }), { phone: '+966512345678', password: 'secret' });
});

test('invalid, missing, and ambiguous credentials are rejected', () => {
  for (const input of [
    { email: 'invalid', password: 'secret' },
    { phone: '123', password: 'secret' },
    { email: 'person@example.com', password: '' },
    { password: 'secret' },
    { email: 'person@example.com', phone: '+966512345678', password: 'secret' },
  ]) {
    assert.equal(passwordLoginSchema.safeParse(input).success, false);
  }
});
