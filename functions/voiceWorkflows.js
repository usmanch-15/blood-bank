const {HttpsError} = require('firebase-functions/v2/https');
const {defineString, defineSecret} = require('firebase-functions/params');
const admin = require('./firebaseAdmin');
const {RtcRole, RtcTokenBuilder} = require('agora-token');

const db = admin.firestore();
const agoraAppId = defineString('AGORA_APP_ID', {default: ''});
const agoraCertificate = defineSecret('AGORA_APP_CERTIFICATE');
const SESSION_TTL_SECONDS = 3600;

function caller(request) {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in first.');
  return request.auth.uid;
}

function validId(value) {
  return typeof value === 'string' && value.length > 0 && !value.includes('/');
}

async function participantsFor(requestId, uid) {
  if (!validId(requestId)) throw new HttpsError('invalid-argument', 'Request required.');
  const snap = await db.doc(`blood_requests/${requestId}`).get();
  const data = snap.data();
  if (!data) throw new HttpsError('not-found', 'Request not found.');
  const commitments = data.commitments || {};
  const donorIds = Object.keys(commitments).filter((id) =>
    ['accepted', 'agreed', 'awaiting_confirmation'].includes(commitments[id]?.status));
  const allowed = new Set([data.requesterId, ...donorIds]);
  if (!allowed.has(uid)) throw new HttpsError('permission-denied', 'Call participants only.');
  return {data, donorIds};
}

function configured() {
  const appId = agoraAppId.value();
  const certificate = agoraCertificate.value();
  if (!appId || !certificate) {
    throw new HttpsError('failed-precondition', 'Voice calling provider is not configured.');
  }
  return {appId, certificate};
}

function tokenFor(appId, certificate, channel, account) {
  const expires = Math.floor(Date.now() / 1000) + SESSION_TTL_SECONDS;
  const uid = numericUid(account);
  return {token: RtcTokenBuilder.buildTokenWithUid(appId, certificate, channel, uid, RtcRole.PUBLISHER, expires), uid};
}

function numericUid(account) {
  let hash = 2166136261;
  for (const char of account) hash = Math.imul(hash ^ char.charCodeAt(0), 16777619);
  return (hash >>> 0) || 1;
}

async function createVoiceCallSession(request) {
  const uid = caller(request);
  const requestId = request.data?.requestId;
  const calleeId = request.data?.calleeId;
  if (!validId(calleeId) || calleeId === uid) {
    throw new HttpsError('invalid-argument', 'A different call participant is required.');
  }
  const {data} = await participantsFor(requestId, uid);
  const participants = new Set([data.requesterId, ...Object.keys(data.commitments || {})]);
  if (!participants.has(calleeId) || (uid !== data.requesterId && calleeId !== data.requesterId)) {
    throw new HttpsError('permission-denied', 'Calls must connect the requester and an assigned donor.');
  }
  const {appId, certificate} = configured();
  const ref = db.collection('callSessions').doc();
  const channel = `blood_${requestId}_${ref.id}`;
  const now = admin.firestore.Timestamp.now();
  await ref.create({
    requestId,
    participantIds: [uid, calleeId],
    channel,
    status: 'ringing',
    createdBy: uid,
    createdAt: now,
    updatedAt: now,
    expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + SESSION_TTL_SECONDS * 1000),
  });
  await db.doc(`notifications/call_${ref.id}`).create({
    userId: calleeId,
    title: 'Incoming blood-request call',
    body: 'A participant is calling about your accepted blood request.',
    type: 'incoming_call',
    relatedId: ref.id,
    requestId,
    isRead: false,
    createdAt: now,
  });
  const issued = tokenFor(appId, certificate, channel, uid);
  return {sessionId: ref.id, appId, channel, token: issued.token, uid: issued.uid, status: 'ringing'};
}

async function getVoiceCallToken(request) {
  const uid = caller(request);
  const sessionId = request.data?.sessionId;
  if (!validId(sessionId)) throw new HttpsError('invalid-argument', 'Call session required.');
  const ref = db.doc(`callSessions/${sessionId}`);
  const snap = await ref.get();
  const data = snap.data();
  if (!data || !data.participantIds?.includes(uid)) throw new HttpsError('permission-denied', 'Call participants only.');
  if (!['ringing', 'accepted'].includes(data.status) || data.expiresAt?.toMillis() < Date.now()) {
    throw new HttpsError('failed-precondition', 'Call session is no longer active.');
  }
  const {appId, certificate} = configured();
  const issued = tokenFor(appId, certificate, data.channel, uid);
  return {sessionId, appId, channel: data.channel, token: issued.token, uid: issued.uid, status: data.status};
}

async function updateVoiceCallSession(request) {
  const uid = caller(request);
  const sessionId = request.data?.sessionId;
  const status = request.data?.status;
  if (!validId(sessionId) || !['accepted', 'rejected', 'ended', 'missed'].includes(status)) {
    throw new HttpsError('invalid-argument', 'Valid call session and status required.');
  }
  const ref = db.doc(`callSessions/${sessionId}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    if (!data || !data.participantIds?.includes(uid)) throw new HttpsError('permission-denied', 'Call participants only.');
    const allowed = {ringing: ['accepted', 'rejected', 'missed'], accepted: ['ended'], ended: [], rejected: [], missed: []};
    if (!allowed[data.status]?.includes(status)) throw new HttpsError('failed-precondition', 'Invalid call state transition.');
    const now = admin.firestore.Timestamp.now();
    tx.update(ref, {status, updatedAt: now, ...(status === 'accepted' ? {answeredBy: uid, answeredAt: now} : {}), ...(status === 'ended' ? {endedBy: uid, endedAt: now} : {})});
    return {updated: true, status};
  });
}

module.exports = {createVoiceCallSession, getVoiceCallToken, updateVoiceCallSession, agoraCertificate};
