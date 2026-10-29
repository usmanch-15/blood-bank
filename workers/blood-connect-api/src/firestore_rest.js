const DATASTORE_SCOPE = 'https://www.googleapis.com/auth/datastore';
const accessTokens = new Map();

export class FirestoreTimestamp {
  constructor(milliseconds) {
    this.milliseconds = milliseconds;
  }

  toMillis() {
    return this.milliseconds;
  }

  toDate() {
    return new Date(this.milliseconds);
  }

  static now() {
    return FirestoreTimestamp.fromMillis(Date.now());
  }

  static fromMillis(milliseconds) {
    return new FirestoreTimestamp(milliseconds);
  }
}

const transform = (operation, values = []) => ({ __firestoreTransform: operation, values });

export const FieldValue = {
  delete: () => transform('delete'),
  arrayUnion: (...values) => transform('appendMissingElements', values),
  increment: (value) => transform('increment', [value]),
  serverTimestamp: () => transform('serverTimestamp'),
};

const base64Url = (bytes) => {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
};

function accountFor(env) {
  if (!env.FIREBASE_SERVICE_ACCOUNT) throw new Error('FIREBASE_SERVICE_ACCOUNT is not configured.');
  const account = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  if (!account.client_email || !account.private_key) {
    throw new Error('Firebase service account is missing client_email or private_key.');
  }
  if (account.project_id && account.project_id !== env.FIREBASE_PROJECT_ID) {
    throw new Error('Firebase service account belongs to a different project.');
  }
  return account;
}

async function tokenFor(env, scope = DATASTORE_SCOPE, fetchImpl = fetch) {
  const account = accountFor(env);
  const cacheKey = `${account.project_id || ''}:${account.client_email}:${scope}`;
  const cached = accessTokens.get(cacheKey);
  if (cached && Date.now() < cached.expiresAt - 60_000) return cached.token;
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(new TextEncoder().encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })));
  const claims = base64Url(new TextEncoder().encode(JSON.stringify({
    iss: account.client_email,
    scope,
    aud: account.token_uri || 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })));
  const pem = account.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, '');
  const binary = atob(pem);
  const keyBytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const input = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(input),
  );
  const response = await fetchImpl(account.token_uri || 'https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${input}.${base64Url(new Uint8Array(signature))}`,
    }),
  });
  if (!response.ok) throw new Error(`Google OAuth token exchange failed (${response.status}).`);
  const result = await response.json();
  if (typeof result.access_token !== 'string') {
    throw new Error('Google OAuth response did not include an access token.');
  }
  const expiresAt = Date.now() + Number(result.expires_in || 3600) * 1000;
  accessTokens.set(cacheKey, { token: result.access_token, expiresAt });
  return result.access_token;
}

export const firebaseAccessToken = tokenFor;

function decodeValue(value) {
  if ('nullValue' in value) return null;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('stringValue' in value) return value.stringValue;
  if ('timestampValue' in value) return FirestoreTimestamp.fromMillis(Date.parse(value.timestampValue));
  if ('referenceValue' in value) return value.referenceValue;
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(decodeValue);
  if ('mapValue' in value) return decodeFields(value.mapValue.fields || {});
  return null;
}

function decodeFields(fields) {
  return Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, decodeValue(value)]));
}

function encodeValue(value) {
  if (value && value.__firestoreTransform) {
    throw new Error('Transform values must be encoded as write transforms.');
  }
  if (value instanceof FirestoreTimestamp) {
    return { timestampValue: new Date(value.toMillis()).toISOString() };
  }
  if (value == null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (Number.isInteger(value)) return { integerValue: String(value) };
  if (typeof value === 'number') return { doubleValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encodeValue) } };
  if (typeof value === 'object') {
    return { mapValue: { fields: encodeFields(value) } };
  }
  throw new Error('Unsupported Firestore value.');
}

function encodeFields(fields) {
  return Object.fromEntries(
    Object.entries(fields)
      .filter(([, value]) => !(value?.__firestoreTransform && value.__firestoreTransform === 'delete'))
      .map(([key, value]) => [key, encodeValue(value)]),
  );
}

function resourceName(env, documentPath) {
  const projectId = encodeURIComponent(String(env.FIREBASE_PROJECT_ID || ''));
  if (!projectId) throw new Error('FIREBASE_PROJECT_ID is not configured.');
  const path = documentPath.split('/').map(encodeURIComponent).join('/');
  return `projects/${projectId}/databases/(default)/documents/${path}`;
}

function documentFromResource(document) {
  const path = document.name.split('/documents/')[1] || '';
  const normalizedPath = path.split('/').map(decodeURIComponent).join('/');
  return {
    id: normalizedPath.split('/').at(-1),
    path: normalizedPath,
    data: decodeFields(document.fields || {}),
  };
}

function firestoreQueryValue(value, env) {
  if (value && value.__documentId) {
    return { referenceValue: `${resourceName(env, value.path)}` };
  }
  return encodeValue(value);
}

function structuredQuery(query, env) {
  const result = { from: [{ collectionId: query.collection.split('/').at(-1) }] };
  if (query.filters.length === 1) {
    result.where = query.filters[0];
  } else if (query.filters.length > 1) {
    result.where = {
      compositeFilter: {
        op: 'AND',
        filters: query.filters,
      },
    };
  }

  if (query.orders.length) {
    result.orderBy = query.orders.map(({ field, direction }) => ({
      field: { fieldPath: field },
      direction,
    }));
  }
  if (query.limitValue) result.limit = query.limitValue;
  if (query.cursorValues) {
    result.startAt = {
      values: query.cursorValues.map((value) => firestoreQueryValue(value, env)),
      before: false,
    };
  }
  return result;
}

function queryEndpoint(client, collection) {
  const segments = collection.split('/');
  segments.pop();
  const parentPath = segments.length
    ? `${client.root}/${segments.map(encodeURIComponent).join('/')}`
    : client.root;
  return `${parentPath}:runQuery`;
}

function queryFilter(field, operator, value, env) {
  const operatorMap = {
    '==': 'EQUAL',
    '>': 'GREATER_THAN',
    '>=': 'GREATER_THAN_OR_EQUAL',
    '<': 'LESS_THAN',
    '<=': 'LESS_THAN_OR_EQUAL',
    in: 'IN',
    'array-contains': 'ARRAY_CONTAINS',
  };
  const op = operatorMap[operator];
  if (!op) throw new Error(`Unsupported Firestore query operator: ${operator}`);
  const values = operator === 'in' ? value.map((item) => encodeValue(item)) : [firestoreQueryValue(value, env)];
  return {
    fieldFilter: {
      field: { fieldPath: field },
      op,
      value: values.length === 1 ? values[0] : { arrayValue: { values } },
    },
  };
}

async function readResponse(response) {
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    const error = new Error(body.error?.message || `Firestore REST request failed (${response.status}).`);
    error.status = response.status;
    error.code = body.error?.status || 'INTERNAL';
    throw error;
  }
  return response;
}

function parseFirestoreStream(body, context) {
  const trimmed = body.trim();
  if (!trimmed) return [];
  try {
    if (trimmed.startsWith('[')) {
      const parsed = JSON.parse(trimmed);
      return Array.isArray(parsed) ? parsed : [parsed];
    }
    return trimmed.split('\n').filter(Boolean).map((line) => JSON.parse(line));
  } catch (error) {
    throw new Error(`Firestore returned malformed JSON for ${context}.`, { cause: error });
  }
}

export class FirestoreRestClient {
  constructor(env, fetchImpl = fetch) {
    this.env = env;
    this.fetch = fetchImpl;
    const projectId = String(env.FIREBASE_PROJECT_ID || '');
    const emulatorHost = projectId.startsWith('demo-')
      ? String(env.FIRESTORE_EMULATOR_HOST || '').trim()
      : '';
    if (emulatorHost && /^(?:https?:\/\/|\/|.*[?#])/i.test(emulatorHost)) {
      throw new Error('FIRESTORE_EMULATOR_HOST must be a host and port, without a URL scheme.');
    }
    this.emulator = emulatorHost.length > 0;
    const origin = this.emulator ? `http://${emulatorHost}` : 'https://firestore.googleapis.com';
    this.root = `${origin}/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents`;
    this.FieldValue = FieldValue;
    this.Timestamp = FirestoreTimestamp;
  }

  doc(path) {
    return new FirestoreDocumentReference(this, path);
  }

  collection(path) {
    return new FirestoreQuery(this, path);
  }

  async request(url, init = {}) {
    const authorization = this.emulator
      ? 'Bearer owner'
      : `Bearer ${await tokenFor(this.env, DATASTORE_SCOPE, this.fetch)}`;
    return readResponse(await this.fetch(url, {
      ...init,
      headers: {
        authorization,
        'content-type': 'application/json',
        ...init.headers,
      },
    }));
  }

  async runTransaction(callback, retries = 5) {
    let lastError;
    for (let attempt = 0; attempt < retries; attempt++) {
      const begin = await this.request(`${this.root}:beginTransaction`, {
        method: 'POST',
        body: JSON.stringify({ options: { readWrite: {} } }),
      });
      const { transaction } = await begin.json();
      const tx = new FirestoreTransaction(this, transaction);
      try {
        const result = await callback(tx);
        await this.request(`${this.root}:commit`, {
          method: 'POST',
          body: JSON.stringify({ transaction, writes: tx.writes }),
        });
        return result;
      } catch (error) {
        lastError = error;
        await this.request(`${this.root}:rollback`, {
          method: 'POST',
          body: JSON.stringify({ transaction }),
        }).catch((rollbackError) => {
          console.warn('Firestore transaction rollback failed:', rollbackError.message);
        });
        if (error.code !== 'ABORTED' || attempt === retries - 1) throw error;
      }
    }
    throw lastError;
  }

  async commit(writes) {
    if (!writes.length) return;
    await this.request(`${this.root}:commit`, {
      method: 'POST',
      body: JSON.stringify({ writes }),
    });
  }
}

class FirestoreDocumentReference {
  constructor(client, path) {
    this.client = client;
    this.path = path;
    this.id = path.split('/').at(-1);
  }

  collection(name) {
    return this.client.collection(`${this.path}/${name}`);
  }

  async get() {
    let response;
    try {
      response = await this.client.request(
        `${this.client.root}/${this.path.split('/').map(encodeURIComponent).join('/')}`,
      );
    } catch (error) {
      if (error.status === 404) return { exists: false, id: this.id, ref: this, data: () => undefined };
      throw error;
    }
    const doc = documentFromResource(await response.json());
    return { exists: true, id: this.id, ref: this, data: () => doc.data };
  }

  async set(data) {
    await this.client.commit([writeFor(this.client.env, this.path, data)]);
  }

  async update(data) {
    await this.client.commit([writeFor(this.client.env, this.path, data, true)]);
  }

  async create(data) {
    await this.client.commit([writeFor(this.client.env, this.path, data, false, { exists: false })]);
  }

  async delete() {
    await this.client.commit([{ delete: resourceName(this.client.env, this.path) }]);
  }
}

class FirestoreQuery {
  constructor(client, collection, filters = [], orders = [], limitValue = 0, cursorValues = null) {
    this.client = client;
    this.collection = collection;
    this.filters = filters;
    this.orders = orders;
    this.limitValue = limitValue;
    this.cursorValues = cursorValues;
  }

  doc(documentId = crypto.randomUUID()) {
    return this.client.doc(`${this.collection}/${documentId}`);
  }

  where(field, operator, value) {
    const fieldPath = field === '__name__' ? '__name__' : field;
    return new FirestoreQuery(
      this.client,
      this.collection,
      [...this.filters, queryFilter(fieldPath, operator, value, this.client.env)],
      this.orders,
      this.limitValue,
      this.cursorValues,
    );
  }

  orderBy(field, direction = 'asc') {
    return new FirestoreQuery(
      this.client,
      this.collection,
      this.filters,
      [...this.orders, { field: field === '__name__' ? '__name__' : field, direction: direction === 'desc' ? 'DESCENDING' : 'ASCENDING' }],
      this.limitValue,
      this.cursorValues,
    );
  }

  limit(value) {
    return new FirestoreQuery(this.client, this.collection, this.filters, this.orders, value, this.cursorValues);
  }

  startAfter(...values) {
    const cursor = this.orders.at(-1)?.field === '__name__'
      && typeof values.at(-1) === 'string'
      ? [
        ...values.slice(0, -1),
        { __documentId: true, path: `${this.collection}/${values.at(-1)}` },
      ]
      : values;
    return new FirestoreQuery(this.client, this.collection, this.filters, this.orders, this.limitValue, cursor);
  }

  async get(transaction = null) {
    const body = {
      structuredQuery: structuredQuery(this, this.client.env),
      ...(transaction ? { transaction } : {}),
    };
    const response = await this.client.request(queryEndpoint(this.client, this.collection), {
      method: 'POST',
      body: JSON.stringify(body),
    });
    const results = parseFirestoreStream(await response.text(), `query "${this.collection}"`);
    const docs = results
      .filter((entry) => entry.document)
      .map((entry) => documentFromResource(entry.document));
    return {
      docs: docs.map((doc) => ({
        id: doc.id,
        ref: this.client.doc(doc.path),
        exists: true,
        data: () => doc.data,
      })),
      size: docs.length,
      empty: docs.length === 0,
    };
  }
}

class FirestoreTransaction {
  constructor(client, transaction) {
    this.client = client;
    this.transaction = transaction;
    this.writes = [];
  }

  async get(reference) {
    if (reference instanceof FirestoreQuery) return reference.get(this.transaction);
    const response = await this.client.request(`${this.client.root}:batchGet`, {
      method: 'POST',
      body: JSON.stringify({
        documents: [resourceName(this.client.env, reference.path)],
        transaction: this.transaction,
      }),
    });
    const results = parseFirestoreStream(await response.text(), `batchGet for "${reference.path}"`);
    if (!results.length) {
      throw new Error(`Firestore batchGet returned an empty response for "${reference.path}".`);
    }
    const result = results[0];
    if (result?.missing) return { exists: false, id: reference.id, ref: reference, data: () => undefined };
    const doc = documentFromResource(result.found);
    return { exists: true, id: doc.id, ref: reference, data: () => doc.data };
  }

  create(reference, data) {
    this.writes.push(writeFor(this.client.env, reference.path, data, false, { exists: false }));
  }

  set(reference, data, options = {}) {
    this.writes.push(writeFor(this.client.env, reference.path, data, options.merge === true));
  }

  update(reference, data) {
    this.writes.push(writeFor(this.client.env, reference.path, data, true));
  }

  delete(reference) {
    this.writes.push({ delete: resourceName(this.client.env, reference.path) });
  }

  transform(reference, fieldPath, operation, value) {
    const transformValue = operation === 'increment'
      ? { increment: encodeValue(value) }
      : { setToServerValue: 'REQUEST_TIME' };
    this.writes.push({
      transform: {
        document: resourceName(this.client.env, reference.path),
        fieldTransforms: [{ fieldPath: firestoreFieldPath(fieldPath), ...transformValue }],
      },
    });
  }
}

function writeFor(env, path, data, merge = false, currentDocument = null) {
  const fields = {};
  const updateTransforms = [];
  const updateMask = [];
  for (const [key, value] of Object.entries(data)) {
    if (value?.__firestoreTransform) {
      if (value.__firestoreTransform === 'delete') {
        updateMask.push(firestoreFieldPath(key));
      } else if (value.__firestoreTransform === 'serverTimestamp') {
        updateTransforms.push({ fieldPath: firestoreFieldPath(key), setToServerValue: 'REQUEST_TIME' });
      } else if (value.__firestoreTransform === 'increment') {
        updateTransforms.push({ fieldPath: firestoreFieldPath(key), increment: encodeValue(value.values[0]) });
      } else {
        updateTransforms.push({
          fieldPath: firestoreFieldPath(key),
          appendMissingElements: { values: value.values.map(encodeValue) },
        });
      }
    } else {
      updateMask.push(firestoreFieldPath(key));
      setFieldPath(fields, key, encodeValue(value));
    }
  }
  if (updateTransforms.length && updateMask.length === 0 && !currentDocument) {
    return {
      transform: {
        document: resourceName(env, path),
        fieldTransforms: updateTransforms,
      },
    };
  }
  const write = {
    update: { name: resourceName(env, path), fields },
    ...(merge ? { updateMask: { fieldPaths: updateMask } } : {}),
    ...(updateTransforms.length ? { updateTransforms } : {}),
    ...(currentDocument ? { currentDocument } : {}),
  };
  return write;
}

function firestoreFieldPath(path) {
  return path.split('.').map((part) => /^[A-Za-z_][A-Za-z0-9_]*$/.test(part)
    ? part
    : `\`${part.replace(/\\/g, '\\\\').replace(/`/g, '\\`')}\``).join('.');
}

function setFieldPath(fields, fieldPath, value) {
  const parts = fieldPath.split('.');
  let current = fields;
  for (const part of parts.slice(0, -1)) {
    current[part] ||= { mapValue: { fields: {} } };
    if (!current[part].mapValue) {
      throw new Error(`Cannot update nested Firestore field "${fieldPath}".`);
    }
    current = current[part].mapValue.fields;
  }
  current[parts.at(-1)] = value;
}
