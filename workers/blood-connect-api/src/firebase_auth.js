const JWKS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

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
  const response = await fetchImpl(JWKS_URL);
  if (!response.ok) throw new Error('Firebase signing keys are unavailable.');
  const keys = await response.json();
  const certificate = keys[header.kid];
  if (!certificate) throw unauthorized('Unknown Firebase signing key.');
  const pem = certificate.replace(/-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----|\s/g, '');
  const der = decode(pem);
  const key = await crypto.subtle.importKey(
    'spki', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify'],
  );
  const valid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5', key, decode(encodedSignature),
    new TextEncoder().encode(`${encodedHeader}.${encodedPayload}`),
  );
  if (!valid) throw unauthorized('Invalid Firebase ID token signature.');
  return { uid: payload.sub, email: typeof payload.email === 'string' ? payload.email : null };
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
