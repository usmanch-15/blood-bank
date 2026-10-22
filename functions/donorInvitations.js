const admin = require('./firebaseAdmin');
const {HttpsError} = require('firebase-functions/v2/https');
const {actor, getRequest} = require('./requestWorkflows');
const {distanceKm} = require('./donationPolicy');
async function donorInvitations(request) {
  const user = await actor(request);
  if (!user.isDonor) throw new HttpsError('permission-denied','Donor account required.');
  let query = admin.firestore().collectionGroup('invites').where('donorId','==',user.uid)
    .where('status','==','invited').orderBy(admin.firestore.FieldPath.documentId()).limit(30);
  const cursor = request.data?.cursor;
  if (cursor != null) {
    if (typeof cursor !== 'string' || !/^blood_requests\/[^/]{1,128}\/invites\/[^/]{1,128}$/.test(cursor)) throw new HttpsError('invalid-argument','Invalid cursor.');
    query = query.startAfter(cursor);
  }
  const page = await query.get(), items = [];
  for (const doc of page.docs) {
    const parent = doc.ref.parent.parent;
    if (!parent || parent.parent.id !== 'blood_requests') continue;
    const requestId = parent.id;
    try {
      const item = await getRequest({...request, data:{requestId}});
      const location = (await parent.get()).data();
      if ([user.latitude,user.longitude,location?.latitude,location?.longitude].every(Number.isFinite)) {
        item.distanceKm = Math.round(distanceKm(user.latitude,user.longitude,location.latitude,location.longitude));
      }
      if (['pending','accepted','partially_fulfilled'].includes(item.status)) items.push(item);
    } catch (e) { if (!['not-found','permission-denied'].includes(e.code)) throw e; }
  }
  return {items, cursor:page.size === 30 ? page.docs.at(-1).ref.path : null};
}
module.exports = {donorInvitations};
