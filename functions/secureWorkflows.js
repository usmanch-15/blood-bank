const { HttpsError } = require('firebase-functions/v2/https');
const admin = require('./firebaseAdmin');
const { active, eligible, compatible, INTERVAL_MS, POINTS } = require('./donationPolicy');
const db = admin.firestore();
const {checkSosRateLimit} = require('./rateLimiter');
const fail = (code, message) => { throw new HttpsError(code, message); };
function id(value) {
  if (typeof value !== 'string' || !value.length || value.length > 128 || value.includes('/')) {
    fail('invalid-argument', 'A valid document identifier is required.');
  }
  return value;
}
function caller(request) {
  if (!request.auth) fail('unauthenticated', 'Please sign in.');
  return request.auth.uid;
}
async function acceptDonation(request) {
  const uid = caller(request);
  const requestId = id(request.data?.requestId);
  const ref = db.collection('blood_requests').doc(requestId);
  return db.runTransaction(async tx => {
    const [req, donor] = await Promise.all([tx.get(ref), tx.get(db.doc(`users/${uid}`))]);
    const d = donor.data(), r = req.data();
    if (!active(d) || d.isDonor !== true || !d.isAvailable) fail('permission-denied', 'An active, available donor account is required.');
    if (!r || r.requesterId === uid) fail('permission-denied', 'You cannot accept this request.');
    if (!active((await tx.get(db.doc(`users/${r.requesterId}`))).data())) fail('permission-denied', 'The request owner is inactive.');
    if (r.status === 'accepted' && r.acceptedDonorId === uid) return { accepted: true };
    if (r.status !== 'pending') fail('failed-precondition', 'This request is no longer open.');
    if (!eligible(d, Date.now()) || !compatible(d.bloodGroup, r.bloodGroup)) fail('failed-precondition', 'Donor does not meet the matching and interval requirements.');
    tx.update(ref, {status: 'accepted', acceptedDonorId: uid, acceptedAt: admin.firestore.Timestamp.now()});
    tx.set(db.doc(`notifications/accepted_${requestId}`), {
      userId: r.requesterId, title: 'Donor accepted your request',
      body: `${d.name || 'A donor'} accepted your blood request. Open Find Donors to arrange the donation.`,
      type: 'general', relatedId: requestId, isRead: false, createdAt: admin.firestore.Timestamp.now(),
    });
    return {accepted: true};
  });
}
async function createSosAlert(request) {
  const uid = caller(request);
  const data = request.data || {};
  const user = (await db.doc(`users/${uid}`).get()).data();
  if (!active(user) || user.isReceiver !== true) fail('permission-denied','An active receiver account is required.');
  if (!Number.isFinite(data.latitude) || Math.abs(data.latitude)>90 ||
      !Number.isFinite(data.longitude) || Math.abs(data.longitude)>180 ||
      !['A+','A-','B+','B-','AB+','AB-','O+','O-'].includes(data.bloodGroup) ||
      !['urgent','critical','life_threatening'].includes(data.urgency)) {
    fail('invalid-argument','Select a blood group, emergency level and valid location.');
  }
  if (!await checkSosRateLimit(uid)) fail('resource-exhausted','SOS limit reached. Try again later or contact emergency services.');
  const ref = db.collection('sosRequests').doc();
  await ref.set({id:ref.id,receiverId:uid,bloodGroup:data.bloodGroup,
    latitude:data.latitude,longitude:data.longitude,urgency:data.urgency,
    triggerTime:admin.firestore.Timestamp.now(),isResolved:false,status:'queued'});
  return {id:ref.id};
}
async function confirmDonation(request) {
  const uid = caller(request);
  const requestId = id(request.data?.requestId), donorId = id(request.data?.donorId);
  const requestRef = db.doc(`blood_requests/${requestId}`);
  const donorRef = db.doc(`users/${donorId}`);
  // One donation per request; retrying a completed request returns the same record.
  const donationRef = db.doc(`donations/${requestId}`);
  return db.runTransaction(async tx => {
    const [req, donor, user, donation] = await Promise.all([
      tx.get(requestRef), tx.get(donorRef), tx.get(db.doc(`users/${uid}`)), tx.get(donationRef),
    ]);
    const r=req.data(), d=donor.data();
    if (!active(user.data()) || !active(d) || d.isDonor !== true || !r ||
        ![donorId, r.requesterId].includes(uid) || r.acceptedDonorId !== donorId) {
      fail('permission-denied', 'Only the assigned donor or request owner can confirm.');
    }
    if (!active((await tx.get(db.doc(`users/${r.requesterId}`))).data())) fail('permission-denied', 'The request owner is inactive.');
    if (donation.exists) return {donationId: donation.id, alreadyConfirmed: true};
    if (r.status !== 'accepted') fail('failed-precondition', 'The request must be accepted before confirmation.');
    const now = admin.firestore.Timestamp.now();
    if (!eligible(d, now.toMillis())) fail('failed-precondition', 'A minimum of 90 days is required between donations.');
    if (!compatible(d.bloodGroup, r.bloodGroup)) fail('failed-precondition', 'Blood groups are incompatible.');
    const nextEligible = admin.firestore.Timestamp.fromMillis(now.toMillis()+INTERVAL_MS);
    tx.create(donationRef, {donorId, donorName: d.name || '', bloodGroup: d.bloodGroup,
      donationDate: now, location: r.hospitalName || null, requestId,
      pointsEarned: POINTS, confirmedBy: uid});
    tx.update(donorRef, {lastDonationDate: now, nextEligibleDate: nextEligible,
      isEligible: false, rewardPoints: admin.firestore.FieldValue.increment(POINTS)});
    tx.update(requestRef, {status: 'fulfilled', fulfilledAt: now, fulfilledByDonorId: donorId});
    tx.create(db.doc(`notifications/donation_${requestId}`), {userId: donorId,
      title: 'Donation confirmed', body: `Thank you for donating. You earned ${POINTS} points.`,
      type: 'donation_confirmed', relatedId: requestId, createdAt: now, isRead: false});
    tx.create(db.doc(`notifications/fulfilled_${requestId}`), {userId: r.requesterId,
      title: 'Blood request fulfilled', body: 'The donation has been confirmed and your request is fulfilled.',
      type: 'general', relatedId: requestId, createdAt: now, isRead: false});
    return {donationId: donationRef.id, nextEligibleDate: nextEligible.toMillis()};
  });
}
async function deleteQuery(query) {
  for (;;) {
    const page = await query.limit(200).get();
    if (page.empty) return;
    const batch = db.batch();
    page.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  }
}
async function deleteAccount(request, adminAction = false) {
  const actor = caller(request);
  const actorData = (await db.doc(`users/${actor}`).get()).data();
  if (adminAction && (!active(actorData) || actorData.role !== 'admin')) fail('permission-denied', 'Administrator access required.');
  const uid = adminAction ? id(request.data?.uid) : actor;
  if (adminAction && uid === actor) fail('failed-precondition', 'Use account settings to delete your own account.');
  if (!adminAction && Date.now()/1000 - (request.auth.token.auth_time || 0) > 300) {
    fail('failed-precondition', 'Sign in again before deleting your account.');
  }
  // Deny all new client activity first. Every cleanup step can be retried.
  await db.doc(`users/${uid}`).set({status: 'deleted', isAvailable: false}, {merge: true});
  for (const [collection, field] of [
    ['notifications','userId'], ['blood_requests','requesterId'], ['sosRequests','receiverId'],
    ['donations','donorId'], ['rewards','donorId'], ['reports','reportedBy'],
    ['misuse_reports','reporterId'], ['misuse_reports','reportedUserId'], ['audit_logs','viewedBy'], ['audit_logs','donorId'],
  ]) await deleteQuery(db.collection(collection).where(field,'==',uid));
  // Remove assignment references on other people's still-open requests.
  for (;;) {
    const page = await db.collection('blood_requests').where('acceptedDonorId','==',uid).limit(200).get();
    if (page.empty) break;
    const batch = db.batch();
    page.docs.forEach(doc => batch.update(doc.ref, {acceptedDonorId: admin.firestore.FieldValue.delete(),
      ...(doc.data().status === 'accepted' ? {status:'pending'} : {})}));
    await batch.commit();
  }
  await db.doc(`rate_limits/${uid}`).delete();
  await db.doc(`rate_limits/contact_${uid}`).delete();
  await admin.storage().bucket().deleteFiles({prefix: `profile_images/${uid}/`});
  await admin.storage().bucket().deleteFiles({prefix: `certificates/${uid}/`});
  await db.recursiveDelete(db.doc(`users/${uid}`));
  try { await admin.auth().deleteUser(uid); }
  catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  return {deleted: true};
}
module.exports = {acceptDonation, confirmDonation, deleteAccount, createSosAlert};
