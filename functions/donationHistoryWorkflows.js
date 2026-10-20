const {HttpsError}=require('firebase-functions/v2/https');
const admin=require('./firebaseAdmin');
const {actor,rateLimit}=require('./requestWorkflows');
const db=admin.firestore();
function donationTimelineLabel(d){
  if(d.disputed===true||d.status==='disputed') return 'disputed';
  if(['cancelled','withdrawn','released'].includes(d.status)) return 'cancelled';
  if(d.completedAt||d.status==='completed') return 'completed';
  if(d.acceptedAt||d.status==='accepted') return 'accepted';
  return 'proposed';
}
async function donationHistory(request){
  const user=await actor(request), page=Math.min(Math.max(Number(request.data?.limit)||30,1),50);
  const field=user.role==='receiver'?'requesterId':'donorId';
  const snap=await db.collection('donations').where(field,'==',user.uid).orderBy('donationDate','desc').limit(page).get();
  return {items:snap.docs.map(x=>({id:x.id,...x.data(),statusLabel:donationTimelineLabel(x.data()),phoneNumber:undefined,privateContact:undefined})),hasMore:snap.size===page};
}
async function submitDonationDispute(request){
  const user=await actor(request),d=request.data||{},id=d.donationId,reason=typeof d.reason==='string'?d.reason.trim():'';
  if(!id||!reason||reason.length>1000) throw new HttpsError('invalid-argument','Provide a donation and a reason up to 1000 characters.');
  const snap=await db.doc(`donations/${id}`).get(), donation=snap.data();
  if(!donation||(donation.donorId!==user.uid&&donation.requesterId!==user.uid)) throw new HttpsError('permission-denied','Donation unavailable.');
  await rateLimit(`donation_dispute_${user.uid}`,5); const report=db.doc(`misuse_reports/donation_${id}_${user.uid}`);
  if((await report.get()).exists) return {alreadySubmitted:true};
  await report.create({reporterId:user.uid,reportedUserId:user.uid===donation.donorId?donation.requesterId:donation.donorId,targetDonationId:id,title:'Donation correction or dispute',description:reason,category:typeof d.category==='string'?d.category.slice(0,50):null,status:'pending',reportedAt:admin.firestore.Timestamp.now()});
  return {submitted:true};
}
async function acknowledgeDonation(request){
  const user=await actor(request),id=request.data?.donationId,ref=db.doc(`donations/${id}`),snap=await ref.get(),d=snap.data();
  if(!d||d.donorId!==user.uid) throw new HttpsError('permission-denied','Only the donor can acknowledge this donation.');
  if(!d.completedAt) throw new HttpsError('failed-precondition','The receiver must confirm first.');
  if(d.disputed===true) throw new HttpsError('failed-precondition','This donation is under review.');
  if(d.donorAcknowledgedAt) return {alreadyAcknowledged:true};
  const now=admin.firestore.Timestamp.now(); await ref.update({donorAcknowledgedBy:user.uid,donorAcknowledgedAt:now}); await db.collection('audit_logs').add({action:'donation_acknowledged',actorId:user.uid,recordId:id,createdAt:now}); return {acknowledged:true};
}
async function disputeDonation(request){
  const user=await actor(request),d=request.data||{},id=d.donationId,reason=typeof d.reason==='string'?d.reason.trim():'';
  if(!id||!reason||reason.length>1000) throw new HttpsError('invalid-argument','Provide a reason up to 1000 characters.');
  const ref=db.doc(`donations/${id}`),snap=await ref.get(),donation=snap.data();
  if(!donation||donation.donorId!==user.uid) throw new HttpsError('permission-denied','Only the donor can dispute this donation.');
  await rateLimit(`donation_dispute_${user.uid}`,5); const report=db.doc(`misuse_reports/donation_${id}_${user.uid}`); if((await report.get()).exists) return {alreadySubmitted:true};
  const now=admin.firestore.Timestamp.now(); await db.runTransaction(async tx=>{tx.update(ref,{disputed:true,status:'disputed',disputedBy:user.uid,disputedAt:now});tx.create(report,{reporterId:user.uid,reportedUserId:donation.requesterId||null,targetDonationId:id,title:'Donation dispute',description:reason,category:typeof d.category==='string'?d.category.slice(0,50):null,status:'pending',reportedAt:now});tx.create(db.collection('audit_logs').doc(),{action:'donation_disputed',actorId:user.uid,recordId:id,createdAt:now});});
  return {disputed:true};
}
module.exports={donationHistory,submitDonationDispute,acknowledgeDonation,disputeDonation,donationTimelineLabel};
