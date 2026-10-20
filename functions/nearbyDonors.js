const admin = require('./firebaseAdmin');
const {eligible, compatible, distanceKm} = require('./donationPolicy');
const {inPakistan} = require('./searchPolicy');
// Indexed latitude bounding band, then exact spherical distance filtering.
// Page through the band instead of loading the entire donor collection.
const MAX_SCAN_PAGES = 5;
const PAGE_SIZE = 200;
const DEFAULT_RESULT_LIMIT = 100;
async function nearbyDonorsPaged(lat, lng, bloodGroup, radiusKm, cursor = null, resultLimit = DEFAULT_RESULT_LIMIT) {
  if (!inPakistan(lat,lng)) return [];
  const delta = radiusKm / 110.574;
  const query = admin.firestore().collection('users')
    .where('isDonor','==',true).where('isAvailable','==',true)
    .where('status','==','approved').where('locationSharingEnabled','==',true)
    .where('latitude','>=',Math.max(-90,lat-delta)).where('latitude','<=',Math.min(90,lat+delta))
    .orderBy('latitude').orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE_SIZE);
  const matches=[];
  let last;
  let scannedPages = 0;
  if (cursor) { const [latitude, uid] = String(cursor).split('|'); last = {data:()=>({latitude:Number(latitude)}), id:uid}; }
  for (; scannedPages < MAX_SCAN_PAGES; scannedPages++) {
    const page = await (last ? query.startAfter(last.data().latitude, last.id) : query).get();
    for (const doc of page.docs) {
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
        if (matches.length >= Math.min(1000, Math.max(1, resultLimit))) break;
      }
    }
    if (matches.length >= Math.min(1000, Math.max(1, resultLimit)) || page.size<PAGE_SIZE) break;
    last=page.docs[page.size-1];
  }
  const nextCursor = last && scannedPages >= MAX_SCAN_PAGES ? `${last.data().latitude}|${last.id}` : null;
  return {matches, cursor:nextCursor, scannedPages};
}
async function nearbyDonors(lat, lng, bloodGroup, radiusKm) {
  const page = await nearbyDonorsPaged(lat,lng,bloodGroup,radiusKm,null,1000);
  return page.matches.map(m=>m.uid);
}
module.exports={nearbyDonors,nearbyDonorsPaged,MAX_SCAN_PAGES,PAGE_SIZE};
