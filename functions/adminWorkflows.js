const {HttpsError} = require('firebase-functions/v2/https');
const admin=require('./firebaseAdmin');
const {actor,serialize,rateLimit,closeRequest,resolveSos}=require('./requestWorkflows');
const db=admin.firestore();
async function adminAction(request) {
  const user=await actor(request);
  if(user.role!=='admin') throw new HttpsError('permission-denied','Administrator required.');
  const {collection,id,updates}=request.data || {};
  const fields={users:['name','bloodGroup','status'],misuse_reports:['status','adminNotes'],feedback:['status','adminNotes']};
  if(!fields[collection] || typeof id!=='string' || !id || id.includes('/') || !updates || typeof updates!=='object' || Object.keys(updates).some(k=>!fields[collection].includes(k))) throw new HttpsError('invalid-argument','Invalid administrative update.');
  if(collection==='users' && (id===user.uid || updates.status && !['approved','rejected','suspended'].includes(updates.status))) throw new HttpsError('failed-precondition','Invalid account status change.');
  if(updates.name!==undefined && (typeof updates.name!=='string' || updates.name.trim().length<2 || updates.name.length>100)) throw new HttpsError('invalid-argument','Invalid name.');
  if(updates.bloodGroup!==undefined && !['A+','A-','B+','B-','AB+','AB-','O+','O-'].includes(updates.bloodGroup)) throw new HttpsError('invalid-argument','Invalid blood group.');
  if(collection!=='users' && updates.status && !['pending','investigating','resolved','dismissed'].includes(updates.status)) throw new HttpsError('invalid-argument','Invalid report status.');
  if(updates.adminNotes!==undefined && (typeof updates.adminNotes!=='string' || updates.adminNotes.length>2000)) throw new HttpsError('invalid-argument','Notes are too long.');
  await db.runTransaction(async tx=>{
    const ref=db.doc(`${collection}/${id}`),before=await tx.get(ref);
    if(!before.exists) throw new HttpsError('not-found','Record unavailable.');
    tx.update(ref,{...updates,...(collection!=='users'?{adminReviewedBy:user.uid,reviewedAt:admin.firestore.Timestamp.now()}:{})});
    tx.create(db.collection('audit_logs').doc(),{action:'admin_update',actorId:user.uid,collection,recordId:id,fields:Object.keys(updates),createdAt:admin.firestore.Timestamp.now()});
    if(collection!=='users' && updates.status) tx.create(db.collection('notifications').doc(),{userId:before.data().reporterId,title:'Report status updated',body:`Your report is ${updates.status}.`,type:'report_update',relatedId:id,isRead:false,createdAt:admin.firestore.Timestamp.now()});
  });
  return {updated:true};
}
async function submitReport(request) {
  const user=await actor(request),d=request.data || {};
  if(typeof d.title!=='string' || !d.title.trim() || d.title.length>100 || typeof d.description!=='string' || d.description.length>2000) throw new HttpsError('invalid-argument','Check report title and details.');
  await rateLimit(`reports_${user.uid}`,10);
  const ref=await db.collection(d.feedback?'feedback':'misuse_reports').add({reporterId:user.uid,title:d.title.trim(),description:d.description,reportType:'other',reportedUserId:typeof d.reportedUserId==='string'?d.reportedUserId:null,targetRequestId:typeof d.targetRequestId==='string'?d.targetRequestId:null,status:'pending',reportedAt:admin.firestore.Timestamp.now()});
  return {id:ref.id};
}
async function exportPage(request) {
  const user=await actor(request),d=request.data || {};
  const allowed=['users','blood_requests','donations','sosRequests','misuse_reports','feedback','notifications','audit_logs'];
  if(!allowed.includes(d.collection)) throw new HttpsError('invalid-argument','Invalid export collection.');
  let query=db.collection(d.collection);
  if(d.admin===true) {
    if(user.role!=='admin') throw new HttpsError('permission-denied','Administrator required.');
  } else {
    const fields={users:'uid',blood_requests:'requesterId',donations:'donorId',sosRequests:'receiverId',misuse_reports:'reporterId',feedback:'reporterId',notifications:'userId'};
    if(!fields[d.collection]) throw new HttpsError('permission-denied','Private export unavailable.');
    query=query.where(fields[d.collection],'==',user.uid);
  }
  query=query.orderBy(admin.firestore.FieldPath.documentId()).limit(100);
  if(d.cursor) { if(typeof d.cursor!=='string' || d.cursor.includes('/')) throw new HttpsError('invalid-argument','Invalid cursor.'); query=query.startAfter(d.cursor); }
  const snap=await query.get();
  const items=snap.docs.map(doc=>({id:doc.id,...serialize(doc.data())}));
  // Moderation internal notes are intentionally excluded from personal export.
  if(!d.admin) items.forEach(item=>{delete item.adminNotes;delete item.adminReviewedBy;});
  if(d.admin && !d.cursor) await db.collection('audit_logs').add({action:'admin_export',actorId:user.uid,collection:d.collection,createdAt:admin.firestore.Timestamp.now()});
  return {items,cursor:snap.size===100?snap.docs.at(-1).id:null};
}
async function adminRequestAction(request) {
  const user=await actor(request),d=request.data || {};
  if(user.role!=='admin') throw new HttpsError('permission-denied','Administrator required.');
  if(typeof d.id!=='string'||!d.id||d.id.includes('/')||!['close','archive'].includes(d.action)) throw new HttpsError('invalid-argument','Invalid action.');
  if(d.sos) await resolveSos({auth:request.auth,data:{sosId:d.id}});
  else await closeRequest({auth:request.auth,data:{requestId:d.id}});
  const collection=d.sos?'sosRequests':'blood_requests';
  const batch=db.batch();
  if(d.action==='archive')batch.update(db.doc(`${collection}/${d.id}`),{archived:true});
  batch.create(db.collection('audit_logs').doc(),{action:`admin_${d.action}`,actorId:user.uid,collection,recordId:d.id,createdAt:admin.firestore.Timestamp.now()});
  await batch.commit();return {updated:true};
}
module.exports={adminAction,submitReport,exportPage,adminRequestAction};
