import { importJWK, jwtVerify } from 'jose';

const JWKS_URL = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';
let cachedJwks;
let jwksExpiresAt = 0;

const decode = (value) => {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  const binary = atob(normalized);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
};

const decodeJson = (value) => JSON.parse(new TextDecoder().decode(decode(value)));

function unauthorized(message) {
  const error = new Error(message);
  error.status = 401;
  return error;
}

export async function verifyFirebaseIdToken(token, env, fetchImpl = fetch) {
  if (!token || typeof token !== 'string') throw unauthorized('Missing bearer token.');
  const parts = token.split('.');
  if (parts.length !== 3) throw unauthorized('Malformed bearer token.');
  const [encodedHeader, encodedPayload, encodedSignature] = parts;
  let header;
  let payload;
  try {
    header = decodeJson(encodedHeader);
    payload = decodeJson(encodedPayload);
  } catch {
    throw unauthorized('Malformed bearer token.');
  }
  const projectId = String(env.FIREBASE_PROJECT_ID || '');
  if (!projectId) throw new Error('Firebase project configuration is missing.');
  const now = Math.floor(Date.now() / 1000);
  if (header.alg !== 'RS256' || !header.kid || payload.aud !== projectId
      || payload.iss !== `https://securetoken.google.com/${projectId}`
      || typeof payload.sub !== 'string' || payload.sub.length === 0
      || !Number.isFinite(payload.exp) || payload.exp <= now
      || !Number.isFinite(payload.iat) || payload.iat > now + 60) {
    throw unauthorized('Invalid Firebase ID token claims.');
  }
  if (!cachedJwks || Date.now() >= jwksExpiresAt) {
    const response = await fetchImpl(JWKS_URL);
    if (!response.ok) throw new Error('Firebase signing keys are unavailable.');
    cachedJwks = await response.json();
    const maxAge = Number(response.headers?.get('cache-control')?.match(/max-age=(\d+)/)?.[1] || 300);
    jwksExpiresAt = Date.now() + maxAge * 1000;
  }
  const keys = cachedJwks;
  const jwk = keys.keys?.find((key) => key.kid === header.kid && key.alg === 'RS256' && key.use === 'sig');
  if (!jwk) throw unauthorized('Unknown Firebase signing key.');
  const key = await importJWK(jwk, 'RS256');
  try {
    const verified = await jwtVerify(token, key, {
      algorithms: ['RS256'],
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
      clockTolerance: 60,
    });
    return {
      uid: verified.payload.sub,
      email: typeof verified.payload.email === 'string' ? verified.payload.email : null,
    };
  } catch {
    throw unauthorized('Invalid Firebase ID token signature or claims.');
  }
}

export function bearerToken(request) {
  const value = request.headers.get('Authorization') || '';
  const match = value.match(/^Bearer\s+(.+)$/i);
  return match?.[1] || null;
}

// Firebase documents emulator ID tokens as unsigned. This path is intentionally
// separate from production verification and is only usable with explicit local
// configuration. It must never be configured in a deployed Worker.
export function verifyLocalEmulatorToken(token, env) {
  if (env.ENVIRONMENT !== 'local' || env.AUTH_EMULATOR_MODE !== 'unsigned') {
    throw new Error('Local emulator token mode is disabled.');
  }
  if (!token || typeof token !== 'string') throw unauthorized('Missing bearer token.');
  const parts = token.split('.');
  if (parts.length !== 3) throw unauthorized('Malformed bearer token.');
  let header;
  let payload;
  try {
    header = decodeJson(parts[0]);
    payload = decodeJson(parts[1]);
  } catch {
    throw unauthorized('Malformed bearer token.');
  }
  const projectId = String(env.FIREBASE_PROJECT_ID || '');
  const now = Math.floor(Date.now() / 1000);
  if (header.alg !== 'none' || payload.aud !== projectId
      || payload.iss !== `https://securetoken.google.com/${projectId}`
      || typeof payload.sub !== 'string' || payload.sub.length === 0
      || !Number.isFinite(payload.exp) || payload.exp <= now
      || !Number.isFinite(payload.iat) || payload.iat > now + 60) {
    throw unauthorized('Invalid emulator ID token claims.');
  }
  if (parts[2] !== '') throw unauthorized('Unsigned emulator token has a signature.');
  return { uid: payload.sub, email: typeof payload.email === 'string' ? payload.email : null };
}
