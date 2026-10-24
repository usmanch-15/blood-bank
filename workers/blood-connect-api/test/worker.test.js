import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { verifyFirebaseIdToken, verifyLocalEmulatorToken } from '../src/firebase_auth.js';

const request = (path, init = {}) => new Request(`https://worker.invalid${path}`, init);

test('health is public and does not require Firebase credentials', async () => {
  const response = await worker.fetch(request('/health'), { ALLOWED_ORIGINS: '' });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { ok: true, service: 'blood-connect-api' });
});

test('readiness stays blocked until a secure Firebase integration is configured', async () => {
  const response = await worker.fetch(request('/readiness'), { ALLOWED_ORIGINS: '' });
  assert.equal(response.status, 503);
  const body = await response.json();
  assert.equal(body.firebase, 'not-configured');
  assert.equal(body.connectivity, 'not-checked');
});

test('readiness reports local emulator configuration without claiming connectivity', async () => {
  const response = await worker.fetch(request('/readiness'), {
    FIREBASE_PROJECT_ID: 'demo-bloodbank', ENVIRONMENT: 'local', AUTH_EMULATOR_MODE: 'unsigned',
  });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    ok: true,
    service: 'blood-connect-api',
    firebase: 'local-emulator-configured',
    connectivity: 'not-checked',
  });
});

test('production readiness stays blocked without a real connectivity check', async () => {
  const response = await worker.fetch(request('/readiness'), {
    FIREBASE_PROJECT_ID: 'blood-bank-98037', ENVIRONMENT: 'production',
  });
  assert.equal(response.status, 503);
  assert.equal((await response.json()).firebase, 'connectivity-not-verified');
});

test('unknown routes and disallowed origins are rejected', async () => {
  const response = await worker.fetch(request('/private', {
    headers: { Origin: 'https://untrusted.invalid' },
  }), { ALLOWED_ORIGINS: 'https://app.example' });
  assert.equal(response.status, 404);
  assert.equal(response.headers.get('access-control-allow-origin'), null);
});

test('authenticated identity endpoint rejects missing and malformed tokens', async () => {
  const missing = await worker.fetch(request('/v1/me'), {});
  assert.equal(missing.status, 503);
  const malformed = await worker.fetch(request('/v1/me', {
    headers: { Authorization: 'Bearer not-a-jwt' },
  }), { FIREBASE_PROJECT_ID: 'demo-bloodbank' });
  assert.equal(malformed.status, 401);
});

test('token verifier rejects invalid claims before contacting Google keys', async () => {
  await assert.rejects(
    verifyFirebaseIdToken('a.b.c', { FIREBASE_PROJECT_ID: 'demo-bloodbank' }, async () => {
      throw new Error('key fetch must not run');
    }),
    (error) => error.status === 401,
  );
});

test('authenticated route stays unavailable without Firebase configuration', async () => {
  const response = await worker.fetch(request('/v1/me', {
    headers: { Authorization: 'Bearer eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJ1In0.sig' },
  }), {});
  assert.equal(response.status, 503);
});

test('verifier accepts a correctly signed Firebase-shaped token', async () => {
  const pair = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify'],
  );
  const b64 = (bytes) => Buffer.from(bytes).toString('base64url');
  const header = b64(Buffer.from(JSON.stringify({ alg: 'RS256', kid: 'test-key' })));
  const payload = b64(Buffer.from(JSON.stringify({
    aud: 'demo-bloodbank', iss: 'https://securetoken.google.com/demo-bloodbank',
    sub: 'synthetic-user', email: 'synthetic@example.test', iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 300,
  })));
  const signingInput = `${header}.${payload}`;
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', pair.privateKey, new TextEncoder().encode(signingInput),
  );
  const spki = await crypto.subtle.exportKey('spki', pair.publicKey);
  const pem = `-----BEGIN CERTIFICATE-----${Buffer.from(spki).toString('base64')}-----END CERTIFICATE-----`;
  const identity = await verifyFirebaseIdToken(`${signingInput}.${b64(new Uint8Array(signature))}`, { FIREBASE_PROJECT_ID: 'demo-bloodbank' }, async () => ({
    ok: true, json: async () => ({ 'test-key': pem }),
  }));
  assert.deepEqual(identity, { uid: 'synthetic-user', email: 'synthetic@example.test' });
});

test('local emulator verifier accepts only explicitly gated unsigned tokens', () => {
  const b64 = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const token = `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    aud: 'demo-bloodbank', iss: 'https://securetoken.google.com/demo-bloodbank',
    sub: 'emulator-user', iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 300,
  })}.`;
  assert.deepEqual(verifyLocalEmulatorToken(token, {
    FIREBASE_PROJECT_ID: 'demo-bloodbank', ENVIRONMENT: 'local', AUTH_EMULATOR_MODE: 'unsigned',
  }), { uid: 'emulator-user', email: null });
  assert.throws(() => verifyLocalEmulatorToken(token, {
    FIREBASE_PROJECT_ID: 'demo-bloodbank', ENVIRONMENT: 'production', AUTH_EMULATOR_MODE: 'unsigned',
  }));
});

test('local emulator verifier rejects expired and signed emulator-shaped tokens', () => {
  const b64 = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const base = `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
    aud: 'demo-bloodbank', iss: 'https://securetoken.google.com/demo-bloodbank',
    sub: 'emulator-user', iat: Math.floor(Date.now() / 1000) - 600, exp: Math.floor(Date.now() / 1000) - 300,
  })}`;
  const env = { FIREBASE_PROJECT_ID: 'demo-bloodbank', ENVIRONMENT: 'local', AUTH_EMULATOR_MODE: 'unsigned' };
  assert.throws(() => verifyLocalEmulatorToken(`${base}.`, env));
  assert.throws(() => verifyLocalEmulatorToken(`${base}.not-empty`, env));
});
