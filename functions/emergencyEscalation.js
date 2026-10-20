const admin = require('./firebaseAdmin');
const db = admin.firestore();
const HOURS = Number(process.env.EMERGENCY_REVIEW_ESCALATION_HOURS || 2);

async function escalatePendingEmergencyReviews() {
  const cutoff = Date.now() - HOURS * 3600000;
  const snap = await db.collection('blood_requests').where('reviewStatus','==','pending_review').limit(200).get();
  const admins = (await db.collection('users').where('role','==','admin').where('status','==','approved').get()).docs;
  for (const doc of snap.docs) {
    const r = doc.data();
    if (!['urgent','critical','life_threatening'].includes(r.urgency)) continue;
    const created = r.createdAt?.toMillis ? r.createdAt.toMillis() : Number(r.createdAt || 0);
    if (!created || created > cutoff) continue;
    for (const adminDoc of admins) {
      const ref = db.doc(`notifications/emergency_escalation_${doc.id}_${adminDoc.id}`);
      try {
        await ref.create({userId:adminDoc.id, relatedId:doc.id, type:'request_review', title:'Emergency request needs review', body:'An urgent request is awaiting admin review.', isRead:false, createdAt:admin.firestore.Timestamp.now()});
      } catch (e) {
        if (e.code !== 6) throw e;
      }
    }
  }
}

module.exports = {escalatePendingEmergencyReviews, EMERGENCY_REVIEW_ESCALATION_HOURS:HOURS};
