import { sendPush } from './fcm.js';
import { FieldValue, FirestoreRestClient, FirestoreTimestamp } from './firestore_rest.js';

const OPEN_STATUSES = ['pending', 'accepted', 'partially_fulfilled'];
const ASSIGNMENT_STATUSES = ['accepted', 'agreed', 'awaiting_confirmation'];
export const SOS_RADIUS_STEPS_KM = [5, 10, 25, 50];
const ELIGIBILITY_MS = 90 * 86_400_000;
const DONATION_POINTS = 50;
const GROUPS = {
  'A+': ['A+', 'A-', 'O+', 'O-'],
  'A-': ['A-', 'O-'],
  'B+': ['B+', 'B-', 'O+', 'O-'],
  'B-': ['B-', 'O-'],
  'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
  'AB-': ['A-', 'B-', 'AB-', 'O-'],
  'O+': ['O+', 'O-'],
  'O-': ['O-'],
};

class CallableError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'CallableError';
    this.code = code;
    this.publicStatus = true;
    this.status = ({
      'invalid-argument': 400,
      unauthenticated: 401,
      'permission-denied': 403,
      'not-found': 404,
      'already-exists': 409,
      'failed-precondition': 412,
      'resource-exhausted': 429,
    })[code] || 500;
  }
}

const fail = (code, message) => { throw new CallableError(code, message); };
const now = () => FirestoreTimestamp.now();
const millis = (value) => value?.toMillis ? value.toMillis() : typeof value === 'number' ? value : 0;
const isActive = (user) => user?.status === 'approved';
export const isEligible = (donor, time = Date.now()) =>
  !donor?.lastDonationDate || time - millis(donor.lastDonationDate) >= ELIGIBILITY_MS;
export const isCompatible = (donorGroup, recipientGroup) =>
  (GROUPS[recipientGroup] || []).includes(donorGroup);
const inPakistan = (lat, lng) => Number.isFinite(lat) && Number.isFinite(lng)
  && lat >= 23.5 && lat <= 37.1 && lng >= 60.8 && lng <= 77.9;

export function distanceKm(lat1, lng1, lat2, lng2) {
  const radians = (degrees) => degrees * Math.PI / 180;
  const a = Math.sin(radians(lat2 - lat1) / 2) ** 2
    + Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(radians(lng2 - lng1) / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(Math.min(1, a)));
}

function validateId(value, label = 'identifier') {
  if (typeof value !== 'string' || !value.length || value.length > 128 || value.includes('/')) {
    fail('invalid-argument', `Invalid ${label}.`);
  }
  return value;
}

function actorId(identity) {
  if (!identity?.uid) fail('unauthenticated', 'Sign in first.');
  return identity.uid;
}

async function actor(db, identity) {
  const uid = actorId(identity);
  const user = (await db.doc(`users/${uid}`).get()).data();
  if (!isActive(user)) fail('permission-denied', 'Active account required.');
  return { ...user, uid };
}

function assignments(request) {
  const result = { ...(request?.commitments || {}) };
  const ids = [
    ...(Array.isArray(request?.acceptedDonorIds) ? request.acceptedDonorIds : []),
    request?.acceptedDonorId,
  ];
  for (const uid of ids) {
    if (typeof uid === 'string' && uid && !Object.hasOwn(result, uid)) {
      result[uid] = { status: 'accepted', name: 'Assigned donor' };
    }
  }
  return result;
}

function participants(request) {
  const current = assignments(request);
  const activeIds = Object.keys(current).filter((uid) => ASSIGNMENT_STATUSES.includes(current[uid]?.status)
    || current[uid]?.status === 'completed');
  const existing = (request?.participantIds || []).filter((uid) =>
    uid === request.requesterId || !current[uid] || activeIds.includes(uid));
  return [...new Set([...existing, request.requesterId, ...activeIds])];
}

function isExpired(request) {
  const deadline = millis(request?.requiredBy);
  return deadline > 0 && deadline <= Date.now();
}

function actionable(request) {
  return !!request && request.reviewStatus !== 'rejected'
    && OPEN_STATUSES.includes(request.status) && !isExpired(request);
}

function assertOpen(request) {
  if (!actionable(request)) fail('failed-precondition', 'This request is closed or expired.');
}

function text(value, max, required = false) {
  if (value == null && !required) return '';
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) {
    fail('invalid-argument', 'Check the required text fields.');
  }
  return value.trim();
}

function validateCoordinates(data) {
  if (!inPakistan(data.latitude, data.longitude)) {
    fail('invalid-argument', 'Select a location inside Pakistan.');
  }
}

function radiusKm(value) {
  if (value == null) return 5;
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    fail('invalid-argument', 'Select a valid search radius.');
  }
  return Math.min(1000, Math.max(5, value));
}

function serialize(value) {
  if (value?.toMillis) return value.toMillis();
  if (Array.isArray(value)) return value.map(serialize);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([key, nested]) => [key, serialize(nested)]));
  }
  return value;
}

function requestSummary(request, requestId, viewer) {
  const result = {
    id: requestId,
    bloodGroup: request.bloodGroup,
    hospitalName: request.hospitalName,
    quantity: request.quantity,
    donatedUnits: request.donatedUnits || 0,
    remainingUnits: request.remainingUnits ?? request.quantity,
    urgency: request.urgency,
    status: isExpired(request) && OPEN_STATUSES.includes(request.status) ? 'expired' : request.status,
    reviewStatus: request.reviewStatus || null,
    requiredBy: request.requiredBy,
    createdAt: request.createdAt,
  };
  if (viewer && Number.isFinite(viewer.latitude) && Number.isFinite(viewer.longitude)
      && Number.isFinite(request.latitude) && Number.isFinite(request.longitude)) {
    result.distanceKm = distanceKm(viewer.latitude, viewer.longitude, request.latitude, request.longitude);
    result.latitude = Math.round(request.latitude * 100) / 100;
    result.longitude = Math.round(request.longitude * 100) / 100;
  }
  return serialize(result);
}

function addEvent(tx, requestRef, actor, action, detail = '') {
  tx.create(requestRef.collection('events').doc(), {
    actorId: actor,
    action,
    detail,
    createdAt: now(),
  });
}

function addNotification(tx, key, userId, requestId, title, body) {
  tx.set(tx.client.doc(`notifications/${key}`), {
    userId,
    relatedId: requestId,
    type: 'request_update',
    title,
    body,
    isRead: false,
    createdAt: now(),
  });
}

async function rateLimit(db, key, maximum, windowMs = 3_600_000) {
  await db.runTransaction(async (tx) => {
    const ref = db.doc(`rate_limits/${key}`);
    const data = (await tx.get(ref)).data();
    const timestamps = (data?.timestamps || []).filter((value) => value > Date.now() - windowMs);
    if (timestamps.length >= maximum) fail('resource-exhausted', 'Too many attempts. Please try again later.');
    tx.set(ref, { timestamps: [...timestamps, Date.now()] });
  });
}

function liveChat(conversation, request, senderId) {
  const ids = conversation?.participantIds;
  const donorId = ids?.find((id) => id !== request?.requesterId);
  const assignment = assignments(request)[donorId];
  return actionable(request)
    && Array.isArray(ids)
    && ids.length === 2
    && new Set(ids).size === 2
    && ids.includes(senderId)
    && ids.includes(request.requesterId)
    && !(conversation.blockedUserIds || []).includes(senderId)
    && ASSIGNMENT_STATUSES.includes(assignment?.status);
}

async function chatContext(db, identity, data) {
  const user = await actor(db, identity);
  const conversationId = validateId(data?.conversationId, 'conversation');
  const ref = db.doc(`conversations/${conversationId}`);
  const conversation = (await ref.get()).data();
  if (!conversation || !Array.isArray(conversation.participantIds)
      || !conversation.participantIds.includes(user.uid)) {
    fail('permission-denied', 'Conversation unavailable.');
  }
  const otherId = conversation.participantIds.find((uid) => uid !== user.uid);
  if (!otherId) fail('failed-precondition', 'Conversation has no other participant.');
  const request = conversation.requestId
    ? (await db.doc(`blood_requests/${conversation.requestId}`).get()).data()
    : null;
  return { user, conversationId, conversation, ref, otherId, request };
}

function notificationId(value) {
  if (typeof value !== 'string' || !value.length || value.length > 500 || value.includes('/')) {
    fail('invalid-argument', 'Invalid notification ID.');
  }
  return value;
}

function notificationRecord(userId, payload) {
  return {
    userId,
    relatedId: payload.relatedId || null,
    type: payload.type || 'general',
    title: payload.title || 'Smart Blood Bank',
    body: payload.body || '',
    isRead: false,
    createdAt: now(),
    pushSentDirectly: true,
    pushStatus: 'pending',
  };
}

export async function notify(db, env, userId, payload, options = {}) {
  const id = notificationId(options.id || payload.notificationId || crypto.randomUUID());
  const ref = db.doc(`notifications/${id}`);
  if (options.transaction) {
    options.transaction.create(ref, notificationRecord(userId, payload));
    return { notificationId: id, deliveryPending: true };
  }
  if (options.record !== false) {
    const existing = await ref.get();
    if (!existing.exists) {
      try {
        await ref.create(notificationRecord(userId, payload));
      } catch (error) {
        if (error.status !== 409 && error.code !== 'ALREADY_EXISTS') throw error;
      }
    }
  }
  const claimed = await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    if (!current.exists || current.data().pushStatus === 'sending') return null;
    if (current.data().pushStatus === 'sent') return 'already-sent';
    tx.update(ref, { pushStatus: 'sending' });
    return 'claimed';
  });
  if (claimed === 'already-sent') return { notificationId: id, sent: true, reason: 'already-sent' };
  if (claimed !== 'claimed') return { notificationId: id, sent: false, reason: 'already-processing' };

  try {
    const userRef = db.doc(`users/${userId}`);
    const user = (await userRef.get()).data();
    if (!user) {
      await ref.update({ pushStatus: 'user-not-found' });
      return { notificationId: id, sent: false, reason: 'user-not-found' };
    }
    if (!notificationAllowed(user, payload.type)) {
      await ref.update({ pushStatus: 'opted_out' });
      return { notificationId: id, sent: false, reason: 'user-opted-out' };
    }
    const devices = await userRef.collection('devices').get();
    const legacy = await userRef.collection('private').doc('device').get();
    const refs = [...devices.docs, ...(legacy.exists ? [legacy] : [])];
    const tokens = new Set();
    let attempted = false;
    let sent = false;
    for (const device of refs) {
      const token = device.data()?.fcmToken;
      if (typeof token !== 'string' || !token || tokens.has(token)) continue;
      tokens.add(token);
      attempted = true;
      for (let attempt = 0; attempt < 3; attempt++) {
        let result;
        let sendError;
        try {
          result = await sendPush(env, token, {
            title: payload.title || 'Smart Blood Bank',
            body: payload.body || '',
            data: { type: payload.type || 'general', relatedId: payload.relatedId || '', ...(payload.data || {}) },
          });
          sendError = null;
        } catch (error) {
          sendError = error;
        }
        if (result?.delivered) {
          sent = true;
          break;
        }
        if (result?.invalidToken) {
          const current = (await device.ref.get()).data();
          if (current?.fcmToken === token) await device.ref.delete();
          break;
        }
        if (attempt < 2) await new Promise((resolve) => setTimeout(resolve, 500 * (2 ** attempt)));
        else if (sendError) console.warn('FCM delivery failed after retries:', sendError.message);
        else if (!result?.delivered) console.warn('FCM delivery failed after retries with HTTP status:', result?.status);
      }
    }
    const reason = sent ? 'sent' : attempted ? 'max-retries-exceeded' : 'no-token';
    await ref.update({ pushStatus: sent ? 'sent' : attempted ? 'failed' : 'no_token' });
    return { notificationId: id, sent, reason };
  } catch (error) {
    await ref.update({ pushStatus: 'failed' });
    throw error;
  }
}

async function notifyChatMessage(db, env, identity, data) {
  const senderId = actorId(identity);
  const conversationId = validateId(data?.conversationId, 'conversation');
  const messageId = validateId(data?.messageId, 'message');
  const conversationRef = db.doc(`conversations/${conversationId}`);
  const messageRef = conversationRef.collection('messages').doc(messageId);
  const notificationRef = db.doc(`notifications/chat_${conversationId}_${messageId}`);
  const notificationKey = `chat_${conversationId}_${messageId}`;
  const recipientId = await db.runTransaction(async (tx) => {
    const [conversationSnapshot, messageSnapshot] = await Promise.all([
      tx.get(conversationRef),
      tx.get(messageRef),
    ]);
    const conversation = conversationSnapshot.data();
    const message = messageSnapshot.data();
    const ids = conversation?.participantIds;
    if (!conversation || !message || !Array.isArray(ids) || ids.length !== 2
        || new Set(ids).size !== 2 || !ids.includes(senderId)) {
      fail('permission-denied', 'Conversation or message unavailable.');
    }
    if (message.senderId !== senderId) fail('permission-denied', 'Only the message sender can notify this conversation.');
    if ((conversation.blockedUserIds || []).includes(senderId)) return null;
    const recipient = ids.find((id) => id !== senderId);
    const [senderSnapshot, recipientSnapshot, requestSnapshot, existing] = await Promise.all([
      tx.get(db.doc(`users/${senderId}`)),
      tx.get(db.doc(`users/${recipient}`)),
      tx.get(db.doc(`blood_requests/${conversation.requestId}`)),
      tx.get(notificationRef),
    ]);
    if (!isActive(senderSnapshot.data()) || !isActive(recipientSnapshot.data())
        || !liveChat(conversation, requestSnapshot.data(), senderId)) return null;
    if (existing.exists) return null;
    tx.update(conversationRef, { [`unread.${recipient}`]: FieldValue.increment(1) });
    await notify(db, env, recipient, {
      type: 'chat_message',
      relatedId: conversationId,
      title: 'New message',
      body: 'Open the app to view your message.',
    }, { id: notificationKey, transaction: tx });
    return recipient;
  });
  if (!recipientId) return { notified: false };
  const delivery = await notify(db, env, recipientId, {
    type: 'chat_message',
    relatedId: conversationId,
    title: 'New message',
    body: 'Open the app to view your message.',
  }, { id: notificationKey, record: false });
  return { notified: true, sent: delivery.sent };
}

async function blockUser(db, identity, data) {
  const { user, ref, otherId } = await chatContext(db, identity, data);
  await ref.update({
    [`blocks.${user.uid}`]: { blockedUserId: otherId, blockedAt: now() },
    blockedUserIds: FieldValue.arrayUnion(otherId),
  });
  return { blocked: true };
}

async function unblockUser(db, identity, data) {
  const { user, ref, otherId } = await chatContext(db, identity, data);
  const conversation = (await ref.get()).data() || {};
  const blocks = { ...(conversation.blocks || {}) };
  delete blocks[user.uid];
  await ref.update({
    blocks,
    blockedUserIds: (conversation.blockedUserIds || []).filter((uid) => uid !== otherId),
  });
  return { blocked: false };
}

async function markConversationRead(db, identity, data) {
  const { user, ref } = await chatContext(db, identity, data);
  await ref.update({ [`unread.${user.uid}`]: 0 });
  return { read: true };
}

async function reportConversation(db, identity, data) {
  const { user, conversationId, otherId } = await chatContext(db, identity, data);
  const reason = typeof data?.reason === 'string' ? data.reason.trim() : '';
  if (!reason || reason.length > 1000) fail('invalid-argument', 'Reason must be 1-1000 characters.');
  await rateLimit(db, `chat_reports_${user.uid}`, 5);
  const key = `chat_report_${user.uid}_${conversationId}_${data.messageId || otherId}`;
  const reportId = key.replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 150);
  const ref = db.doc(`misuse_reports/${reportId}`);
  if ((await ref.get()).exists) return { alreadyReported: true };
  await ref.create({
    reporterId: user.uid,
    reportedUserId: otherId,
    targetConversationId: conversationId,
    targetMessageId: typeof data.messageId === 'string' ? data.messageId : null,
    title: 'Chat report',
    description: reason.slice(0, 1000),
    category: typeof data.category === 'string' ? data.category.slice(0, 50) : null,
    status: 'pending',
    reportedAt: now(),
  });
  return { reported: true };
}

async function sharePhoneNumber(db, env, identity, data) {
  if (data?.confirm !== true) fail('failed-precondition', 'Explicit confirmation is required.');
  const { user, conversationId, ref, otherId } = await chatContext(db, identity, data);
  const messageId = crypto.randomUUID();
  const messageRef = ref.collection('messages').doc(messageId);
  const notificationKey = `chat_${conversationId}_${messageId}`;
  await db.runTransaction(async (tx) => {
    const conversationSnapshot = await tx.get(ref);
    const currentConversation = conversationSnapshot.data();
    const currentOtherId = currentConversation?.participantIds?.find((uid) => uid !== user.uid);
    if (!currentOtherId || currentOtherId !== otherId) {
      fail('permission-denied', 'Conversation unavailable.');
    }
    const [requestSnapshot, senderSnapshot, receiverSnapshot, contactSnapshot, existing] = await Promise.all([
      tx.get(db.doc(`blood_requests/${currentConversation.requestId}`)),
      tx.get(db.doc(`users/${user.uid}`)),
      tx.get(db.doc(`users/${currentOtherId}`)),
      tx.get(db.doc(`users/${user.uid}/private/contact`)),
      tx.get(db.doc(`notifications/${notificationKey}`)),
    ]);
    if (senderSnapshot.data()?.status !== 'approved' || receiverSnapshot.data()?.status !== 'approved'
        || !liveChat(currentConversation, requestSnapshot.data(), user.uid)) {
      fail('permission-denied', 'Conversation is read-only.');
    }
    const contact = contactSnapshot.data();
    if (!contact?.phoneNumber) fail('failed-precondition', 'No verified phone number is available.');
    if (existing.exists) return;
    tx.create(messageRef, {
      senderId: user.uid,
      type: 'phone_share',
      sharedWith: currentOtherId,
      phoneNumber: contact.phoneNumber,
      body: 'Phone number shared by participant.',
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(ref, { [`unread.${currentOtherId}`]: FieldValue.increment(1) });
    await notify(db, env, currentOtherId, {
      type: 'chat_message',
      relatedId: conversationId,
      title: 'New message',
      body: 'Open the app to view your message.',
    }, { id: notificationKey, transaction: tx });
  });
  await notify(db, env, otherId, {
    type: 'chat_message',
    relatedId: conversationId,
    title: 'New message',
    body: 'Open the app to view your message.',
  }, { id: notificationKey, record: false });
  return { shared: true };
}

async function closeInternal(db, identity, requestId, system = false) {
  const ref = db.doc(`blood_requests/${validateId(requestId, 'request ID')}`);
  return db.runTransaction(async (tx) => {
    const requestSnapshot = await tx.get(ref);
    const request = requestSnapshot.data();
    const userSnapshot = system ? null : await tx.get(db.doc(`users/${identity.uid}`));
    const user = userSnapshot?.data();
    if (!request || (!system && (!isActive(user)
        || (request.requesterId !== identity.uid && user.role !== 'admin')))) {
      fail('permission-denied', 'Only the requester or administrator can close this request.');
    }
    if (system && !isExpired(request)) return { closed: false };
    if (!OPEN_STATUSES.includes(request.status)) return { closed: true };

    const accepted = Object.keys(assignments(request))
      .filter((uid) => ASSIGNMENT_STATUSES.includes(assignments(request)[uid].status));
    const donors = await Promise.all(accepted.map((uid) => tx.get(db.doc(`users/${uid}`))));
    const status = isExpired(request) ? 'expired' : 'cancelled';
    const commitments = assignments(request);
    for (const donor of donors) {
      commitments[donor.id] = { ...commitments[donor.id], status: 'released' };
      if (donor.exists && donor.data().activeRequestId === ref.id) {
        tx.update(donor.ref, { activeRequestId: FieldValue.delete() });
      }
      addNotification(
        tx,
        `closed_${ref.id}_${donor.id}`,
        donor.id,
        ref.id,
        'Request closed',
        `The request was ${status}. Your assignment has been released.`,
      );
    }
    tx.update(ref, { status, commitments, acceptedDonorIds: [], closedAt: now() });
    if (request.sosId) {
      tx.update(db.doc(`sosRequests/${request.sosId}`), {
        status,
        isResolved: true,
        resolvedAt: now(),
      });
    }
    addEvent(tx, ref, system ? 'system' : identity.uid, status);
    return { closed: true };
  });
}

export async function matchingDonors(
  db, latitude, longitude, bloodGroup, radius, resultLimit = 1000, cursorValue = null,
) {
  if (!inPakistan(latitude, longitude)) return { matches: [], cursor: null, scannedPages: 0 };
  const delta = radius / 110.574;
  const minLat = Math.max(-90, latitude - delta);
  const maxLat = Math.min(90, latitude + delta);
  const query = db.collection('users')
    .where('isDonor', '==', true)
    .where('isAvailable', '==', true)
    .where('status', '==', 'approved')
    .where('locationSharingEnabled', '==', true)
    .where('latitude', '>=', minLat)
    .where('latitude', '<=', maxLat)
    .orderBy('latitude')
    .orderBy('__name__')
    .limit(200);
  let cursor = null;
  let hasMore = false;
  let scannedPages = 0;
  const matches = [];
  const limit = Math.min(1000, Math.max(1, resultLimit));
  if (cursorValue != null) {
    const parts = typeof cursorValue === 'string' ? cursorValue.split('|') : [];
    const cursorLatitude = Number(parts[0]);
    const uid = parts[1];
    if (parts.length !== 2 || !parts[0].trim() || !uid || ['.', '..'].includes(uid)
        || uid.includes('/') || uid.length > 128 || !Number.isFinite(cursorLatitude)
        || cursorLatitude < minLat || cursorLatitude > maxLat) {
      fail('invalid-argument', 'Invalid search cursor.');
    }
    cursor = { latitude: cursorLatitude, id: uid };
  }
  while (scannedPages < 5) {
    const page = await (cursor ? query.startAfter(cursor.latitude, cursor.id) : query).get();
    scannedPages++;
    hasMore = page.size === 200;
    for (const [index, doc] of page.docs.entries()) {
      cursor = { latitude: doc.data().latitude, id: doc.id };
      const donor = doc.data();
      let stale = false;
      if (donor.activeRequestId) {
        const activeRequest = (await db.doc(`blood_requests/${donor.activeRequestId}`).get()).data();
        stale = !activeRequest || !OPEN_STATUSES.includes(activeRequest.status) || isExpired(activeRequest);
        if (stale) await doc.ref.update({ activeRequestId: FieldValue.delete() });
      }
      const complete = typeof donor.name === 'string' && donor.name.trim().length >= 2
        && typeof donor.bloodGroup === 'string'
        && Number.isFinite(donor.latitude) && Number.isFinite(donor.longitude);
      if (inPakistan(donor.latitude, donor.longitude) && complete
          && (!bloodGroup || isCompatible(donor.bloodGroup, bloodGroup))
          && isEligible(donor) && donor.isEligible !== false
          && (!donor.activeRequestId || stale)
          && distanceKm(latitude, longitude, donor.latitude, donor.longitude) <= radius) {
        matches.push({
          uid: doc.id,
          data: donor,
          distanceKm: distanceKm(latitude, longitude, donor.latitude, donor.longitude),
        });
        if (matches.length >= limit) {
          hasMore = index < page.size - 1 || page.size === 200;
          break;
        }
      }
    }
    if (matches.length >= limit || page.size < 200) break;
  }
  return { matches, cursor: cursor && hasMore ? `${cursor.latitude}|${cursor.id}` : null, scannedPages };
}

function notificationAllowed(user, category) {
  if (!isActive(user) || user.notificationsEnabled === false) return false;
  if (!category) return true;
  const preference = category === 'donation_confirmed' || category === 'eligibilityReminders'
    ? 'rewardUpdates'
    : category === 'sos' ? 'sosAlerts' : category;
  return user.notificationPrefs?.[preference] !== false;
}

async function notifyUser(db, env, uid, { title, body, data }) {
  if (!(await db.doc(`users/${uid}`).get()).exists) {
    return { sent: false, reason: 'user-not-found' };
  }
  const result = await notify(db, env, uid, {
    title,
    body,
    type: data.type,
    relatedId: data.relatedId,
    data: {
      ...data,
      hospitalName: data.hospitalName || '',
      hospitalLocation: data.hospitalLocation || '',
      bloodGroup: data.bloodGroup || '',
      urgency: data.urgency || '',
    },
  }, { id: `request_${data.requestId}_${uid}` });
  if (result.reason === 'max-retries-exceeded') {
    return { sent: false, reason: 'delivery-failed' };
  }
  return { sent: result.sent, reason: result.reason };
}

async function notifyRequest(db, env, identity, data) {
  const uid = actorId(identity);
  const requestId = validateId(data?.requestId, 'request ID');
  const ref = db.doc(`blood_requests/${requestId}`);
  const [requestSnapshot, userSnapshot] = await Promise.all([
    ref.get(),
    db.doc(`users/${uid}`).get(),
  ]);
  const request = requestSnapshot.data();
  if (!request || request.requesterId !== uid || !isActive(userSnapshot.data()) || !actionable(request)) {
    fail('permission-denied', 'An active request belonging to you is required.');
  }
  const radius = radiusKm(data.radiusKm);
  const requested = data.userIds;
  if (requested != null && (!Array.isArray(requested) || requested.length > 1000
      || requested.some((id) => typeof id !== 'string'))) {
    fail('invalid-argument', 'Select at most 1000 donors per notification request.');
  }
  await rateLimit(db, `notify_${uid}`, 20);
  const donorIds = (await matchingDonors(db, request.latitude, request.longitude, request.bloodGroup, radius))
    .matches.map((donor) => donor.uid);
  const pending = donorIds.filter((donorId) => donorId !== uid
    && !(request.notifiedDonors || []).includes(donorId)
    && (!Array.isArray(requested) || requested.includes(donorId)));
  const recipients = pending.slice(0, 200);
  const completed = [];
  for (const donorId of recipients) {
    const delivery = await notifyUser(db, env, donorId, {
      title: 'Blood donation request',
      body: 'A matching request is available. Open the app for details.',
      data: {
        type: 'blood_request',
        relatedId: requestId,
        requestId,
        hospitalName: request.hospitalName,
        hospitalLocation: request.hospitalAddress || request.location || '',
        bloodGroup: request.bloodGroup,
        urgency: request.urgency,
      },
    });
    if (delivery.reason !== 'delivery-failed' && delivery.reason !== 'already-processing'
        && delivery.reason !== 'user-not-found') {
      completed.push(donorId);
    }
  }
  if (completed.length) {
    await ref.update({ notifiedDonors: FieldValue.arrayUnion(...completed) });
  }
  return {
    count: completed.length,
    remaining: Math.max(0, pending.length - completed.length),
  };
}

export function validateRequest(data, user) {
  validateCoordinates(data);
  if (!['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].includes(data.bloodGroup)) {
    fail('invalid-argument', 'Select a blood group.');
  }
  if (!Number.isInteger(data.quantity) || data.quantity < 1 || data.quantity > 50) {
    fail('invalid-argument', 'Request 1–50 units.');
  }
  const deadline = Number(data.requiredBy);
  if (!Number.isFinite(deadline) || deadline <= Date.now() || deadline > Date.now() + 31 * 86_400_000) {
    fail('invalid-argument', 'Select a future deadline within 31 days.');
  }
  const urgency = text(data.urgency || 'normal', 30).toLowerCase();
  if (!['normal', 'low', 'urgent', 'critical', 'life_threatening'].includes(urgency)) {
    fail('invalid-argument', 'Invalid urgency.');
  }
  const contact = text(data.contactNumber, 20, true);
  if (!/^\+?[0-9]{10,15}$/.test(contact)) fail('invalid-argument', 'Enter a valid contact number.');
  if (data.patientAge != null && (!Number.isInteger(data.patientAge) || data.patientAge < 1 || data.patientAge > 120)) {
    fail('invalid-argument', 'Invalid patient age.');
  }
  return {
    requesterId: user.uid,
    requesterName: user.name || '',
    bloodGroup: data.bloodGroup,
    quantity: data.quantity,
    unitsRequired: data.quantity,
    donatedUnits: 0,
    remainingUnits: data.quantity,
    hospitalId: text(data.hospitalId, 128),
    hospitalName: text(data.hospitalName, 100, true),
    hospitalAddress: text(data.hospitalAddress, 300, true),
    location: text(data.hospitalAddress, 300, true),
    latitude: data.latitude,
    longitude: data.longitude,
    patientName: text(data.patientName, 100),
    patientAge: data.patientAge ?? null,
    patientGender: text(data.patientGender, 20),
    reason: text(data.reason, 1000),
    contactNumber: contact,
    requesterPhone: contact,
    urgency,
    requiredBy: FirestoreTimestamp.fromMillis(deadline),
    createdAt: now(),
    updatedAt: now(),
    status: 'pending',
    participantIds: [user.uid],
    acceptedDonorIds: [],
    commitments: {},
    notifiedDonors: [],
    schemaVersion: 2,
    source: 'cloudflare',
    ...( ['urgent', 'critical', 'life_threatening'].includes(urgency) ? { reviewStatus: 'pending_review' } : {}),
  };
}

async function createBloodRequest(db, env, identity, input) {
  const user = await actor(db, identity);
  if (!user.isReceiver) fail('permission-denied', 'Receiver account required.');
  const data = { ...(input || {}) };
  if (!data.contactNumber) {
    data.contactNumber = (await db.doc(`users/${user.uid}/private/contact`).get()).data()?.phoneNumber;
  }
  if (data.hospitalId) {
    const hospital = (await db.doc(`hospitals/${validateId(data.hospitalId)}`).get()).data();
    if (!hospital || typeof hospital.name !== 'string' || !hospital.name.trim()
        || typeof hospital.address !== 'string' || !hospital.address.trim()
        || !Number.isFinite(hospital.latitude) || hospital.latitude < -90 || hospital.latitude > 90
        || !Number.isFinite(hospital.longitude) || hospital.longitude < -180 || hospital.longitude > 180) {
      fail('failed-precondition', 'The selected hospital is not configured with a valid location.');
    }
    if (data.hospitalName?.trim() !== hospital.name.trim()
        || data.hospitalAddress?.trim() !== hospital.address.trim()
        || data.latitude !== hospital.latitude || data.longitude !== hospital.longitude) {
      fail('invalid-argument', 'Hospital details do not match the selected hospital.');
    }
  }
  const requestData = validateRequest(data, user);
  const requestId = validateId(input?.requestId, 'request ID');
  const ref = db.doc(`blood_requests/${requestId}`);
  await rateLimit(db, `requests_${user.uid}`, 20);
  const existing = await ref.get();
  if (existing.exists) {
    if (existing.data().requesterId !== user.uid) fail('permission-denied', 'Request belongs to another account.');
    const notificationStatus = await matchAndNotifySafely(db, env, identity, requestId, existing.data());
    return { id: requestId, notificationStatus };
  }
  const cutoff = FirestoreTimestamp.fromMillis(Date.now() - 30 * 60_000);
  await db.runTransaction(async (tx) => {
    const guard = db.doc(`request_submission_guards/${user.uid}`);
    await tx.get(guard);
    const requestSnapshot = await tx.get(ref);
    if (requestSnapshot.exists) {
      if (requestSnapshot.data().requesterId !== user.uid) fail('permission-denied', 'Request belongs to another account.');
      return;
    }
    const recent = await tx.get(db.collection('blood_requests')
      .where('requesterId', '==', user.uid)
      .where('createdAt', '>=', cutoff)
      .limit(25));
    const duplicate = recent.docs.some((doc) => {
      const recentRequest = doc.data();
      return recentRequest.bloodGroup === requestData.bloodGroup
        && String(recentRequest.hospitalId || '') === String(requestData.hospitalId || '')
        && recentRequest.hospitalName === requestData.hospitalName
        && OPEN_STATUSES.includes(recentRequest.status);
    });
    if (duplicate) {
      fail('already-exists', 'A similar blood request was created recently. Please review it before creating another.');
    }
    tx.set(guard, { updatedAt: now() });
    tx.create(ref, requestData);
    addEvent(tx, ref, user.uid, 'created');
  });

  const notificationStatus = await matchAndNotifySafely(db, env, identity, requestId, requestData);
  return { id: requestId, notificationStatus };
}

async function matchAndNotifySafely(db, env, identity, requestId, requestData) {
  try {
    const result = await matchAndNotify(db, env, identity, requestId, requestData);
    return result.remaining > 0 ? 'pending' : 'complete';
  } catch (error) {
    console.error('Blood request was saved; donor notification dispatch is pending.', {
      code: typeof error?.code === 'string' ? error.code : 'internal',
    });
    return 'pending';
  }
}

async function matchAndNotify(db, env, identity, requestId, requestData) {
  let selectedRadius = 5;
  let recipients = [];
  for (const radius of [5, 10, 25, 50]) {
    selectedRadius = radius;
    recipients = (await matchingDonors(
      db, requestData.latitude, requestData.longitude, requestData.bloodGroup, radius,
    ))
      .matches.map((donor) => donor.uid).filter((donorId) => donorId !== identity.uid);
    if (recipients.length) break;
  }
  if (recipients.length) {
    return notifyRequest(db, env, identity, { requestId, radiusKm: selectedRadius, userIds: recipients });
  }
  return { count: 0, remaining: 0 };
}

async function acceptDonation(db, identity, data) {
  const caller = actorId(identity);
  const requestId = validateId(data?.requestId, 'request ID');
  const ref = db.doc(`blood_requests/${requestId}`);
  return db.runTransaction(async (tx) => {
    const [requestSnapshot, donorSnapshot] = await Promise.all([
      tx.get(ref),
      tx.get(db.doc(`users/${caller}`)),
    ]);
    const request = requestSnapshot.data();
    const donor = donorSnapshot.data();
    if (!isActive(donor) || !donor.isDonor || !donor.isAvailable || !request || request.requesterId === caller) {
      fail('permission-denied', 'Active available donor required.');
    }
    const owner = (await tx.get(db.doc(`users/${request.requesterId}`))).data();
    if (!isActive(owner)) fail('permission-denied', 'Requester is inactive.');
    assertOpen(request);
    const commitments = assignments(request);
    const mine = commitments[caller];
    if (['accepted', 'agreed', 'awaiting_confirmation'].includes(mine?.status)) return { accepted: true };
    if (mine?.status === 'completed') fail('failed-precondition', 'You already contributed to this request.');
    if (donor.activeRequestId && donor.activeRequestId !== requestId) {
      const previous = (await tx.get(db.doc(`blood_requests/${donor.activeRequestId}`))).data();
      if (previous && OPEN_STATUSES.includes(previous.status) && !isExpired(previous)) {
        fail('failed-precondition', 'Withdraw from your active donation first.');
      }
    }
    if (!isEligible(donor) || !isCompatible(donor.bloodGroup, request.bloodGroup)) {
      fail('failed-precondition', 'Donation interval or blood group does not match.');
    }
    const accepted = Object.keys(commitments).filter((uid) => ASSIGNMENT_STATUSES.includes(commitments[uid].status));
    if ((request.donatedUnits || 0) + accepted.length >= request.quantity) {
      fail('failed-precondition', 'All remaining units have donor commitments.');
    }
    commitments[caller] = { status: 'accepted', name: donor.name || 'Donor', acceptedAt: now(), units: 1 };
    tx.update(ref, {
      commitments,
      acceptedDonorIds: [...accepted, caller],
      participantIds: [...new Set([...participants(request), caller])],
      status: request.donatedUnits ? 'partially_fulfilled' : 'accepted',
      updatedAt: now(),
    });
    tx.set(db.doc(`conversations/${requestId}_${caller}`), {
      requestId,
      participantIds: [request.requesterId, caller],
      updatedAt: now(),
    }, { merge: true });
    tx.update(donorSnapshot.ref, { activeRequestId: requestId });
    tx.set(db.doc(`blood_requests/${requestId}/invites/${caller}`), { status: 'confirmed', updatedAt: now() }, { merge: true });
    addNotification(tx, `accepted_${requestId}_${caller}`, request.requesterId, requestId,
      'Donor accepted', `${donor.name || 'A donor'} committed one unit. Open request tracking.`);
    addEvent(tx, ref, caller, 'accepted');
    return { accepted: true };
  });
}

async function declineRequest(db, identity, data) {
  const user = await actor(db, identity);
  const requestId = validateId(data?.requestId, 'request ID');
  if (!user.isDonor) fail('permission-denied', 'Donor account required.');
  const ref = db.doc(`blood_requests/${requestId}`);
  return db.runTransaction(async (tx) => {
    const request = (await tx.get(ref)).data();
    if (!actionable(request)) fail('failed-precondition', 'This request is closed or expired.');
    if (request.requesterId === user.uid || !isCompatible(user.bloodGroup, request.bloodGroup)
        || !isEligible(user) || !user.isAvailable) {
      fail('permission-denied', 'This request is not available to you.');
    }
    const existing = assignments(request)[user.uid];
    if (existing && [...ASSIGNMENT_STATUSES, 'completed'].includes(existing.status)) {
      fail('failed-precondition', 'You already accepted this request.');
    }
    const declined = [...(user.declinedRequestIds || [])];
    if (declined.includes(requestId)) return { declined: true, alreadyDeclined: true };
    declined.push(requestId);
    tx.update(db.doc(`users/${user.uid}`), { declinedRequestIds: declined });
    tx.set(db.doc(`blood_requests/${requestId}/invites/${user.uid}`), { status: 'declined', updatedAt: now() }, { merge: true });
    return { declined: true };
  });
}

async function updateAssignment(db, identity, data) {
  const caller = actorId(identity);
  const requestId = validateId(data?.requestId, 'request ID');
  const donorId = validateId(data?.donorId || caller, 'donor ID');
  const action = data?.action;
  if (!['withdraw', 'release', 'ready', 'agree', 'decline'].includes(action)) {
    fail('invalid-argument', 'Invalid assignment action.');
  }
  const ref = db.doc(`blood_requests/${requestId}`);
  return db.runTransaction(async (tx) => {
    const [requestSnapshot, userSnapshot, donorSnapshot] = await Promise.all([
      tx.get(ref),
      tx.get(db.doc(`users/${caller}`)),
      tx.get(db.doc(`users/${donorId}`)),
    ]);
    const request = requestSnapshot.data();
    const user = userSnapshot.data();
    if (!isActive(user) || !request) fail('permission-denied', 'Request unavailable.');
    const owner = caller === request.requesterId || user.role === 'admin';
    if ((action === 'release' && !owner) || (action !== 'release' && caller !== donorId)) {
      fail('permission-denied', 'Action not permitted.');
    }
    const commitments = assignments(request);
    const entry = commitments[donorId];
    if (!entry || !ASSIGNMENT_STATUSES.includes(entry.status)) fail('failed-precondition', 'No active assignment.');
    if (['agree', 'decline'].includes(action) && entry.status !== 'accepted') {
      if (entry.status === (action === 'agree' ? 'agreed' : 'declined')) return { updated: true, alreadyResponded: true };
      fail('failed-precondition', 'The agreement has already been answered.');
    }
    if (['agree', 'decline'].includes(action) || action === 'ready') assertOpen(request);
    if (action === 'ready' && entry.status !== 'agreed') {
      fail('failed-precondition', 'The donor must agree before requesting donation confirmation.');
    }
    const nextStatus = action === 'ready' ? 'awaiting_confirmation'
      : action === 'agree' ? 'agreed'
        : action === 'decline' ? 'declined'
          : action === 'release' ? 'released' : 'withdrawn';
    commitments[donorId] = {
      ...entry,
      status: nextStatus,
      ...(action === 'ready' ? { donorConfirmedAt: now() } : {}),
      ...(action === 'agree' ? { agreedAt: now() } : {}),
      ...(action === 'decline' ? { declinedAt: now() } : {}),
      updatedAt: now(),
    };
    const accepted = Object.keys(commitments).filter((uid) => ASSIGNMENT_STATUSES.includes(commitments[uid].status));
    const updates = { commitments, acceptedDonorIds: accepted, updatedAt: now() };
    if (['withdraw', 'release', 'decline'].includes(action)) {
      updates.participantIds = participants(request).filter((uid) => uid !== donorId);
      updates.acceptedDonorId = FieldValue.delete();
      if (OPEN_STATUSES.includes(request.status)) {
        updates.status = isExpired(request) ? 'expired' : request.donatedUnits
          ? 'partially_fulfilled' : accepted.length ? 'accepted' : 'pending';
      }
      if (donorSnapshot.exists && donorSnapshot.data().activeRequestId === requestId) {
        tx.update(donorSnapshot.ref, { activeRequestId: FieldValue.delete() });
      }
    }
    tx.update(ref, updates);
    const recipient = ['release', 'withdraw', 'decline'].includes(action)
      ? (owner ? donorId : request.requesterId) : request.requesterId;
    const title = action === 'agree' ? 'Donor agreed to donate'
      : action === 'decline' ? 'Donor did not agree'
        : action === 'ready' ? 'Donation awaiting confirmation' : 'Assignment updated';
    const body = action === 'agree'
      ? 'The donor agreed to coordinate this donation. Confirm only after blood is actually received.'
      : action === 'decline'
        ? 'The donor did not confirm the agreement. You can find another donor.'
        : action === 'ready'
          ? 'Please confirm the donation after it has taken place.'
          : 'A donor assignment was released. Remaining units can be reassigned.';
    addNotification(tx, `${action}_${requestId}_${donorId}`, recipient, requestId, title, body);
    addEvent(tx, ref, caller, action, donorId);
    return { updated: true };
  });
}

async function getRequest(db, identity, data) {
  const user = await actor(db, identity);
  const requestId = validateId(data?.requestId, 'request ID');
  const request = (await db.doc(`blood_requests/${requestId}`).get()).data();
  if (!request) fail('not-found', 'Request no longer exists.');
  const privateOwner = user.role === 'admin' || user.uid === request.requesterId;
  const permitted = privateOwner || participants(request).includes(user.uid);
  if (!permitted && (!user.isDonor || !actionable(request))) fail('permission-denied', 'Request is not available.');
  const donorParticipant = !privateOwner && participants(request).includes(user.uid);
  const own = assignments(request)[user.uid];
  const donorView = donorParticipant ? {
    id: requestId,
    bloodGroup: request.bloodGroup,
    hospitalName: request.hospitalName,
    hospitalAddress: request.hospitalAddress,
    location: request.location,
    latitude: request.latitude,
    longitude: request.longitude,
    quantity: request.quantity,
    donatedUnits: request.donatedUnits || 0,
    remainingUnits: request.remainingUnits ?? request.quantity,
    urgency: request.urgency,
    status: isExpired(request) && OPEN_STATUSES.includes(request.status) ? 'expired' : request.status,
    requesterId: request.requesterId,
    requiredBy: request.requiredBy,
    createdAt: request.createdAt,
    commitments: own ? {
      [user.uid]: {
        status: own.status,
        units: own.units || 1,
        acceptedAt: own.acceptedAt || null,
        agreedAt: own.agreedAt || null,
        donorConfirmedAt: own.donorConfirmedAt || null,
      },
    } : {},
  } : null;
  return {
    ...(privateOwner ? serialize(request) : serialize(donorView) || requestSummary(request, requestId)),
    id: requestId,
    canViewPrivate: privateOwner,
  };
}

async function discoverRequests(db, identity, data) {
  const user = await actor(db, identity);
  if (!user.isDonor) fail('permission-denied', 'Donor account required.');
  const radius = radiusKm(data?.radiusKm);
  if (!inPakistan(user.latitude, user.longitude)) {
    fail('failed-precondition', 'Save a location inside Pakistan to discover requests.');
  }
  if (!isEligible(user) || !user.isAvailable) return { items: [], cursor: null };
  const base = db.collection('blood_requests')
    .where('status', 'in', OPEN_STATUSES)
    .orderBy('__name__')
    .limit(100);
  let cursor = data?.cursor ? validateId(data.cursor, 'cursor') : null;
  const items = [];
  for (let batch = 0; batch < 4; batch++) {
    const page = await (cursor ? base.startAfter(cursor) : base).get();
    for (const doc of page.docs) {
      const request = doc.data();
      if (request.requesterId !== user.uid
          && !(request.acceptedDonorIds || []).includes(user.uid)
          && request.acceptedDonorId !== user.uid
          && actionable(request)
          && inPakistan(request.latitude, request.longitude)
          && isCompatible(user.bloodGroup, request.bloodGroup)
          && !(user.declinedRequestIds || []).includes(doc.id)
          && distanceKm(user.latitude, user.longitude, request.latitude, request.longitude) <= radius) {
        items.push(requestSummary(request, doc.id, user));
      }
    }
    cursor = page.size === 100 ? page.docs.at(-1).id : null;
    if (!cursor || items.length >= 40) break;
  }
  const weight = { critical: 4, life_threatening: 4, urgent: 3, normal: 2, low: 1 };
  items.sort((left, right) => (weight[right.urgency] || 1) - (weight[left.urgency] || 1)
    || left.distanceKm - right.distanceKm);
  return { items, cursor };
}

async function findDonors(db, identity, data) {
  const user = await actor(db, identity);
  validateCoordinates(data || {});
  const radius = radiusKm(data?.radiusKm);
  const resultLimit = Math.min(100, Number(data?.limit) || 100);
  const page = await matchingDonors(
    db, data.latitude, data.longitude, data.bloodGroup || null, radius, resultLimit, data.cursor,
  );
  const donors = page.matches
    .filter((entry) => entry.uid !== user.uid)
    .map(({ uid, data: donor }) => {
      const distance = distanceKm(data.latitude, data.longitude, donor.latitude, donor.longitude);
      const verified = donor.verificationStatus === 'approved'
        && (!donor.verificationExpiresAt || millis(donor.verificationExpiresAt) > Date.now());
      const weight = { critical: 4, life_threatening: 4, urgent: 3, normal: 2, low: 1 };
      return {
        uid,
        name: donor.name,
        bloodGroup: donor.bloodGroup,
        profileImageUrl: donor.profileImageUrl || null,
        profileVerified: verified,
        isEligible: isEligible(donor),
        isAvailable: donor.isAvailable === true,
        status: donor.status,
        latitude: Math.round(donor.latitude * 100) / 100,
        longitude: Math.round(donor.longitude * 100) / 100,
        distanceKm: distance,
        matchScore: (weight[data.urgency] || 2) * 100 - distance,
      };
    })
    .sort((left, right) => right.matchScore - left.matchScore);
  return {
    donors,
    cursor: page.cursor,
    scannedPages: page.scannedPages,
    ranking: 'score = urgencyWeight(request) × 100 − distanceKm; urgency weights critical/life_threatening=4, urgent=3, normal=2, low=1',
  };
}

export function donationTimelineLabel(donation) {
  if (donation.disputed === true || donation.status === 'disputed') return 'disputed';
  if (['cancelled', 'withdrawn', 'released'].includes(donation.status)) return 'cancelled';
  if (donation.completedAt || donation.status === 'completed') return 'completed';
  if (donation.acceptedAt || donation.status === 'accepted') return 'accepted';
  return 'proposed';
}

async function notifyAfterCommit(db, env, userId, payload, id) {
  return notify(db, env, userId, payload, { id, record: false });
}

async function createSosAlert(db, env, identity, data) {
  const user = await actor(db, identity);
  if (!user.isReceiver) fail('permission-denied', 'Receiver account required.');
  validateCoordinates(data || {});
  if (!['urgent', 'critical', 'life_threatening'].includes(data.urgency)) {
    fail('invalid-argument', 'Choose an emergency level.');
  }
  const privateContact = (await db.doc(`users/${user.uid}/private/contact`).get()).data();
  const hospitalName = text(data.hospitalName || 'Emergency meeting point', 100, true);
  const requestData = validateRequest({
    ...data,
    quantity: 1,
    requiredBy: Date.now() + 6 * 3_600_000,
    hospitalName,
    hospitalAddress: text(data.hospitalAddress, 300) || hospitalName,
    contactNumber: data.contactNumber || privateContact?.phoneNumber,
  }, user);
  await rateLimit(db, `sos_${user.uid}`, 3);
  const sosId = data.submissionId ? validateId(data.submissionId, 'SOS ID') : crypto.randomUUID();
  const sosRef = db.doc(`sosRequests/${sosId}`);
  const requestRef = db.collection('blood_requests').doc();
  const result = await db.runTransaction(async (tx) => {
    const existing = await tx.get(sosRef);
    if (existing.exists) {
      const sos = existing.data();
      if (sos.receiverId !== user.uid) fail('permission-denied', 'SOS belongs to another account.');
      return { id: sosId, requestId: sos.requestId, created: false };
    }
    tx.create(requestRef, {
      ...requestData,
      sosId,
      reviewStatus: 'pending_review',
      source: 'cloudflare',
    });
    tx.create(sosRef, {
      receiverId: user.uid,
      requestId: requestRef.id,
      bloodGroup: requestData.bloodGroup,
      latitude: requestData.latitude,
      longitude: requestData.longitude,
      urgency: requestData.urgency,
      triggerTime: now(),
      requiredBy: requestData.requiredBy,
      isResolved: false,
      status: 'queued',
      reviewStatus: 'pending_review',
      notifiedDonors: [],
      source: 'cloudflare',
    });
    return { id: sosId, requestId: requestRef.id, created: true };
  });
  if (result.created) await notifyNearbyDonorsOnSOS(db, env, sosId);
  return { id: result.id, requestId: result.requestId };
}

async function notifyNearbyDonorsOnSOS(db, env, sosId) {
  const sosRef = db.doc(`sosRequests/${sosId}`);
  const sos = (await sosRef.get()).data();
  if (!sos || !sos.bloodGroup || !sos.receiverId || sos.isResolved
      || sos.reviewStatus === 'rejected') return { notified: 0 };
  if (sos.requestId && !actionable((await db.doc(`blood_requests/${sos.requestId}`).get()).data())) {
    return { notified: 0 };
  }
  const owner = (await db.doc(`users/${sos.receiverId}`).get()).data();
  if (!isActive(owner)) return { notified: 0 };

  let donorIds = [];
  let radiusKm = 50;
  for (const radius of SOS_RADIUS_STEPS_KM) {
    donorIds = (await matchingDonors(
      db,
      sos.latitude,
      sos.longitude,
      sos.bloodGroup,
      radius,
    )).matches.map(({ uid }) => uid);
    if (donorIds.length) {
      radiusKm = radius;
      break;
    }
  }
  const canNotify = await db.runTransaction(async (tx) => {
    const current = (await tx.get(sosRef)).data();
    const root = current?.requestId
      ? (await tx.get(db.doc(`blood_requests/${current.requestId}`))).data()
      : null;
    if (!current || current.isResolved || current.reviewStatus === 'rejected'
        || (current.requestId && !actionable(root))) return false;
    tx.update(sosRef, { notifiedDonors: donorIds, radiusKm, status: 'processed' });
    return true;
  });
  if (!canNotify) return { notified: 0 };

  const results = await Promise.all(donorIds.map((donorId) => notify(db, env, donorId, {
    title: '🚨 SOS Blood Request',
    body: `Urgent: ${sos.bloodGroup} blood needed nearby. Tap to view.`,
    type: 'sosAlerts',
    relatedId: sosId,
    data: { type: 'sosAlerts', relatedId: sosId },
  }, { id: `sos_${sosId}_${donorId}` })));
  return {
    notified: donorIds.length,
    radiusKm,
    sent: results.filter((result) => result.sent).length,
  };
}

async function getSos(db, identity, data) {
  const user = await actor(db, identity);
  const sosId = validateId(data?.sosId, 'SOS ID');
  const snapshot = await db.doc(`sosRequests/${sosId}`).get();
  const sos = snapshot.data();
  if (!sos) fail('not-found', 'SOS no longer exists.');
  const linked = sos.requestId
    ? (await db.doc(`blood_requests/${sos.requestId}`).get()).data()
    : null;
  const participant = linked && participants(linked).includes(user.uid);
  if (sos.receiverId !== user.uid && user.role !== 'admin' && !participant) {
    fail('permission-denied', 'SOS unavailable.');
  }
  return {
    id: sosId,
    requestId: sos.requestId,
    bloodGroup: sos.bloodGroup,
    urgency: sos.urgency,
    status: sos.status,
    isResolved: sos.isResolved,
  };
}

async function resolveSos(db, identity, data) {
  const user = await actor(db, identity);
  const sosId = validateId(data?.sosId, 'SOS ID');
  const ref = db.doc(`sosRequests/${sosId}`);
  const sos = (await ref.get()).data();
  if (!sos || (sos.receiverId !== user.uid && user.role !== 'admin')) {
    fail('permission-denied', 'Only the owner can resolve this SOS.');
  }
  if (sos.requestId) await closeRequest(db, identity, { requestId: sos.requestId });
  await ref.update({
    isResolved: true,
    status: data?.cancel ? 'cancelled' : 'resolved',
    resolvedAt: now(),
  });
  return { resolved: true };
}

async function confirmDonation(db, env, identity, data) {
  const caller = actorId(identity);
  const requestId = validateId(data?.requestId, 'request ID');
  const donorId = validateId(data?.donorId, 'donor ID');
  const requestRef = db.doc(`blood_requests/${requestId}`);
  const donorRef = db.doc(`users/${donorId}`);
  const donationRef = db.doc(`donations/${requestId}_${donorId}`);
  const result = await db.runTransaction(async (tx) => {
    const [requestSnapshot, donorSnapshot, userSnapshot, existing, legacy] = await Promise.all([
      tx.get(requestRef),
      tx.get(donorRef),
      tx.get(db.doc(`users/${caller}`)),
      tx.get(donationRef),
      tx.get(db.doc(`donations/${requestId}`)),
    ]);
    const request = requestSnapshot.data();
    const donor = donorSnapshot.data();
    const user = userSnapshot.data();
    if (!isActive(user) || !isActive(donor) || !request
        || (caller !== request.requesterId && user.role !== 'admin')) {
      fail('permission-denied', 'The requester or administrator must confirm completion.');
    }
    if (existing.exists) return { donationId: existing.id, alreadyConfirmed: true };
    if (legacy.exists && legacy.data().donorId === donorId) {
      return { donationId: legacy.id, alreadyConfirmed: true };
    }
    assertOpen(request);
    const commitments = assignments(request);
    const entry = commitments[donorId];
    if (!entry || entry.status !== 'awaiting_confirmation' || !entry.donorConfirmedAt) {
      fail('failed-precondition', 'The donor must confirm the donation first.');
    }
    if (!donor.isDonor || !isEligible(donor) || !isCompatible(donor.bloodGroup, request.bloodGroup)) {
      fail('failed-precondition', 'Donor interval or group does not match.');
    }
    const donatedUnits = (request.donatedUnits || 0) + 1;
    if (donatedUnits > request.quantity) fail('failed-precondition', 'Request is already filled.');
    const stamp = now();
    const nextEligibleDate = FirestoreTimestamp.fromMillis(stamp.toMillis() + ELIGIBILITY_MS);
    commitments[donorId] = {
      ...entry,
      status: 'completed',
      receiverConfirmedAt: stamp,
      completedAt: stamp,
      units: 1,
    };
    const acceptedDonorIds = Object.keys(commitments)
      .filter((uid) => ASSIGNMENT_STATUSES.includes(commitments[uid].status));
    tx.create(donationRef, {
      donorId,
      requesterId: request.requesterId,
      donorName: donor.name || '',
      bloodGroup: donor.bloodGroup,
      donationDate: stamp,
      location: request.hospitalName,
      requestId,
      units: 1,
      status: 'completed',
      completedAt: stamp,
      pointsEarned: DONATION_POINTS,
      confirmedBy: caller,
    });
    tx.update(donorRef, {
      lastDonationDate: stamp,
      nextEligibleDate,
      isEligible: false,
      rewardPoints: FieldValue.increment(DONATION_POINTS),
      activeRequestId: FieldValue.delete(),
    });
    tx.update(requestRef, {
      commitments,
      acceptedDonorIds,
      participantIds: participants(request),
      donatedUnits,
      remainingUnits: request.quantity - donatedUnits,
      status: donatedUnits === request.quantity ? 'fulfilled' : 'partially_fulfilled',
      ...(donatedUnits === request.quantity ? { fulfilledAt: stamp } : {}),
      updatedAt: stamp,
    });
    if (request.sosId && donatedUnits === request.quantity) {
      tx.update(db.doc(`sosRequests/${request.sosId}`), {
        isResolved: true,
        status: 'resolved',
        resolvedAt: stamp,
      });
    }
    await notify(db, env, donorId, {
      type: 'donation_confirmed',
      relatedId: requestId,
      title: 'Donation confirmed',
      body: `One unit confirmed. You earned ${DONATION_POINTS} points.`,
    }, { id: `donation_${requestId}_${donorId}`, transaction: tx });
    await notify(db, env, request.requesterId, {
      type: 'donation_confirmed',
      relatedId: requestId,
      title: donatedUnits === request.quantity ? 'Request fulfilled' : 'Donation recorded',
      body: `${donatedUnits} of ${request.quantity} units confirmed.`,
    }, { id: `progress_${requestId}_${donorId}`, transaction: tx });
    addEvent(tx, requestRef, caller, 'donation_confirmed', donorId);
    return {
      donationId: donationRef.id,
      donatedUnits,
      remainingUnits: request.quantity - donatedUnits,
      notifications: [
        { userId: donorId, id: `donation_${requestId}_${donorId}` },
        { userId: request.requesterId, id: `progress_${requestId}_${donorId}` },
      ],
    };
  });
  if (result.notifications) {
    await Promise.all(result.notifications.map(({ userId, id }) => notifyAfterCommit(
      db,
      env,
      userId,
      { type: 'donation_confirmed', relatedId: requestId },
      id,
    )));
    delete result.notifications;
  }
  return result;
}

async function donationHistory(db, identity, data) {
  const user = await actor(db, identity);
  const pageSize = Math.min(Math.max(Number(data?.limit) || 30, 1), 50);
  const field = user.role === 'receiver' ? 'requesterId' : 'donorId';
  const snapshot = await db.collection('donations')
    .where(field, '==', user.uid)
    .orderBy('donationDate', 'desc')
    .limit(pageSize)
    .get();
  return {
    items: snapshot.docs.map((document) => {
      const donation = document.data();
      const { phoneNumber: _phoneNumber, privateContact: _privateContact, ...safe } = donation;
      return { id: document.id, ...serialize(safe), statusLabel: donationTimelineLabel(donation) };
    }),
    hasMore: snapshot.size === pageSize,
  };
}

async function submitDonationDispute(db, identity, data) {
  const user = await actor(db, identity);
  const donationId = typeof data?.donationId === 'string' ? data.donationId : '';
  const reason = typeof data?.reason === 'string' ? data.reason.trim() : '';
  if (!donationId || !reason || reason.length > 1000) {
    fail('invalid-argument', 'Provide a donation and a reason up to 1000 characters.');
  }
  const donation = (await db.doc(`donations/${validateId(donationId, 'donation ID')}`).get()).data();
  if (!donation || (donation.donorId !== user.uid && donation.requesterId !== user.uid)) {
    fail('permission-denied', 'Donation unavailable.');
  }
  await rateLimit(db, `donation_dispute_${user.uid}`, 5);
  const reportId = `donation_${donationId}_${user.uid}`;
  const reportRef = db.doc(`misuse_reports/${reportId}`);
  if ((await reportRef.get()).exists) return { alreadySubmitted: true };
  await reportRef.create({
    reporterId: user.uid,
    reportedUserId: user.uid === donation.donorId ? donation.requesterId : donation.donorId,
    targetDonationId: donationId,
    title: 'Donation correction or dispute',
    description: reason,
    category: typeof data.category === 'string' ? data.category.slice(0, 50) : null,
    status: 'pending',
    reportedAt: now(),
  });
  return { submitted: true };
}

async function acknowledgeDonation(db, identity, data) {
  const user = await actor(db, identity);
  const donationId = validateId(data?.donationId, 'donation ID');
  const ref = db.doc(`donations/${donationId}`);
  const result = await db.runTransaction(async (tx) => {
    const donation = (await tx.get(ref)).data();
    if (!donation || donation.donorId !== user.uid) {
      fail('permission-denied', 'Only the donor can acknowledge this donation.');
    }
    if (!donation.completedAt) fail('failed-precondition', 'The receiver must confirm first.');
    if (donation.disputed === true) fail('failed-precondition', 'This donation is under review.');
    if (donation.donorAcknowledgedAt) return { alreadyAcknowledged: true };
    const stamp = now();
    tx.update(ref, { donorAcknowledgedBy: user.uid, donorAcknowledgedAt: stamp });
    const auditRef = db.collection('audit_logs').doc();
    tx.create(auditRef, {
      action: 'donation_acknowledged',
      actorId: user.uid,
      recordId: donationId,
      createdAt: stamp,
    });
    return { acknowledged: true };
  });
  return result;
}

async function disputeDonation(db, identity, data) {
  const user = await actor(db, identity);
  const donationId = typeof data?.donationId === 'string' ? data.donationId : '';
  const reason = typeof data?.reason === 'string' ? data.reason.trim() : '';
  if (!donationId || !reason || reason.length > 1000) {
    fail('invalid-argument', 'Provide a reason up to 1000 characters.');
  }
  const ref = db.doc(`donations/${validateId(donationId, 'donation ID')}`);
  const donation = (await ref.get()).data();
  if (!donation || donation.donorId !== user.uid) {
    fail('permission-denied', 'Only the donor can dispute this donation.');
  }
  await rateLimit(db, `donation_dispute_${user.uid}`, 5);
  const reportRef = db.doc(`misuse_reports/donation_${donationId}_${user.uid}`);
  if ((await reportRef.get()).exists) return { alreadySubmitted: true };
  const stamp = now();
  await db.runTransaction(async (tx) => {
    const current = (await tx.get(ref)).data();
    if (!current || current.donorId !== user.uid) {
      fail('permission-denied', 'Only the donor can dispute this donation.');
    }
    if ((await tx.get(reportRef)).exists) return;
    tx.update(ref, {
      disputed: true,
      status: 'disputed',
      disputedBy: user.uid,
      disputedAt: stamp,
    });
    tx.create(reportRef, {
      reporterId: user.uid,
      reportedUserId: donation.requesterId || null,
      targetDonationId: donationId,
      title: 'Donation dispute',
      description: reason,
      category: typeof data.category === 'string' ? data.category.slice(0, 50) : null,
      status: 'pending',
      reportedAt: stamp,
    });
    tx.create(db.collection('audit_logs').doc(), {
      action: 'donation_disputed',
      actorId: user.uid,
      recordId: donationId,
      createdAt: stamp,
    });
  });
  return { disputed: true };
}

async function getDonorContact(db, identity) {
  await actor(db, identity);
  fail('permission-denied', 'Automatic phone disclosure is disabled. Use in-app communication.');
}

function closeRequest(db, identity, data) {
  actorId(identity);
  if (data?.status != null && data.status !== 'cancelled') {
    fail('invalid-argument', 'Only request cancellation is supported.');
  }
  return closeInternal(db, identity, data?.requestId);
}

async function expireOpenRequests(db) {
  let cursor = null;
  do {
    let query = db.collection('blood_requests')
      .where('status', 'in', OPEN_STATUSES)
      .orderBy('__name__')
      .limit(100);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    for (const doc of page.docs) {
      if (isExpired(doc.data())) await closeInternal(db, { uid: 'system' }, doc.id, true);
    }
    cursor = page.size === 100 ? page.docs.at(-1).id : null;
  } while (cursor);
}

export async function callWorkflow(name, identity, data, env) {
  const db = new FirestoreRestClient(env);
  switch (name) {
    case 'notifyChatMessage':
      return notifyChatMessage(db, env, identity, data);
    case 'markConversationRead':
      return markConversationRead(db, identity, data);
    case 'blockUser':
      return blockUser(db, identity, data);
    case 'unblockUser':
      return unblockUser(db, identity, data);
    case 'reportConversation':
      return reportConversation(db, identity, data);
    case 'sharePhoneNumber':
      return sharePhoneNumber(db, env, identity, data);
    case 'createSosAlert':
      return createSosAlert(db, env, identity, data);
    case 'getSos':
      return getSos(db, identity, data);
    case 'resolveSos':
      return resolveSos(db, identity, data);
    case 'confirmDonation':
      return confirmDonation(db, env, identity, data);
    case 'donationHistory':
      return donationHistory(db, identity, data);
    case 'acknowledgeDonation':
      return acknowledgeDonation(db, identity, data);
    case 'disputeDonation':
      return disputeDonation(db, identity, data);
    case 'submitDonationDispute':
      return submitDonationDispute(db, identity, data);
    case 'getDonorContact':
      return getDonorContact(db, identity);
    case 'createBloodRequest':
      return createBloodRequest(db, env, identity, data);
    case 'acceptDonation':
      return acceptDonation(db, identity, data);
    case 'declineRequest':
      return declineRequest(db, identity, data);
    case 'updateAssignment':
      return updateAssignment(db, identity, data);
    case 'closeRequest':
      return closeRequest(db, identity, data);
    case 'getRequest':
      return getRequest(db, identity, data);
    case 'discoverRequests':
      return discoverRequests(db, identity, data);
    case 'findDonors':
      return findDonors(db, identity, data);
    case 'notifyRequest':
      return notifyRequest(db, env, identity, data);
    default:
      fail('not-found', `Unsupported workflow: ${name}`);
  }
}

export async function expireOpenRequestsForWorker(env) {
  await expireOpenRequests(new FirestoreRestClient(env));
}
