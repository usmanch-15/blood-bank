const { HttpsError } = require('firebase-functions/v2/https');
const admin = require('./firebaseAdmin');
const { active } = require('./donationPolicy');
const db = admin.firestore();

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
async function deleteQuery(query) {
  for (;;) {
    const page = await query.limit(200).get();
    if (page.empty) return;
    const batch = db.batch();
    for (const doc of page.docs) { if(doc.ref.parent.id==='blood_requests') await db.recursiveDelete(doc.ref); else batch.delete(doc.ref); }
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
  // Release every active commitment before deleting the donor profile.
  const requests=await db.collection('blood_requests').where('acceptedDonorIds','array-contains',uid).get();
  for (const doc of requests.docs) {
    await db.runTransaction(async tx=>{
      const snap=await tx.get(doc.ref),r=snap.data();
      const commitments={...(r.commitments || {})};delete commitments[uid];
      const ids=(r.acceptedDonorIds || []).filter(k=>k!==uid);
      tx.update(doc.ref,{commitments,acceptedDonorIds:ids,participantIds:(r.participantIds || []).filter(k=>k!==uid),...(require('./requestWorkflows').openStatuses.includes(r.status)?{status:r.donatedUnits?'partially_fulfilled':ids.length?'accepted':'pending'}:{})});
    });
  }
  const completed=await db.collection('blood_requests').where('participantIds','array-contains',uid).get();
  for(const doc of completed.docs){await doc.ref.update({participantIds:admin.firestore.FieldValue.arrayRemove(uid),[`commitments.${uid}`]:admin.firestore.FieldValue.delete()});}
  await deleteQuery(db.collection('feedback').where('reporterId','==',uid));
  await db.doc(`rate_limits/${uid}`).delete();
  await db.doc(`rate_limits/contact_${uid}`).delete();
  await admin.storage().bucket().deleteFiles({prefix: `profile_images/${uid}/`});
  await admin.storage().bucket().deleteFiles({prefix: `certificates/${uid}/`});
  await db.recursiveDelete(db.doc(`users/${uid}`));
  try { await admin.auth().deleteUser(uid); }
  catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  if(adminAction) await db.collection('audit_logs').add({action:'admin_delete_account',actorId:actor,recordId:uid,createdAt:admin.firestore.Timestamp.now()});
  return {deleted: true};
}
module.exports = {deleteAccount, ...require('./requestWorkflows')};
