const {HttpsError} = require('firebase-functions/v2/https');
const admin = require('./firebaseAdmin');
const db = admin.firestore();
const {actionable} = require('./requestPolicy');
const workflows = require('./requestWorkflows');
const {nearbyDonors} = require('./nearbyDonors');
const {radiusKm} = require('./searchPolicy');
async function notifyRequest(request) {
  if (!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const requestId = request.data?.requestId;
  if (typeof requestId !== 'string' || !requestId.length || requestId.length>128 || requestId.includes('/')) throw new HttpsError('invalid-argument','Request required.');
  const ref = db.doc(`blood_requests/${requestId}`);
  const [req, user] = await Promise.all([ref.get(), db.doc(`users/${request.auth.uid}`).get()]);
  const r=req.data();
  if (!r || r.requesterId !== request.auth.uid || user.data()?.status !== 'approved' || !actionable(r)) {
    throw new HttpsError('permission-denied','An active request belonging to you is required.');
  }
  let radius;
  try { radius = radiusKm(request.data?.radiusKm); }
  catch (_) { throw new HttpsError('invalid-argument','Invalid search radius.'); }
  const requested = request.data.userIds;
  if (requested != null && (!Array.isArray(requested) || requested.length>1000 || requested.some(uid=>typeof uid!=='string'))) {
    throw new HttpsError('invalid-argument','Select at most 1000 donors per notification request.');
  }
  await workflows.rateLimit(`notify_${request.auth.uid}`,20);
  const ids = await nearbyDonors(r.latitude,r.longitude,r.bloodGroup,radius);
  const pending = ids.filter(uid => uid !== request.auth.uid && !(r.notifiedDonors || []).includes(uid) &&
    (!Array.isArray(requested) || requested.includes(uid)));
  const recipients = pending.slice(0,200);
  for (const uid of recipients) {
    try {
      await db.doc(`notifications/request_${requestId}_${uid}`).create({
        userId:uid, title:'Blood donation request', body:'A matching request is available. Open the app for details.',
        type:'blood_request',relatedId:requestId,isRead:false,createdAt:admin.firestore.Timestamp.now(),
      });
    } catch(e) { if(e.code !== 6) throw e; }
  }
  if (recipients.length) await ref.update({notifiedDonors: admin.firestore.FieldValue.arrayUnion(...recipients)});
  return {count:recipients.length,remaining:Math.max(0,pending.length-recipients.length)};
}

module.exports = {notifyRequest};
