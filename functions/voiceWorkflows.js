const {HttpsError} = require('firebase-functions/v2/https');
const {defineString, defineSecret} = require('firebase-functions/params');
const admin = require('./firebaseAdmin');
const {RtcRole, RtcTokenBuilder} = require('agora-token');
const {compatible, eligible, distanceKm} = require('./donationPolicy');

const {assignments, actionable} = require('./requestPolicy');
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
  const user = (await db.doc(`users/${uid}`).get()).data();
  if (user?.status !== 'approved') throw new HttpsError('permission-denied', 'Active account required.');
  if (!data) throw new HttpsError('not-found', 'Request not found.');
  if (!actionable(data)) throw new HttpsError('failed-precondition', 'Request is closed.');
  const commitments = assignments(data);
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
  const {data, donorIds} = await participantsFor(requestId, uid);
  const calleeUser = (await db.doc(`users/${calleeId}`).get()).data();
  const preAccept = uid === data.requesterId && calleeUser?.isDonor === true && calleeUser.status === 'approved' && calleeUser.isAvailable === true &&
    compatible(calleeUser.bloodGroup, data.bloodGroup) && eligible(calleeUser, Date.now()) && Number.isFinite(data.latitude) && Number.isFinite(data.longitude) && Number.isFinite(calleeUser.latitude) && Number.isFinite(calleeUser.longitude) && distanceKm(data.latitude, data.longitude, calleeUser.latitude, calleeUser.longitude) <= 1000;
  const participants = new Set([data.requesterId, ...donorIds]);
  if (!participants.has(calleeId) && !preAccept || (uid !== data.requesterId && calleeId !== data.requesterId)) {
    throw new HttpsError('permission-denied', 'Calls must connect the requester and an assigned donor.');
  }
  const activeCalls = await db.collection('callSessions').where('participantIds','array-contains',calleeId).where('status','in',['ringing','accepted']).limit(10).get();
  if (activeCalls.docs.some(d => d.data().expiresAt?.toMillis?.() > Date.now())) throw new HttpsError('resource-exhausted','This donor is currently busy on another call.');
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

async function inviteDonor(request) {
  const uid = caller(request), requestId = request.data?.requestId, donorId = request.data?.donorId;
  if (!validId(requestId) || !validId(donorId)) throw new HttpsError('invalid-argument', 'Request and donor are required.');
  const {data} = await participantsFor(requestId, uid);
  if (uid !== data.requesterId) throw new HttpsError('permission-denied', 'Only the requester can invite a donor.');
  if (data.reviewStatus && data.reviewStatus !== 'approved') throw new HttpsError('failed-precondition', 'This request is awaiting approved review.');
  const donorRef = db.doc(`users/${donorId}`), donorSnap = await donorRef.get(), donor = donorSnap.data();
  if (!donor || donor.status !== 'approved' || donor.isDonor !== true || donor.isAvailable !== true || !compatible(donor.bloodGroup, data.bloodGroup) || !eligible(donor, Date.now())) throw new HttpsError('failed-precondition', 'This donor is not currently eligible.');
  const ref = db.doc(`blood_requests/${requestId}`), inviteRef = ref.collection('invites').doc(donorId);
  const now = admin.firestore.Timestamp.now();
  try { await inviteRef.create({donorId, requesterId:uid, status:'invited', createdAt:now, updatedAt:now}); } catch (e) { if (e.code === 6) return {invited:true, alreadyInvited:true}; throw e; }
  await db.doc(`notifications/invite_${requestId}_${donorId}`).set({userId:donorId, relatedId:requestId, requestId, type:'donor_invite', title:'You were asked to donate', body:'A nearby blood request needs your response.', isRead:false, createdAt:now}, {merge:true});
  return {invited:true};
}

async function markDonorNotReady(request) {
  const uid = caller(request), requestId = request.data?.requestId, donorId = request.data?.donorId;
  if (!validId(requestId) || !validId(donorId)) throw new HttpsError('invalid-argument','Request and donor are required.');
  const {data} = await participantsFor(requestId, uid);
  if (uid !== data.requesterId || donorId === uid) throw new HttpsError('permission-denied','Only the request owner can mark a donor not ready.');
  const donor = (await db.doc(`users/${donorId}`).get()).data();
  if (!donor || donor.status !== 'approved' || donor.isDonor !== true || donor.isAvailable !== true ||
      !compatible(donor.bloodGroup, data.bloodGroup) || !eligible(donor, Date.now())) throw new HttpsError('failed-precondition','This donor is not a valid candidate.');
  const limitRef=db.doc(`rate_limits/not_ready_${uid}_${requestId}`), now=admin.firestore.Timestamp.now();
  const target=db.doc(`blood_requests/${requestId}/notReadyDonors/${donorId}`);
  await db.runTransaction(async tx=>{
    const [limit, existing, req]=await Promise.all([tx.get(limitRef),tx.get(target),tx.get(db.doc(`blood_requests/${requestId}`))]);
    const r=req.data(); if(!actionable(r) || r.requesterId!==uid) throw new HttpsError('failed-precondition','Request is closed or expired.');
    if(existing.exists) return;
    if(limit.exists && limit.data().until?.toMillis?.()>Date.now()) throw new HttpsError('resource-exhausted','Please wait before marking another donor.');
    tx.create(target,{donorId,requesterId:uid,createdAt:now});
    tx.set(limitRef,{until:admin.firestore.Timestamp.fromMillis(Date.now()+5000)},{merge:true});
  });
  return {marked:true};
}

async function getVoiceCallToken(request) {
  const uid = caller(request);
  const sessionId = request.data?.sessionId;
  if (!validId(sessionId)) throw new HttpsError('invalid-argument', 'Call session required.');
  const ref = db.doc(`callSessions/${sessionId}`);
  const snap = await ref.get();
  const data = snap.data();
  if (!data || !data.participantIds?.includes(uid)) throw new HttpsError('permission-denied', 'Call participants only.');
  for (const participant of data.participantIds) await participantsFor(data.requestId, participant);
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
    const user = (await tx.get(db.doc(`users/${uid}`))).data();
    if (user?.status !== 'approved') throw new HttpsError('permission-denied', 'Active account required.');
    if (!data || !data.participantIds?.includes(uid)) throw new HttpsError('permission-denied', 'Call participants only.');
    if (['accepted','rejected'].includes(status) && data.createdBy === uid) throw new HttpsError('permission-denied', 'Only the callee may answer or reject.');
    if (status === 'accepted') {
      const r = (await tx.get(db.doc(`blood_requests/${data.requestId}`))).data();
      const other = (await tx.get(db.doc(`users/${data.createdBy}`))).data();
      const donorId = data.participantIds.find(id => id !== r?.requesterId);
      if (other?.status !== 'approved' || !actionable(r) || data.expiresAt?.toMillis() <= Date.now() ||
          !['accepted','agreed','awaiting_confirmation'].includes(assignments(r)[donorId]?.status)) throw new HttpsError('failed-precondition','Call is no longer available.');
    }
    const allowed = {ringing: ['accepted', 'rejected', 'missed'], accepted: ['ended'], ended: [], rejected: [], missed: []};
    if (!allowed[data.status]?.includes(status)) throw new HttpsError('failed-precondition', 'Invalid call state transition.');
    const now = admin.firestore.Timestamp.now();
    tx.update(ref, {status, updatedAt: now, ...(status === 'accepted' ? {answeredBy: uid, answeredAt: now} : {}), ...(status === 'ended' ? {endedBy: uid, endedAt: now} : {})});
    return {updated: true, status};
  });
}

module.exports = {createVoiceCallSession, getVoiceCallToken, updateVoiceCallSession, inviteDonor, markDonorNotReady, agoraCertificate};
