const admin = require('./firebaseAdmin');
const {eligible, compatible, distanceKm} = require('./donationPolicy');
// Indexed latitude bounding band, then exact spherical distance filtering.
// Page through the band instead of loading the entire donor collection.
async function nearbyDonors(lat, lng, bloodGroup, radiusKm) {
  if (!Number.isFinite(lat) || Math.abs(lat)>90 || !Number.isFinite(lng) || Math.abs(lng)>180) return [];
  const delta = radiusKm / 110.574;
  const query = admin.firestore().collection('users')
    .where('isDonor','==',true).where('isAvailable','==',true)
    .where('status','==','approved').where('locationSharingEnabled','==',true)
    .where('latitude','>=',Math.max(-90,lat-delta)).where('latitude','<=',Math.min(90,lat+delta))
    .orderBy('latitude').limit(200);
  const matches=[];
  let last;
  for (;;) {
    const page = await (last ? query.startAfter(last) : query).get();
    for (const doc of page.docs) {
      const d=doc.data();
      if (Number.isFinite(d.longitude) && compatible(d.bloodGroup,bloodGroup) && eligible(d,Date.now()) &&
          distanceKm(lat,lng,d.latitude,d.longitude)<=radiusKm) matches.push(doc.id);
    }
    if (page.size<200) break;
    last=page.docs[page.size-1];
  }
  return matches;
}
module.exports={nearbyDonors};
