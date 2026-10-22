const {HttpsError} = require('firebase-functions/v2/https');
const admin = require('./firebaseAdmin');
const {actor} = require('./requestWorkflows');
const {validateBanner, visibleBanner} = require('./bannerPolicy');
const db = admin.firestore();
const validId = v => typeof v === 'string' && /^[a-zA-Z0-9_-]{1,128}$/.test(v);
async function manageAwarenessBanner(request) {
  const user = await actor(request);
  if (user.role !== 'admin') throw new HttpsError('permission-denied', 'Administrator required.');
  const d = request.data || {};
  if (d.id && !validId(d.id)) throw new HttpsError('invalid-argument', 'Invalid banner.');
  let banner;
  try { banner = validateBanner(d); } catch (e) { throw new HttpsError('invalid-argument', e.message); }
  const ref = d.id ? db.doc(`awareness_banners/${d.id}`) : db.collection('awareness_banners').doc();
  await db.runTransaction(async tx => {
    const previous = await tx.get(ref);
    tx.set(ref, {...banner, revision: (previous.data()?.revision || 0) + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp(), updatedBy: user.uid}, {merge:true});
    tx.create(db.collection('audit_logs').doc(), {actorId:user.uid, action:'awareness_banner_saved', targetId:ref.id, createdAt:admin.firestore.FieldValue.serverTimestamp()});
  });
  return {id:ref.id};
}
async function donorAwarenessBanners(request) {
  const user = await actor(request);
  if (user.role !== 'donor' || !user.isDonor) return {items:[]};
  const snap = await db.collection('awareness_banners').where('active','==',true).get();
  const items = snap.docs.map(doc => ({...doc.data(), id:doc.id})).filter(b => visibleBanner(b, Date.now()))
    .sort((a,b) => b.priority - a.priority).slice(0, 5)
    .map(({id,en,ur,action,imageUrl,revision}) => ({id,en,ur,action,imageUrl,revision}));
  return {items};
}
async function recordBannerEvent(request) {
  const user = await actor(request), d = request.data || {};
  if (user.role !== 'donor' || !user.isDonor) throw new HttpsError('permission-denied','Donor mode required.');
  if (!validId(d.id) || !['view','click'].includes(d.event)) throw new HttpsError('invalid-argument','Invalid event.');
  const ref = db.doc(`awareness_banners/${d.id}`);
  return db.runTransaction(async tx => {
    const b = (await tx.get(ref)).data();
    if (!b || !visibleBanner(b,Date.now()) || b.revision !== d.revision) return {recorded:false};
    const eventRef = ref.collection('events').doc(`${user.uid}_${b.revision}_${d.event}`);
    if ((await tx.get(eventRef)).exists) return {recorded:false};
    tx.create(eventRef, {createdAt:admin.firestore.FieldValue.serverTimestamp()});
    tx.update(ref, {[d.event === 'view' ? 'views' : 'clicks']:admin.firestore.FieldValue.increment(1)});
    return {recorded:true};
  });
}
module.exports = {manageAwarenessBanner, donorAwarenessBanners, recordBannerEvent};
