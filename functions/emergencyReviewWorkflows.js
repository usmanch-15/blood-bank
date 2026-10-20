const {HttpsError}=require('firebase-functions/v2/https');
const admin=require('./firebaseAdmin');
const {actor,rateLimit}=require('./requestWorkflows');
const db=admin.firestore();
const PENDING_REVIEW_ESCALATION_HOURS=Number(process.env.EMERGENCY_REVIEW_ESCALATION_HOURS||2);
const LIMITED_DISCLOSURE_PENDING=true;
async function reviewEmergencyRequest(request){
  const user=await actor(request),d=request.data||{};
  if(user.role!=='admin') throw new HttpsError('permission-denied','Administrator required.');
  if(!['approved','rejected','flagged','clarification'].includes(d.decision)||typeof d.note!=='string'||!d.note.trim()) throw new HttpsError('invalid-argument','Decision and note are required.');
  const collection=d.sos?'sosRequests':'blood_requests',ref=db.doc(`${collection}/${d.id}`),now=admin.firestore.Timestamp.now(),snap=await ref.get(),target=snap.data();
  if(!target) throw new HttpsError('not-found','Request unavailable.');
  const status=d.decision==='approved'?'approved':d.decision==='rejected'?'rejected':d.decision==='flagged'?'flagged':'clarification';
  await db.runTransaction(async tx=>{tx.update(ref,{reviewStatus:status,reviewerId:user.uid,reviewNote:d.note.trim(),reviewedAt:now});tx.create(db.collection('audit_logs').doc(),{action:`emergency_${d.decision}`,actorId:user.uid,collection,recordId:d.id,createdAt:now,note:d.note.trim()});tx.create(db.collection('notifications').doc(`emergency_${d.id}_${d.decision}`),{userId:target.requesterId||target.receiverId,type:'request_review',relatedId:d.id,title:'Request review updated',body:'Your emergency request review status changed. Open request tracking.',isRead:false,createdAt:now});});
  return {updated:true};
}
async function replyEmergencyClarification(request){
  const user=await actor(request),d=request.data||{},ref=db.doc(`blood_requests/${d.requestId}`),snap=await ref.get(),r=snap.data();
  if(!r||r.requesterId!==user.uid||r.reviewStatus!=='clarification') throw new HttpsError('permission-denied','Clarification reply unavailable.');
  if(r.clarificationReply) throw new HttpsError('already-exists','Clarification was already answered.');
  if(typeof d.reply!=='string'||!d.reply.trim()||d.reply.length>1000) throw new HttpsError('invalid-argument','Reply must be 1-1000 characters.');
  await ref.update({clarificationReply:d.reply.trim(),clarificationRepliedAt:admin.firestore.Timestamp.now()}); return {replied:true};
}
module.exports={reviewEmergencyRequest,replyEmergencyClarification,PENDING_REVIEW_ESCALATION_HOURS,LIMITED_DISCLOSURE_PENDING};
