import { bearerToken, verifyFirebaseIdToken, verifyLocalEmulatorToken } from './firebase_auth.js';

const json = (body, status = 200, headers = {}) => new Response(JSON.stringify(body), {
  status,
  headers: { 'content-type': 'application/json; charset=utf-8', ...headers },
});

function cors(request, env) {
  const origin = request.headers.get('Origin') || '';
  const allowed = String(env.ALLOWED_ORIGINS || '').split(',').map((v) => v.trim()).filter(Boolean);
  const headers = { 'access-control-allow-methods': 'GET,OPTIONS', 'access-control-allow-headers': 'Authorization,Content-Type' };
  if (allowed.includes(origin)) headers['access-control-allow-origin'] = origin;
  return headers;
}

function readiness(env) {
  const projectConfigured = typeof env.FIREBASE_PROJECT_ID === 'string'
    && env.FIREBASE_PROJECT_ID.length > 0;
  const localEmulatorConfigured = env.ENVIRONMENT === 'local'
    && env.AUTH_EMULATOR_MODE === 'unsigned'
    && projectConfigured;
  if (localEmulatorConfigured) {
    return {
      status: 200,
      body: {
        ok: true,
        service: 'blood-connect-api',
        firebase: 'local-emulator-configured',
        connectivity: 'not-checked',
      },
    };
  }
  return {
    status: 503,
    body: {
      ok: false,
      service: 'blood-connect-api',
      firebase: projectConfigured ? 'connectivity-not-verified' : 'not-configured',
      connectivity: 'not-checked',
    },
  };
}

export default {
  async fetch(request, env) {
    const headers = cors(request, env);
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    const url = new URL(request.url);
    if (url.pathname === '/health' && request.method === 'GET') {
      return json({ ok: true, service: 'blood-connect-api' }, 200, headers);
    }
    if (url.pathname === '/readiness' && request.method === 'GET') {
      const result = readiness(env);
      return json(result.body, result.status, headers);
    }
    if (url.pathname === '/v1/me' && request.method === 'GET') {
      try {
        if (!env.FIREBASE_PROJECT_ID) return json({ error: 'firebase-unavailable' }, 503, headers);
        const token = bearerToken(request);
        const identity = env.AUTH_EMULATOR_MODE === 'unsigned'
          ? verifyLocalEmulatorToken(token, env)
          : await verifyFirebaseIdToken(token, env);
        return json({ ok: true, identity }, 200, headers);
      } catch (error) {
        const status = error.status || 503;
        return json({ error: status === 401 ? 'unauthorized' : 'firebase-unavailable' }, status, headers);
      }
    }
    return json({ error: 'not-found' }, 404, headers);
  },
};
