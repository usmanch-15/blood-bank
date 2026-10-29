import test from 'node:test';
import assert from 'node:assert/strict';
import worker from '../src/index.js';
import { FirestoreRestClient, FieldValue, FirestoreTimestamp } from '../src/firestore_rest.js';
import { verifyFirebaseIdToken, verifyLocalEmulatorToken } from '../src/firebase_auth.js';
import {
  distanceKm,
  isCompatible,
  isEligible,
  matchingDonors,
  validateRequest,
} from '../src/workflows.js';

const request = (path, init = {}) => new Request(`https://worker.invalid${path}`, init);
const b64 = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
const localToken = (uid = 'test-user', projectId = 'demo-bloodbank', exp = Math.floor(Date.now() / 1000) + 300) => `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
  aud: projectId,
  iss: `https://securetoken.google.com/${projectId}`,
  sub: uid,
  iat: Math.floor(Date.now() / 1000),
  exp,
})}.`;

test('health is public and does not require Firebase credentials', async () => {
  const response = await worker.fetch(request('/health'), { ALLOWED_ORIGINS: '' });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { ok: true });
});

test('call routes require a Firebase bearer token and unknown workflows are rejected', async () => {
  const missing = await worker.fetch(request('/call/getRequest', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ data: { requestId: 'request-1' } }),
  }), { FIREBASE_PROJECT_ID: 'demo-bloodbank' });
  assert.equal(missing.status, 401);

  const invalid = await worker.fetch(request('/call/getRequest', {
    method: 'POST',
    headers: { authorization: 'Bearer invalid', 'content-type': 'application/json' },
    body: JSON.stringify({ data: { requestId: 'request-1' } }),
  }), { FIREBASE_PROJECT_ID: 'demo-bloodbank' });
  assert.equal(invalid.status, 401);

  const unknown = await worker.fetch(request('/call/notAWorkflow', {
    method: 'POST',
    headers: { authorization: `Bearer ${localToken()}`, 'content-type': 'application/json' },
    body: JSON.stringify({ data: {} }),
  }), {
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
    ENVIRONMENT: 'local',
    AUTH_EMULATOR_MODE: 'unsigned',
  });
  assert.equal(unknown.status, 404);
});

test('call routes reject expired and wrong-project emulator tokens', async () => {
  const env = {
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
    ENVIRONMENT: 'local',
    AUTH_EMULATOR_MODE: 'unsigned',
  };
  for (const token of [
    localToken('test-user', 'demo-bloodbank', Math.floor(Date.now() / 1000) - 1),
    localToken('test-user', 'different-demo-project'),
  ]) {
    const response = await worker.fetch(request('/call/createBloodRequest', {
      method: 'POST',
      headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ data: {} }),
    }), env);
    assert.equal(response.status, 401);
  }
});

test('Firestore failures return a structured server error without a success response', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => Response.json({
    error: { code: 13, status: 'INTERNAL', message: 'Synthetic Firestore outage.' },
  }, { status: 503 });
  try {
    const response = await worker.fetch(request('/call/createBloodRequest', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${localToken('receiver')}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({ data: { requestId: 'offline-request' } }),
    }), {
      FIREBASE_PROJECT_ID: 'demo-bloodbank',
      ENVIRONMENT: 'local',
      AUTH_EMULATOR_MODE: 'unsigned',
      FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
    });
    assert.equal(response.status, 500);
    assert.deepEqual(await response.json(), {
      error: {
        code: 'INTERNAL',
        message: 'The server could not complete this request.',
      },
    });
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('unrecognized URLs remain unavailable and CORS only echoes configured origins', async () => {
  const response = await worker.fetch(request('/requests', {
    method: 'POST',
    headers: { Origin: 'https://untrusted.invalid' },
  }), { ALLOWED_ORIGINS: 'https://app.example' });
  assert.equal(response.status, 404);
  assert.equal(response.headers.get('access-control-allow-origin'), null);

  const options = await worker.fetch(request('/call/getRequest', {
    method: 'OPTIONS',
    headers: { Origin: 'https://app.example' },
  }), { ALLOWED_ORIGINS: 'https://app.example' });
  assert.equal(options.status, 204);
  assert.equal(options.headers.get('access-control-allow-origin'), 'https://app.example');
});

test('token verifier rejects invalid claims before contacting Google keys', async () => {
  await assert.rejects(
    verifyFirebaseIdToken('a.b.c', { FIREBASE_PROJECT_ID: 'demo-bloodbank' }, async () => {
      throw new Error('key fetch must not run');
    }),
    (error) => error.status === 401,
  );
});

test('Firestore emulator override is enabled only for demo projects', async () => {
  const production = new FirestoreRestClient({
    FIREBASE_PROJECT_ID: 'blood-bank-production',
    FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
  });
  assert.equal(production.emulator, false);
  assert.match(production.root, /^https:\/\/firestore\.googleapis\.com\//);

  let requestUrl;
  let authorization;
  const emulator = new FirestoreRestClient({
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
    FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
  }, async (url, init) => {
    requestUrl = String(url);
    authorization = init.headers.authorization;
    return Response.json({
      name: 'projects/demo-bloodbank/databases/(default)/documents/users/test-user',
      fields: { status: { stringValue: 'approved' } },
    });
  });
  const snapshot = await emulator.doc('users/test-user').get();
  assert.equal(emulator.emulator, true);
  assert.match(requestUrl, /^http:\/\/127\.0\.0\.1:8080\/v1\/projects\/demo-bloodbank/);
  assert.equal(authorization, 'Bearer owner');
  assert.equal(snapshot.data().status, 'approved');
});

test('verifier accepts a correctly signed Firebase-shaped token', async () => {
  const pair = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify'],
  );
  const encode = (bytes) => Buffer.from(bytes).toString('base64url');
  const header = encode(Buffer.from(JSON.stringify({ alg: 'RS256', kid: 'test-key' })));
  const payload = encode(Buffer.from(JSON.stringify({
    aud: 'demo-bloodbank',
    iss: 'https://securetoken.google.com/demo-bloodbank',
    sub: 'synthetic-user',
    email: 'synthetic@example.test',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 300,
  })));
  const input = `${header}.${payload}`;
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', pair.privateKey, new TextEncoder().encode(input),
  );
  const jwk = await crypto.subtle.exportKey('jwk', pair.publicKey);
  Object.assign(jwk, { kid: 'test-key', alg: 'RS256', use: 'sig' });
  const identity = await verifyFirebaseIdToken(`${input}.${encode(new Uint8Array(signature))}`, {
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
  }, async () => ({
    ok: true,
    headers: { get: () => 'max-age=60' },
    json: async () => ({ keys: [jwk] }),
  }));
  assert.deepEqual(identity, { uid: 'synthetic-user', email: 'synthetic@example.test' });
});

test('local emulator verifier is explicitly gated and validates unsigned tokens', () => {
  const token = localToken('emulator-user');
  const env = {
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
    ENVIRONMENT: 'local',
    AUTH_EMULATOR_MODE: 'unsigned',
  };
  assert.deepEqual(verifyLocalEmulatorToken(token, env), { uid: 'emulator-user', email: null });
  assert.throws(() => verifyLocalEmulatorToken(
    localToken('emulator-user', 'another-demo-project'),
    env,
  ), { status: 401 });
  assert.throws(() => verifyLocalEmulatorToken(
    localToken('emulator-user', 'demo-bloodbank', Math.floor(Date.now() / 1000) - 1),
    env,
  ), { status: 401 });
  assert.throws(() => verifyLocalEmulatorToken(token, {
    ...env,
    ENVIRONMENT: 'production',
  }));
});

test('matching uses 90-day eligibility, blood compatibility, and Haversine distance', async () => {
  assert.ok(Math.abs(distanceKm(0, 0, 0, 1) - 111.195) < 0.1);
  assert.equal(isCompatible('O-', 'AB+'), true);
  assert.equal(isCompatible('AB+', 'O-'), false);
  const now = 1_000_000_000_000;
  assert.equal(isEligible({ lastDonationDate: null }, now), true);
  assert.equal(isEligible({ lastDonationDate: FirestoreTimestamp.fromMillis(now - 90 * 86_400_000) }, now), true);
  assert.equal(isEligible({ lastDonationDate: FirestoreTimestamp.fromMillis(now - 90 * 86_400_000 + 1) }, now), false);

  const donors = [
    { id: 'eligible', data: () => ({ name: 'Eligible Donor', bloodGroup: 'O-', latitude: 30, longitude: 72, isAvailable: true, status: 'approved', isEligible: true }) },
    { id: 'blocked-by-range', data: () => ({ name: 'Far Donor', bloodGroup: 'O-', latitude: 30, longitude: 73, isAvailable: true, status: 'approved' }) },
    { id: 'ineligible', data: () => ({ name: 'Recent Donor', bloodGroup: 'O-', latitude: 30, longitude: 72, isAvailable: true, status: 'approved', lastDonationDate: FirestoreTimestamp.fromMillis(Date.now() - 1) }) },
  ];
  const query = {
    where() { return this; },
    orderBy() { return this; },
    limit() { return this; },
    async get() { return { docs: donors, size: donors.length }; },
  };
  const result = await matchingDonors({ collection: () => query }, 30, 72, 'AB+', 15, 10);
  assert.deepEqual(result.matches.map((donor) => donor.uid), ['eligible']);
});

test('request validation requires hospital name and address and preserves the current request policy', () => {
  const valid = {
    bloodGroup: 'B+',
    quantity: 2,
    requiredBy: Date.now() + 7 * 86_400_000,
    urgency: 'urgent',
    contactNumber: '03001234567',
    hospitalName: 'DHQ Hospital Vehari',
    hospitalAddress: 'Multan Road, Vehari',
    latitude: 30.045,
    longitude: 72.351,
    patientName: 'Ali Khan',
  };
  const requestData = validateRequest(valid, { uid: 'receiver-1', name: 'Receiver' });
  assert.equal(requestData.hospitalName, valid.hospitalName);
  assert.equal(requestData.hospitalAddress, valid.hospitalAddress);
  assert.equal(requestData.location, valid.hospitalAddress);
  assert.equal(requestData.quantity, 2);
  assert.equal(requestData.urgency, 'urgent');
  assert.throws(
    () => validateRequest({ ...valid, hospitalAddress: ' ' }, { uid: 'receiver-1' }),
    { code: 'invalid-argument' },
  );
  assert.throws(
    () => validateRequest({ ...valid, quantity: 51 }, { uid: 'receiver-1' }),
    { code: 'invalid-argument' },
  );
  assert.throws(
    () => validateRequest({ ...valid, longitude: 0 }, { uid: 'receiver-1' }),
    { code: 'invalid-argument' },
  );
});

test('Firestore REST client encodes transactions, array unions, and deletes correctly', async () => {
  const generated = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify'],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', generated.privateKey));
  const privateKey = `-----BEGIN PRIVATE KEY-----\n${Buffer.from(pkcs8).toString('base64')}\n-----END PRIVATE KEY-----`;
  const env = {
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
    FIREBASE_SERVICE_ACCOUNT: JSON.stringify({
      project_id: 'demo-bloodbank',
      client_email: `test-${crypto.randomUUID()}@example.test`,
      private_key: privateKey,
    }),
  };
  let committed;
  let firestoreAuthorization;
  const fakeFetch = async (url, init = {}) => {
    const value = String(url);
    if (value === 'https://oauth2.googleapis.com/token') {
      return Response.json({ access_token: 'synthetic-access-token', expires_in: 3600 });
    }
    if (value.endsWith(':beginTransaction')) return Response.json({ transaction: 'tx-1' });
    if (value.endsWith(':batchGet')) {
      firestoreAuthorization = init.headers.authorization;
      return new Response(`${JSON.stringify({
        found: {
          name: 'projects/demo-bloodbank/databases/(default)/documents/users/user-1',
          fields: { active: { booleanValue: true } },
        },
      })}\n`);
    }
    if (value.endsWith(':commit')) {
      committed = JSON.parse(init.body);
      return Response.json({});
    }
    throw new Error(`Unexpected Firestore URL: ${value}`);
  };
  const db = new FirestoreRestClient(env, fakeFetch);
  await db.runTransaction(async (tx) => {
    const ref = db.doc('users/user-1');
    const snapshot = await tx.get(ref);
    assert.equal(snapshot.data().active, true);
    tx.update(ref, {
      updatedAt: FirestoreTimestamp.fromMillis(1234),
      notifiedDonors: FieldValue.arrayUnion('donor-1'),
      legacyField: FieldValue.delete(),
    });
  });

  const write = committed.writes[0];
  assert.equal(firestoreAuthorization, 'Bearer synthetic-access-token');
  assert.deepEqual(write.updateMask.fieldPaths, ['updatedAt', 'legacyField']);
  assert.deepEqual(write.updateTransforms, [{
    fieldPath: 'notifiedDonors',
    appendMissingElements: { values: [{ stringValue: 'donor-1' }] },
  }]);
  assert.equal(write.update.fields.updatedAt.timestampValue, new Date(1234).toISOString());
  assert.equal('legacyField' in write.update.fields, false);
});

test('Firestore queries target subcollection parents and encode document cursors as references', async () => {
  const generated = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify'],
  );
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey('pkcs8', generated.privateKey));
  const privateKey = `-----BEGIN PRIVATE KEY-----\n${Buffer.from(pkcs8).toString('base64')}\n-----END PRIVATE KEY-----`;
  const env = {
    FIREBASE_PROJECT_ID: 'demo-bloodbank',
    FIREBASE_SERVICE_ACCOUNT: JSON.stringify({
      project_id: 'demo-bloodbank',
      client_email: `query-${crypto.randomUUID()}@example.test`,
      private_key: privateKey,
    }),
  };
  let queryUrl;
  let queryBody;
  const fakeFetch = async (url, init = {}) => {
    const value = String(url);
    if (value === 'https://oauth2.googleapis.com/token') {
      return Response.json({ access_token: 'synthetic-access-token', expires_in: 3600 });
    }
    queryUrl = value;
    queryBody = JSON.parse(init.body);
    return new Response(`${JSON.stringify({
      document: {
        name: 'projects/demo-bloodbank/databases/(default)/documents/users/user-1/devices/device-2',
        fields: { active: { booleanValue: true } },
      },
    })}\n`);
  };
  const db = new FirestoreRestClient(env, fakeFetch);
  const page = await db.collection('users/user-1/devices')
    .where('active', '==', true)
    .orderBy('__name__')
    .limit(10)
    .startAfter('device-1')
    .get();
  assert.match(queryUrl, /documents\/users\/user-1:runQuery$/);
  assert.equal(queryBody.structuredQuery.from[0].collectionId, 'devices');
  assert.deepEqual(queryBody.structuredQuery.startAt.values, [{
    referenceValue: 'projects/demo-bloodbank/databases/(default)/documents/users/user-1/devices/device-1',
  }]);
  assert.equal(page.size, 1);
  assert.equal(page.docs[0].data().active, true);
});
