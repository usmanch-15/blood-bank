const {HttpsError}=require('firebase-functions/v2/https');
const admin=require('./firebaseAdmin');
const {actor,rateLimit}=require('./requestWorkflows');
const {liveConversation}=require('./requestPolicy');
const db=admin.firestore();
const fail=(c,m)=>{throw new HttpsError(c,m)};
async function conversation(request) {
  const user=await actor(request), id=request.data?.conversationId;
  if(typeof id!=='string'||!id.length||id.length>128||id.includes('/')) fail('invalid-argument','Invalid conversation.');
  const ref=db.doc(`conversations/${id}`), snap=await ref.get(), c=snap.data();
  if(!c||!Array.isArray(c.participantIds)||!c.participantIds.includes(user.uid)) fail('permission-denied','Conversation unavailable.');
  const r=(await db.doc(`blood_requests/${c.requestId}`).get()).data();
  const other=c.participantIds.find(x=>x!==user.uid); if(!other) fail('failed-precondition','Conversation has no other participant.');
  return {user,c,ref,other,r};
}
async function blockUser(request) {
  const {user,ref,other}=await conversation(request); const now=admin.firestore.Timestamp.now();
  await ref.set({blocks:{[user.uid]:{blockedUserId:other,blockedAt:now}},blockedUserIds:admin.firestore.FieldValue.arrayUnion(other)},{merge:true});
  return {blocked:true};
}
async function unblockUser(request) {
  const {user,ref,other}=await conversation(request); const snap=await ref.get(), c=snap.data()||{};
  const ids=(c.blockedUserIds||[]).filter(x=>x!==other); const blocks={...(c.blocks||{})}; delete blocks[user.uid];
  await ref.set({blocks,blockedUserIds:ids},{merge:true}); return {blocked:false};
}
async function markConversationRead(request) {
  const {user,ref}=await conversation(request); await ref.update({[`unread.${user.uid}`]:0}); return {read:true};
}
async function reportConversation(request) {
  const {user,other}=await conversation(request), d=request.data||{}, reason=typeof d.reason==='string'?d.reason.trim():'';
  if(!reason||reason.length>1000) fail('invalid-argument','Reason must be 1-1000 characters.');
  await rateLimit(`chat_reports_${user.uid}`,5);
  const key=`chat_report_${user.uid}_${request.data.conversationId}_${d.messageId||other}`;
  const ref=db.doc(`misuse_reports/${key.replace(/[^A-Za-z0-9_-]/g,'_').slice(0,150)}`);
  if((await ref.get()).exists) return {alreadyReported:true};
  await ref.create({reporterId:user.uid,reportedUserId:other,targetConversationId:request.data.conversationId,targetMessageId:typeof d.messageId==='string'?d.messageId:null,title:'Chat report',description:reason.slice(0,1000),category:typeof d.category==='string'?d.category.slice(0,50):null,status:'pending',reportedAt:admin.firestore.Timestamp.now()});
  return {reported:true};
}
async function sharePhoneNumber(request) {
  if(request.data?.confirm!==true) fail('failed-precondition','Explicit confirmation is required.');
  const {user,ref}=await conversation(request);
  await db.runTransaction(async tx=>{
    const c=(await tx.get(ref)).data();
    const other=c?.participantIds?.find(uid=>uid!==user.uid);
    if(!other) fail('permission-denied','Conversation unavailable.');
    const [root,sender,receiver,privateContact]=await Promise.all([
      tx.get(db.doc(`blood_requests/${c.requestId}`)),tx.get(db.doc(`users/${user.uid}`)),
      tx.get(db.doc(`users/${other}`)),tx.get(db.doc(`users/${user.uid}/private/contact`)),
    ]);
    if(sender.data()?.status!=='approved'||receiver.data()?.status!=='approved'||!liveConversation(c,root.data(),user.uid)) fail('permission-denied','Conversation is read-only.');
    const contact=privateContact.data();
    if(!contact?.phoneNumber) fail('failed-precondition','No verified phone number is available.');
    tx.create(ref.collection('messages').doc(),{senderId:user.uid,type:'phone_share',sharedWith:other,phoneNumber:contact.phoneNumber,body:'Phone number shared by participant.',createdAt:admin.firestore.FieldValue.serverTimestamp()});
  });
  return {shared:true};
}
module.exports={blockUser,unblockUser,markConversationRead,reportConversation,sharePhoneNumber};
