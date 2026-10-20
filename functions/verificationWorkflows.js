const {HttpsError}=require('firebase-functions/v2/https');
const admin=require('./firebaseAdmin');
const {actor,rateLimit}=require('./requestWorkflows');
const db=admin.firestore();
const EXPIRY_DAYS=Number(process.env.VERIFIED_PROFILE_EXPIRY_DAYS||365);
async function submitVerification(request){
  const user=await actor(request); if(!user.isDonor) throw new HttpsError('permission-denied','Donor account required.');
  await rateLimit(`verification_${user.uid}`,3); const ref=db.doc(`verification_requests/${user.uid}`), existing=await ref.get();
  if(existing.exists&&['pending','approved','more_info_needed'].includes(existing.data().status)) throw new HttpsError('already-exists','A verification request is already open.');
  const evidence=typeof request.data?.evidencePath==='string'?request.data.evidencePath:'';
  if(!evidence.startsWith(`verification_evidence/${user.uid}/`)) throw new HttpsError('invalid-argument','Evidence must use the restricted path.');
  await ref.set({userId:user.uid,status:'pending',evidencePath:evidence,submittedAt:admin.firestore.Timestamp.now()},{merge:true}); return {submitted:true};
}
async function reviewVerification(request){
  const user=await actor(request),d=request.data||{}; if(user.role!=='admin') throw new HttpsError('permission-denied','Administrator required.');
  if(!['approved','rejected','more_info_needed'].includes(d.decision)||typeof d.note!=='string'||!d.note.trim()||d.note.length>2000) throw new HttpsError('invalid-argument','Decision and review note are required.');
  const ref=db.doc(`verification_requests/${d.userId}`), now=admin.firestore.Timestamp.now(); const updates={status:d.decision,reviewerId:user.uid,reviewNote:d.note.trim(),reviewedAt:now};
  if(d.decision==='approved') updates.expiresAt=admin.firestore.Timestamp.fromMillis(Date.now()+EXPIRY_DAYS*86400000);
  await db.runTransaction(async tx=>{tx.update(ref,updates);tx.update(db.doc(`users/${d.userId}`),{profileVerificationStatus:d.decision,profileVerified:d.decision==='approved',profileVerifiedUntil:updates.expiresAt||null});tx.create(db.collection('audit_logs').doc(),{action:`verification_${d.decision}`,actorId:user.uid,recordId:d.userId,createdAt:now,note:d.note.trim()});tx.create(db.collection('notifications').doc(`verification_${d.userId}_${now.toMillis()}`),{userId:d.userId,type:'verification_decision',relatedId:d.userId,title:'Profile verification updated',body:'Your profile verification status was updated. Open the app for details.',isRead:false,createdAt:now});});
  return {updated:true};
}
async function revokeVerification(request){
  const user=await actor(request),d=request.data||{}; if(user.role!=='admin'||typeof d.userId!=='string'||typeof d.reason!=='string'||!d.reason.trim()) throw new HttpsError('permission-denied','Administrator and a reason are required.');
  const now=admin.firestore.Timestamp.now(); await db.doc(`users/${d.userId}`).update({profileVerificationStatus:'revoked',profileVerified:false,profileVerifiedUntil:null}); await db.doc(`verification_requests/${d.userId}`).set({status:'revoked',reviewerId:user.uid,reviewNote:d.reason.trim(),reviewedAt:now},{merge:true}); await db.collection('audit_logs').add({action:'verification_revoked',actorId:user.uid,recordId:d.userId,createdAt:now,note:d.reason.trim()}); return {revoked:true};
}
module.exports={submitVerification,reviewVerification,revokeVerification,EXPIRY_DAYS};
