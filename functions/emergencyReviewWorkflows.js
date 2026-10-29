const {HttpsError}=require('firebase-functions/v2/https');
const admin=require('./firebaseAdmin');
const {actor,rateLimit}=require('./requestWorkflows');
const {assignments,activeStatuses}=require('./requestPolicy');
const db=admin.firestore();
const PENDING_REVIEW_ESCALATION_HOURS=Number(process.env.EMERGENCY_REVIEW_ESCALATION_HOURS||2);
const LIMITED_DISCLOSURE_PENDING=true;
async function reviewEmergencyRequest(request){
  const user=await actor(request),d=request.data||{};
  if(user.role!=='admin') throw new HttpsError('permission-denied','Administrator required.');
  if(!['approved','rejected','flagged','clarification'].includes(d.decision)||typeof d.note!=='string'||!d.note.trim()) throw new HttpsError('invalid-argument','Decision and note are required.');
  if(typeof d.id!=='string'||!d.id.length||d.id.length>128||d.id.includes('/')||d.note.length>1000) throw new HttpsError('invalid-argument','Invalid review identifier or note.');
  const collection=d.sos?'sosRequests':'blood_requests',ref=db.doc(`${collection}/${d.id}`),now=admin.firestore.Timestamp.now();
  await db.runTransaction(async tx=>{
    const target=(await tx.get(ref)).data();
    if(!target) throw new HttpsError('not-found','Request unavailable.');
    const rootRef=d.sos&&target.requestId?db.doc(`blood_requests/${target.requestId}`):d.sos?null:ref;
    const root=rootRef?(rootRef.path===ref.path?target:(await tx.get(rootRef)).data()):null;
    if(d.sos&&target.requestId&&(!root||root.sosId!==d.id)) throw new HttpsError('failed-precondition','Linked request unavailable.');
    const sosRef=!d.sos&&root?.sosId?db.doc(`sosRequests/${root.sosId}`):null;
    const linked=sosRef?(await tx.get(sosRef)).data():null;
    if(sosRef&&(!linked||linked.requestId!==ref.id)) throw new HttpsError('failed-precondition','Linked SOS unavailable.');
    const commitments=assignments(root||{});
    const release=d.decision==='rejected'&&root&&['pending','accepted','partially_fulfilled'].includes(root.status);
    const ids=release?Object.keys(commitments).filter(id=>activeStatuses.includes(commitments[id]?.status)):[];
    const donors=await Promise.all(ids.map(id=>tx.get(db.doc(`users/${id}`))));
    const review={reviewStatus:d.decision,reviewerId:user.uid,reviewNote:d.note.trim(),reviewedAt:now};
    tx.update(ref,review);
    if(rootRef&&rootRef.path!==ref.path) tx.update(rootRef,review);
    if(sosRef) tx.update(sosRef,review);
    if(release){
      for(const donor of donors){
        commitments[donor.id]={...commitments[donor.id],status:'released'};
        if(donor.data()?.activeRequestId===rootRef.id) tx.update(donor.ref,{activeRequestId:admin.firestore.FieldValue.delete()});
      }
      tx.update(rootRef,{status:'cancelled',commitments,acceptedDonorIds:[],acceptedDonorId:admin.firestore.FieldValue.delete(),closedAt:now});
    }
    const closingSos=d.sos?ref:sosRef;
    if(d.decision==='rejected'&&closingSos) tx.update(closingSos,{status:'cancelled',isResolved:true,resolvedAt:now});
    tx.create(db.collection('audit_logs').doc(),{action:`emergency_${d.decision}`,actorId:user.uid,collection,recordId:d.id,createdAt:now,note:d.note.trim()});
    tx.set(db.collection('notifications').doc(`emergency_${d.id}_${d.decision}`),{userId:target.requesterId||target.receiverId,type:'request_review',relatedId:d.id,title:'Request review updated',body:'Your emergency request review status changed. Open request tracking.',isRead:false,createdAt:now});
  });
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
