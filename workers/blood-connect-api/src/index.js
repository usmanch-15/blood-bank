import { bearerToken, verifyFirebaseIdToken, verifyLocalEmulatorToken } from './firebase_auth.js';
import { expireOpenRequestsForWorker, callWorkflow } from './workflows.js';

const json = (body, status = 200, headers = {}) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8', ...headers },
});

function cors(request, env) {
  const origin = request.headers.get('Origin') || '';
  const allowed = String(env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);
  const headers = {
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'Authorization,Content-Type',
    'access-control-max-age': '86400',
    vary: 'Origin',
  };
  if (allowed.includes(origin)) headers['access-control-allow-origin'] = origin;
  return headers;
}

function requestError(status, message, code = 'request-failed') {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  error.publicStatus = true;
  return error;
}

async function authenticate(request, env) {
  const token = bearerToken(request);
  if (!token) throw requestError(401, 'A Firebase bearer token is required.', 'unauthenticated');
  if (!env.FIREBASE_PROJECT_ID || env.FIREBASE_PROJECT_ID === 'YOUR_FIREBASE_PROJECT_ID') {
    throw requestError(503, 'Firebase project configuration is missing.');
  }
  try {
    return env.AUTH_EMULATOR_MODE === 'unsigned'
      ? verifyLocalEmulatorToken(token, env)
      : await verifyFirebaseIdToken(token, env);
  } catch (error) {
    if (error.status === 401) throw requestError(401, error.message, 'unauthenticated');
    if (error.message?.includes('signing keys')) {
      throw requestError(503, error.message);
    }
    throw error;
  }
}

async function readJson(request) {
  try {
    const body = await request.json();
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw requestError(400, 'Request body must be a JSON object.', 'invalid-argument');
    }
    return body;
  } catch (error) {
    if (error.status) throw error;
    throw requestError(400, 'Request body must contain valid JSON.', 'invalid-argument');
  }
}

function statusFor(error) {
  if (error.publicStatus && Number.isInteger(error.status)) return error.status;
  if (error.code === 'ABORTED') return 409;
  return 500;
}

export default {
  async fetch(request, env) {
    const headers = cors(request, env);
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    const url = new URL(request.url);
    if (url.pathname === '/health' && request.method === 'GET') {
      return json({ ok: true }, 200, headers);
    }

    try {
      if (request.method !== 'POST' || !/^\/call\/[A-Za-z][A-Za-z0-9]*$/.test(url.pathname)) {
        throw requestError(404, 'Route not found.', 'not-found');
      }
      const identity = await authenticate(request, env);
      const envelope = await readJson(request);
      if (!Object.hasOwn(envelope, 'data') || !envelope.data || typeof envelope.data !== 'object'
          || Array.isArray(envelope.data)) {
        throw requestError(400, 'A callable data object is required.', 'invalid-argument');
      }
      const name = url.pathname.slice('/call/'.length);
      const result = await callWorkflow(name, identity, envelope.data, env);
      return json({ result }, 200, headers);
    } catch (error) {
      const status = statusFor(error);
      if (status >= 500) console.error('Blood Connect Worker request failed:', error.message);
      const code = error.code || (status === 401 ? 'unauthenticated' : 'internal');
      const message = status >= 500 ? 'The server could not complete this request.' : error.message;
      return json({ error: { code, message } }, status, headers);
    }
  },

  async scheduled(_event, env, ctx) {
    ctx.waitUntil(expireOpenRequestsForWorker(env).catch((error) => {
      console.error('Blood Connect request expiry job failed:', error.message);
      throw error;
    }));
  },
};
