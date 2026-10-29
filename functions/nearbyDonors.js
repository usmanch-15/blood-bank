const admin = require('./firebaseAdmin');
const {eligible, compatible, distanceKm} = require('./donationPolicy');
const {inPakistan} = require('./searchPolicy');
// Indexed latitude bounding band, then exact spherical distance filtering.
// Page through the band instead of loading the entire donor collection.
const MAX_SCAN_PAGES = 5;
const PAGE_SIZE = 200;
const DEFAULT_RESULT_LIMIT = 100;
async function nearbyDonorsPaged(lat, lng, bloodGroup, radiusKm, cursor = null, resultLimit = DEFAULT_RESULT_LIMIT) {
  if (!inPakistan(lat,lng)) return {matches:[], cursor:null, scannedPages:0};
  const delta = radiusKm / 110.574;
  const query = admin.firestore().collection('users')
    .where('isDonor','==',true).where('isAvailable','==',true)
    .where('status','==','approved').where('locationSharingEnabled','==',true)
    .where('latitude','>=',Math.max(-90,lat-delta)).where('latitude','<=',Math.min(90,lat+delta))
    .orderBy('latitude').orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE_SIZE);
  const matches=[];
  let last;
  let scannedPages = 0;
  let hasMore = false;
  const limit = Math.min(1000, Math.max(1, resultLimit));
  if (cursor != null) {
    const parts = typeof cursor === 'string' ? cursor.split('|') : [];
    const [latitude, uid] = parts;
    if (parts.length !== 2 || !latitude.trim() || !uid || ['.','..'].includes(uid) || uid.includes('/') || uid.length > 128 ||
        !Number.isFinite(Number(latitude)) || Number(latitude) < Math.max(-90, lat-delta) ||
        Number(latitude) > Math.min(90, lat+delta)) {
      throw new (require('firebase-functions/v2/https').HttpsError)('invalid-argument','Invalid search cursor.');
    }
    last = {data:()=>({latitude:Number(latitude)}), id:uid};
  }
  while (scannedPages < MAX_SCAN_PAGES) {
    const page = await (last ? query.startAfter(last.data().latitude, last.id) : query).get();
    scannedPages++;
    hasMore = page.size === PAGE_SIZE;
    for (const [index, doc] of page.docs.entries()) {
      last = doc;
      const d=doc.data();
      let stale = false;
      if (d.activeRequestId) {
        const active = (await admin.firestore().doc(`blood_requests/${d.activeRequestId}`).get()).data();
        stale = !active || !['pending','accepted','partially_fulfilled'].includes(active.status) ||
          (active.requiredBy?.toMillis && active.requiredBy.toMillis() <= Date.now());
        if (stale) await doc.ref.update({activeRequestId:admin.firestore.FieldValue.delete()});
      }
      const complete = typeof d.name === 'string' && d.name.trim().length >= 2 &&
        typeof d.bloodGroup === 'string' && Number.isFinite(d.latitude) && Number.isFinite(d.longitude);
      if (inPakistan(d.latitude,d.longitude) && complete && (!bloodGroup || compatible(d.bloodGroup,bloodGroup)) && eligible(d,Date.now()) && d.isEligible !== false && (!d.activeRequestId || stale) &&
        distanceKm(lat,lng,d.latitude,d.longitude)<=radiusKm) {
        matches.push({uid:doc.id, data:d, distanceKm:distanceKm(lat,lng,d.latitude,d.longitude)});
        if (matches.length >= limit) {
          hasMore = index < page.size - 1 || page.size === PAGE_SIZE;
          break;
        }
      }
    }
    if (matches.length >= limit || page.size<PAGE_SIZE) break;
  }
  const nextCursor = last && hasMore ? `${last.data().latitude}|${last.id}` : null;
  return {matches, cursor:nextCursor, scannedPages};
}
async function nearbyDonors(lat, lng, bloodGroup, radiusKm) {
  const page = await nearbyDonorsPaged(lat,lng,bloodGroup,radiusKm,null,1000);
  return page.matches.map(m=>m.uid);
}
module.exports={nearbyDonors,nearbyDonorsPaged,MAX_SCAN_PAGES,PAGE_SIZE};
