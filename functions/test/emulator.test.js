const {test,before,after,beforeEach} = require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,updateDoc,getDoc,deleteDoc,writeBatch,getDocs,collection,query,where,serverTimestamp}=require('firebase/firestore');
const admin=require('../firebaseAdmin');
if(!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw Error('Use emulators:exec. Production tests are forbidden.');
const projectId='demo-bloodbank';
admin.initializeApp({projectId,storageBucket:`${projectId}.appspot.com`});
const workflows=require('../secureWorkflows');
const {nearbyDonors}=require('../nearbyDonors');
const voice=require('../voiceWorkflows');
let env;
const profile=(uid,role='donor')=>({uid,email:`${uid}@example.test`,name:'Test User',role,status:'approved',bloodGroup:'O+',isDonor:role==='donor',isReceiver:role==='receiver',isAvailable:true,locationSharingEnabled:false,latitude:null,longitude:null,rewardPoints:0,isEligible:true,lastDonationDate:null});
const requestData={requesterId:'receiver',status:'pending',bloodGroup:'O+',quantity:1,hospitalName:"Children's Hospital"};
const auth=uid=>({uid,token:{auth_time:Math.floor(Date.now()/1000)}});

test('chat writes and phone sharing require a live assignment; history remains readable',async()=>{
  const chat=require('../chatWorkflows');
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('users/donor/private/contact').set({phoneNumber:'+923001234567'});
  const input={auth:auth('donor'),data:{conversationId:'request_donor',confirm:true}};
  const db=env.authenticatedContext('donor').firestore();
  const message=()=>({senderId:'donor',body:'Available',createdAt:serverTimestamp()});
  await assertSucceeds(setDoc(doc(db,'conversations/request_donor/messages/allowed'),message()));
  await admin.firestore().doc('blood_requests/request').update({requiredBy:Date.now()+3600000});
  await assertSucceeds(setDoc(doc(db,'conversations/request_donor/messages/legacy-deadline'),message()));
  assert.deepEqual(await chat.sharePhoneNumber(input),{shared:true});
  await chat.blockUser({auth:auth('receiver'),data:{conversationId:'request_donor'}});
  await assertFails(setDoc(doc(db,'conversations/request_donor/messages/blocked'),message()));
  await assert.rejects(chat.sharePhoneNumber(input),{code:'permission-denied'});
  await chat.unblockUser({auth:auth('receiver'),data:{conversationId:'request_donor'}});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',donorId:'donor',action:'withdraw'}});
  await assertFails(setDoc(doc(db,'conversations/request_donor/messages/withdrawn'),message()));
  await assert.rejects(chat.sharePhoneNumber(input),{code:'permission-denied'});
  await assertSucceeds(getDoc(doc(db,'conversations/request_donor/messages/allowed')));
  assert.deepEqual(await chat.markConversationRead(input),{read:true});
});

test('expired requests and suspended peers deny chat writes and phone sharing',async()=>{
  const chat=require('../chatWorkflows');
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('users/donor/private/contact').set({phoneNumber:'+923001234567'});
  const db=env.authenticatedContext('donor').firestore();
  const input={auth:auth('donor'),data:{conversationId:'request_donor',confirm:true}};
  for(const state of ['expired','suspended']){
    await admin.firestore().doc('blood_requests/request').update({requiredBy:admin.firestore.Timestamp.fromMillis(Date.now()+(state==='expired'?-1000:3600000))});
    await admin.firestore().doc('users/receiver').update({status:state==='suspended'?'suspended':'approved'});
    await assertFails(setDoc(doc(db,`conversations/request_donor/messages/${state}`),{senderId:'donor',body:'Denied',createdAt:serverTimestamp()}));
    await assert.rejects(chat.sharePhoneNumber(input),{code:'permission-denied'});
  }
});

test('legacy array and empty commitments preserve access but never override withdrawal',async()=>{
  const ref=admin.firestore().doc('blood_requests/request');
  await ref.update({acceptedDonorIds:['donor'],commitments:{},status:'accepted'});
  const before=(await ref.get()).data();
  const detail=await workflows.getRequest({auth:auth('donor'),data:{requestId:'request'}});
  assert.equal(detail.commitments.donor.status,'accepted');
  assert.equal((await workflows.participantRequests({auth:auth('donor'),data:{mode:'active'}})).items.length,1);
  assert.deepEqual((await ref.get()).data(),before);
  await ref.update({commitments:{donor:{status:'withdrawn'}}});
  assert.equal((await workflows.participantRequests({auth:auth('donor'),data:{mode:'active'}})).items.length,0);
});

test('emergency rejection closes linked records, releases donors and denies new actions',async()=>{
  const {reviewEmergencyRequest}=require('../emergencyReviewWorkflows');
  await admin.firestore().doc('users/admin').set(profile('admin','admin'));
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('blood_requests/request').update({sosId:'sos',reviewStatus:'pending_review',patientName:'preserve-private'});
  await admin.firestore().doc('sosRequests/sos').set({requestId:'request',receiverId:'receiver',isResolved:false});
  await assert.rejects(reviewEmergencyRequest({auth:auth('donor'),data:{id:'sos',sos:true,decision:'rejected',note:'Review'}}),{code:'permission-denied'});
  const input={auth:auth('admin'),data:{id:'sos',sos:true,decision:'rejected',note:'Review'}};
  await reviewEmergencyRequest(input);
  await reviewEmergencyRequest(input);
  const r=(await admin.firestore().doc('blood_requests/request').get()).data();
  assert.equal(r.status,'cancelled'); assert.equal(r.patientName,'preserve-private');
  assert.equal(r.commitments.donor.status,'released');
  assert.equal((await admin.firestore().doc('users/donor').get()).data().activeRequestId,undefined);
  assert.equal((await admin.firestore().doc('sosRequests/sos').get()).data().isResolved,true);
  await assert.rejects(workflows.acceptDonation({auth:auth('other'),data:{requestId:'request'}}),{code:'failed-precondition'});
  await assert.rejects(require('../requestNotifications').notifyRequest({auth:auth('receiver'),data:{requestId:'request'}}),{code:'permission-denied'});
  await assertSucceeds(getDoc(doc(env.authenticatedContext('receiver').firestore(),'blood_requests/request')));
  await assertFails(getDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/request')));
  // A legacy rejected record may still say pending: guards must not rely on cancellation alone.
  await admin.firestore().doc('blood_requests/request').update({status:'pending',latitude:31,longitude:74});
  await admin.firestore().doc('users/other').update({latitude:31,longitude:74,locationSharingEnabled:true});
  await assert.rejects(workflows.acceptDonation({auth:auth('other'),data:{requestId:'request'}}),{code:'failed-precondition'});
  await assert.rejects(workflows.getRequest({auth:auth('other'),data:{requestId:'request'}}),{code:'permission-denied'});
  assert.equal((await workflows.discoverRequests({auth:auth('other'),data:{radiusKm:50}})).items.length,0);
});

test('legacy assigned voice answers work, while rejected reviews deny answers',async()=>{
  await admin.firestore().doc('blood_requests/request').update({acceptedDonorIds:['donor'],commitments:{},status:'accepted'});
  const session={requestId:'request',participantIds:['receiver','donor'],createdBy:'receiver',status:'ringing',expiresAt:admin.firestore.Timestamp.fromMillis(Date.now()+3600000)};
  await admin.firestore().doc('callSessions/legacy').set(session);
  assert.deepEqual(await voice.updateVoiceCallSession({auth:auth('donor'),data:{sessionId:'legacy',status:'accepted'}}),{updated:true,status:'accepted'});
  await admin.firestore().doc('callSessions/rejected').set(session);
  await admin.firestore().doc('blood_requests/request').update({reviewStatus:'rejected'});
  await assert.rejects(voice.updateVoiceCallSession({auth:auth('donor'),data:{sessionId:'rejected',status:'accepted'}}),{code:'failed-precondition'});
});

test('SOS retries reuse the same linked request and deny another owner',async()=>{
  const data={submissionId:'retry-sos',bloodGroup:'O+',urgency:'critical',latitude:31,longitude:74,hospitalName:'Emergency Hospital',contactNumber:'+923001234567'};
  const results=await Promise.all([1,2].map(()=>workflows.createSosAlert({auth:auth('receiver'),data})));
  assert.deepEqual(results[0],results[1]);
  assert.equal((await admin.firestore().collection('blood_requests').where('sosId','==','retry-sos').get()).size,1);
  await admin.firestore().doc('users/other').update({isReceiver:true});
  await assert.rejects(workflows.createSosAlert({auth:auth('other'),data}),{code:'permission-denied'});
});

test('normalized emergency urgency always enters review',async()=>{
  await workflows.createBloodRequest({auth:auth('receiver'),data:{...requestData,requestId:'normalized-urgent',latitude:31,longitude:74,contactNumber:'+923001234567',requiredBy:Date.now()+3600000,urgency:' Critical '}});
  const saved=(await admin.firestore().doc('blood_requests/normalized-urgent').get()).data();
  assert.equal(saved.urgency,'critical');
  assert.equal(saved.reviewStatus,'pending_review');
});

test('concurrent similar requests serialize across different IDs and retries remain idempotent',async()=>{
  const data={...requestData,latitude:31,longitude:74,contactNumber:'+923001234567',requiredBy:Date.now()+3600000};
  const results=await Promise.allSettled(['parallel-a','parallel-b'].map(requestId=>workflows.createBloodRequest({auth:auth('receiver'),data:{...data,requestId}})));
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal(results.find(r=>r.status==='rejected').reason.code,'already-exists');
  const requestId=results.find(r=>r.status==='fulfilled').value.id;
  assert.equal((await workflows.createBloodRequest({auth:auth('receiver'),data:{...data,requestId}})).id,requestId);
  await assertFails(getDoc(doc(env.authenticatedContext('receiver').firestore(),'request_submission_guards/receiver')));
});
test('a receiver with donor capability retains owner tracking after role switching',async()=>{
  await admin.firestore().doc('users/receiver').update({isDonor:true});
  const result=await workflows.getRequest({auth:auth('receiver'),data:{requestId:'request'}});
  assert.equal(result.requesterId,'receiver'); assert.equal(result.canViewPrivate,true);
});
test('saved coordinates enforce Pakistan bounds while unchanged legacy profiles remain editable',async()=>{
  const ref=doc(env.authenticatedContext('donor').firestore(),'users/donor');
  await assertFails(updateDoc(ref,{locationSharingEnabled:true,latitude:40,longitude:74}));
  await assertSucceeds(updateDoc(ref,{locationSharingEnabled:true,latitude:23.5,longitude:60.8}));
  await admin.firestore().doc('users/donor').update({latitude:40});
  await assertSucceeds(updateDoc(ref,{name:'Updated Name'}));
  await assertFails(updateDoc(ref,{longitude:75}));
  await assertSucceeds(updateDoc(ref,{latitude:null,longitude:null,locationSharingEnabled:false}));
});
test('discovery scans sparse pages and preserves continuation after its read bound',async()=>{
  await admin.firestore().doc('users/donor').update({latitude:31,longitude:74,locationSharingEnabled:true});
  for(let start=0;start<450;start+=225) {
    const batch=admin.firestore().batch();
    for(let i=start;i<start+225;i++) batch.set(admin.firestore().doc(`blood_requests/a${String(i).padStart(3,'0')}`),
      {...requestData,latitude:31,longitude:74,bloodGroup:'A-',requiredBy:admin.firestore.Timestamp.fromMillis(Date.now()+3600000)});
    await batch.commit();
  }
  await admin.firestore().doc('blood_requests/zmatch').set({...requestData,latitude:32,longitude:74});
  const first=await workflows.discoverRequests({auth:auth('donor'),data:{radiusKm:250}});
  assert.equal(first.items.length,0); assert.ok(first.cursor);
  const next=await workflows.discoverRequests({auth:auth('donor'),data:{radiusKm:250,cursor:first.cursor}});
  assert.deepEqual(next.items.map(i=>i.id),['zmatch']); assert.equal(next.cursor,null);
  const local=await workflows.discoverRequests({auth:auth('donor'),data:{radiusKm:5,cursor:first.cursor}});
  assert.equal(local.items.length,0);
  await assert.rejects(workflows.discoverRequests({auth:auth('receiver'),data:{}}),{code:'permission-denied'});
  await admin.firestore().doc('users/donor').update({status:'suspended'});
  await assert.rejects(workflows.discoverRequests({auth:auth('donor'),data:{}}),{code:'permission-denied'});
});
test('chat trigger notifies only the other active participant, privately and idempotently',async()=>{
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  const {notifyChatMessage}=require('../chatNotifications');
  const event={params:{conversationId:'request_donor',messageId:'m1'},data:{data:()=>({senderId:'donor',body:'PRIVATE_MESSAGE_SENTINEL'})}};
  await Promise.all([notifyChatMessage(event),notifyChatMessage(event)]);
  const doc=await admin.firestore().doc('notifications/chat_request_donor_m1').get();
  assert.equal(doc.data().userId,'receiver'); assert.equal(doc.data().relatedId,'request_donor');
  assert.ok(!JSON.stringify(doc.data()).includes('PRIVATE_MESSAGE_SENTINEL'));
  await notifyChatMessage({...event,params:{...event.params,messageId:'spoof'},data:{data:()=>({senderId:'other'})}});
  assert.equal((await admin.firestore().doc('notifications/chat_request_donor_spoof').get()).exists,false);
  await admin.firestore().doc('users/receiver').update({status:'suspended'});
  await notifyChatMessage({...event,params:{...event.params,messageId:'suspended'}});
  assert.equal((await admin.firestore().doc('notifications/chat_request_donor_suspended').get()).exists,false);
});
test('voice answers require the active callee and a live authorized assignment',async()=>{
  const voice=require('../voiceWorkflows');
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('callSessions/call').set({requestId:'request',participantIds:['receiver','donor'],createdBy:'receiver',status:'ringing',expiresAt:admin.firestore.Timestamp.fromMillis(Date.now()+3600000)});
  const call=(uid,status)=>voice.updateVoiceCallSession({auth:auth(uid),data:{sessionId:'call',status}});
  await assert.rejects(call('receiver','accepted'),{code:'permission-denied'});
  await assert.rejects(call('other','accepted'),{code:'permission-denied'});
  await call('donor','accepted');
  await assert.rejects(call('donor','accepted'),{code:'failed-precondition'});
  await call('receiver','ended');
  await assert.rejects(voice.getVoiceCallToken({auth:auth('donor'),data:{sessionId:'call'}}),{code:'failed-precondition'});
  await admin.firestore().doc('users/donor').update({status:'suspended'});
  await assert.rejects(call('donor','ended'),{code:'permission-denied'});
});
test('notifyRequest respects the selected range, ownership and deduplicates inbox entries',async()=>{
  const {notifyRequest}=require('../requestNotifications');
  await admin.firestore().doc('blood_requests/request').update({latitude:31,longitude:74});
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:32,longitude:74});
  const input={auth:auth('receiver'),data:{requestId:'request',radiusKm:5}};
  assert.equal((await notifyRequest(input)).count,0);
  const wide={...input,data:{...input.data,radiusKm:250}};
  assert.equal((await notifyRequest(wide)).count,1);
  assert.equal((await notifyRequest(wide)).count,0);
  const inbox=(await admin.firestore().doc('notifications/request_request_donor').get()).data();
  assert.equal(inbox.userId,'donor'); assert.ok(!inbox.body.includes('O+'));
  await assert.rejects(notifyRequest({...wide,auth:auth('other')}),{code:'permission-denied'});
  await assert.rejects(notifyRequest({...wide,data:{...wide.data,radiusKm:'bad'}}),{code:'invalid-argument'});
});
test('chat block and mark-read are participant scoped',async()=>{
  const chat=require('../chatWorkflows');
  await admin.firestore().doc('blood_requests/request').update({status:'accepted',requesterId:'receiver',participantIds:['receiver','donor'],acceptedDonorIds:['donor'],commitments:{donor:{status:'accepted'}}});
  await admin.firestore().doc('conversations/request_donor').set({requestId:'request',participantIds:['receiver','donor'],unread:{donor:2,receiver:1}});
  await chat.blockUser({auth:auth('receiver'),data:{conversationId:'request_donor'}});
  const c=(await admin.firestore().doc('conversations/request_donor').get()).data(); assert.deepEqual(c.blockedUserIds,['donor']);
  await chat.markConversationRead({auth:auth('receiver'),data:{conversationId:'request_donor'}});
  assert.equal((await admin.firestore().doc('conversations/request_donor').get()).data().unread.receiver,0);
});
test('chat report is duplicate protected and phone sharing requires confirmation',async()=>{
  const chat=require('../chatWorkflows');
  await admin.firestore().doc('blood_requests/request').update({status:'accepted',participantIds:['receiver','donor'],acceptedDonorIds:['donor'],commitments:{donor:{status:'accepted'}}});
  await admin.firestore().doc('conversations/request_donor').set({requestId:'request',participantIds:['receiver','donor']});
  const input={auth:auth('receiver'),data:{conversationId:'request_donor',reason:'unwanted contact',messageId:'m1'}};
  assert.deepEqual(await chat.reportConversation(input),{reported:true}); assert.deepEqual(await chat.reportConversation(input),{alreadyReported:true});
  await assert.rejects(chat.sharePhoneNumber({auth:auth('receiver'),data:{conversationId:'request_donor',confirm:false}}),{code:'failed-precondition'});
});
test('blocked chat sender produces no notification and unread increments atomically',async()=>{
  const chat=require('../chatWorkflows');
  await admin.firestore().doc('blood_requests/request').update({status:'accepted',participantIds:['receiver','donor'],acceptedDonorIds:['donor'],commitments:{donor:{status:'accepted'}}});
  await admin.firestore().doc('conversations/request_donor').set({requestId:'request',participantIds:['receiver','donor'],blockedUserIds:['donor']});
  await chat.blockUser({auth:auth('receiver'),data:{conversationId:'request_donor'}}).catch(()=>{});
  const {notifyChatMessage}=require('../chatNotifications');
  await notifyChatMessage({params:{conversationId:'request_donor',messageId:'blocked'},data:{data:()=>({senderId:'donor',body:'x'})}});
  assert.equal((await admin.firestore().doc('notifications/chat_request_donor_blocked').get()).exists,false);
});
test('findDonors exposes profile image but no phone or exact coordinates',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31.123456,longitude:74.654321,profileImageUrl:'https://cdn.example/avatar.jpg',phone:'+923001234567'});
  const result=await workflows.findDonors({auth:auth('receiver'),data:{latitude:31.12,longitude:74.65,radiusKm:100}});
  assert.equal(result.donors.length,1);
  const donor=result.donors[0];
  assert.equal(donor.profileImageUrl,'https://cdn.example/avatar.jpg');
  assert.equal(donor.phone,undefined); assert.notEqual(donor.latitude,31.123456); assert.notEqual(donor.longitude,74.654321);
});
test('decline is idempotent and races with acceptance without double counts',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31,longitude:74});
  const decline=()=>workflows.declineRequest({auth:auth('donor'),data:{requestId:'request'}});
  const [a,b]=await Promise.allSettled([decline(),decline()]);
  assert.ok([a,b].every(x=>x.status==='fulfilled'));
  const user=(await admin.firestore().doc('users/donor').get()).data();
  assert.equal(user.declinedRequestIds.filter(x=>x==='request').length,1);
  await admin.firestore().doc('users/donor').update({declinedRequestIds:[],isAvailable:true});
  await admin.firestore().doc('blood_requests/request').update({commitments:{},acceptedDonorIds:[]});
  const raced=await Promise.allSettled([workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}}),decline()]);
  assert.ok(raced.some(x=>x.status==='fulfilled'));
  if ((await admin.firestore().doc('blood_requests/request').get()).data().commitments?.donor) {
    await assert.rejects(decline(),{code:'failed-precondition'});
  }
});
before(async()=>{env=await initializeTestEnvironment({projectId,
  firestore:{rules:fs.readFileSync('../firestore.rules','utf8')},
  storage:{rules:fs.readFileSync('../storage.rules','utf8')}});});
after(async()=>{await env.cleanup();await admin.app().delete();});
beforeEach(async()=>{
  await env.clearFirestore();
  await Promise.all(['donor','other','receiver'].map(uid=>admin.firestore().doc(`users/${uid}`).set(profile(uid,uid==='receiver'?'receiver':'donor'))));
  await admin.firestore().doc('blood_requests/request').set(requestData);
});
test('signup schema, mode switching, availability and privilege boundaries',async()=>{
  const db=env.authenticatedContext('new',{email:'new@example.test'}).firestore();
  await assertSucceeds(setDoc(doc(db,'users/new'),profile('new')));
  await assertSucceeds(updateDoc(doc(db,'users/new'),{role:'receiver',isReceiver:true,isAvailable:false}));
  await assertFails(updateDoc(doc(db,'users/new'),{role:'admin'}));
  await assertFails(updateDoc(doc(db,'users/new'),{rewardPoints:9999}));
  await assertFails(updateDoc(doc(db,'users/new'),{lastDonationDate:null,isEligible:false}));
  await assertFails(updateDoc(doc(db,'users/new'),{status:'approved',phoneNumber:'+923001234567'}));
});
test('signup profile and private contact commit atomically',async()=>{
  const db=env.authenticatedContext('new',{email:'new@example.test'}).firestore();
  const batch=writeBatch(db);
  batch.set(doc(db,'users/new'),profile('new','receiver'));
  batch.set(doc(db,'users/new/private/contact'),{phoneNumber:'+923001234567',cnic:'12345-1234567-1'});
  await assertSucceeds(batch.commit());
  assert.equal((await getDoc(doc(db,'users/new/private/contact'))).data().phoneNumber,'+923001234567');
});
test('email sync requires the authenticated email claim and coordinate pairs',async()=>{
  const ref=doc(env.authenticatedContext('donor',{email:'new@example.test'}).firestore(),'users/donor');
  await assertFails(updateDoc(ref,{email:'victim@example.test'}));
  await assertSucceeds(updateDoc(ref,{email:'new@example.test'}));
  await assertFails(updateDoc(ref,{locationSharingEnabled:true,latitude:31}));
});
test('acceptance and fulfillment notify the requester and donor exactly once',async()=>{
  const accept={auth:auth('donor'),data:{requestId:'request'}};
  await workflows.acceptDonation(accept);
  await workflows.acceptDonation(accept);
  assert.equal((await admin.firestore().doc('notifications/accepted_request_donor').get()).data().userId,'receiver');
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'agree'}});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'ready'}});
  const confirm={auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}};
  await workflows.confirmDonation(confirm);
  await workflows.confirmDonation(confirm);
  assert.equal((await admin.firestore().collection('notifications').get()).size,5);
  assert.equal((await admin.firestore().doc('notifications/progress_request_donor').get()).data().userId,'receiver');
});
test('ordinary accounts cannot resolve unrelated SOS or perform admin edits',async()=>{
  await admin.firestore().doc('sosRequests/sos').set({receiverId:'receiver',isResolved:false});
  const db=env.authenticatedContext('donor').firestore();
  await assertFails(updateDoc(doc(db,'sosRequests/sos'),{isResolved:true}));
  await assertFails(updateDoc(doc(db,'users/receiver'),{name:'Edited by donor'}));
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  const adminDb=env.authenticatedContext('admin').firestore();
  await assertFails(updateDoc(doc(adminDb,'sosRequests/sos'),{isResolved:true}));
  await assertFails(updateDoc(doc(adminDb,'users/admin'),{status:'rejected'}));
});
test('SOS creation validates ownership, urgency and limits before writing',async()=>{
  const data={latitude:31,longitude:74,bloodGroup:'O+',urgency:'life_threatening',contactNumber:'+923001234567'};
  await assert.rejects(workflows.createSosAlert({auth:auth('donor'),data}),{code:'permission-denied'});
  await assert.rejects(workflows.createSosAlert({auth:auth('receiver'),data:{...data,latitude:200}}),{code:'invalid-argument'});
  for (let i=0;i<3;i++) await workflows.createSosAlert({auth:auth('receiver'),data:{...data,receiverId:'other'}});
  await assert.rejects(workflows.createSosAlert({auth:auth('receiver'),data}),{code:'resource-exhausted'});
  const records=await admin.firestore().collection('sosRequests').get();
  assert.equal(records.size,3);
  assert.ok(records.docs.every(doc=>doc.data().receiverId==='receiver' && doc.data().urgency==='life_threatening'));
  await assertFails(setDoc(doc(env.authenticatedContext('receiver').firestore(),'sosRequests/direct'),{...data,receiverId:'receiver',isResolved:false}));
});
test('suspended users and unauthenticated callers cannot read dashboards',async()=>{
  await admin.firestore().doc('users/donor').update({status:'suspended'});
  await assertFails(getDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/request')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'users/receiver')));
});
test('owner can cancel but cannot forge fulfillment, assignment or ownership',async()=>{
  const ref=doc(env.authenticatedContext('receiver').firestore(),'blood_requests/request');
  await assertFails(updateDoc(ref,{status:'fulfilled'}));
  await assertFails(updateDoc(ref,{requesterId:'other'}));
  await assertFails(updateDoc(ref,{acceptedDonorId:'donor'}));
  await assertFails(updateDoc(ref,{status:'cancelled'}));
  await assert.rejects(
    workflows.closeRequest({auth:auth('donor'),data:{requestId:'request',status:'cancelled'}}),
    {code:'permission-denied'},
  );
  await assert.rejects(
    workflows.closeRequest({auth:auth('receiver'),data:{requestId:'request',status:'fulfilled'}}),
    {code:'invalid-argument'},
  );
  assert.equal((await admin.firestore().doc('blood_requests/request').get()).data().status,'pending');
  await workflows.closeRequest({auth:auth('receiver'),data:{requestId:'request',status:'cancelled'}});
  await workflows.closeRequest({auth:auth('receiver'),data:{requestId:'request',status:'cancelled'}});
  assert.equal((await admin.firestore().doc('blood_requests/request').get()).data().status,'cancelled');
  await assertFails(updateDoc(ref,{status:'pending'}));

  await admin.firestore().doc('users/admin').set(profile('admin','admin'));
  await admin.firestore().doc('blood_requests/admin-close').set({...requestData,requesterId:'receiver'});
  await workflows.closeRequest({auth:auth('admin'),data:{requestId:'admin-close',status:'cancelled'}});
  assert.equal((await admin.firestore().doc('blood_requests/admin-close').get()).data().status,'cancelled');
});
test('request creation requires receiver capability, valid coordinates and no forged recipients',async()=>{
  const valid={...requestData,latitude:31,longitude:74,notifiedDonors:[]};
  const receiverDb=env.authenticatedContext('receiver').firestore();
  await assertFails(setDoc(doc(receiverDb,'blood_requests/new'),valid));
  await workflows.createBloodRequest({auth:auth('receiver'),data:{...valid,requestId:'new',contactNumber:'+923001234567',requiredBy:Date.now()+3600000}});
  await assertFails(setDoc(doc(receiverDb,'blood_requests/forged'),{...valid,notifiedDonors:['donor']}));
  await assertFails(setDoc(doc(receiverDb,'blood_requests/bad-location'),{...valid,latitude:200}));
  await assertFails(setDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/not-receiver'),{...valid,requesterId:'donor'}));
});
test('notifications and donation records cannot be forged by clients',async()=>{
  const db=env.authenticatedContext('donor').firestore();
  await assertFails(setDoc(doc(db,'notifications/fake'),{userId:'receiver',body:'spam'}));
  await assertFails(setDoc(doc(db,'donations/fake'),{donorId:'donor',pointsEarned:9999}));
  await assertFails(deleteDoc(doc(db,'users/donor')));
  await assertFails(getDoc(doc(env.authenticatedContext('other').firestore(),'users/donor/private/device')));
});
test('phone changes require verified claims; location consent and availability persist',async()=>{
  const db=env.authenticatedContext('donor').firestore();
  const ref=doc(db,'users/donor');
  await assertSucceeds(setDoc(doc(db,'users/donor/private/contact'),{phoneNumber:'+923001234567'}));
  await assertFails(updateDoc(doc(db,'users/donor/private/contact'),{phoneNumber:'+923009999999'}));
  const verified=env.authenticatedContext('donor',{phone_number:'+923009999999'}).firestore();
  await assertSucceeds(updateDoc(doc(verified,'users/donor/private/contact'),{phoneNumber:'+923009999999'}));
  await assertFails(updateDoc(ref,{latitude:31,longitude:74}));
  await assertSucceeds(updateDoc(ref,{locationSharingEnabled:true,latitude:31,longitude:74,isAvailable:false}));
  assert.equal((await getDoc(ref)).data().isAvailable,false);
  await assertSucceeds(updateDoc(ref,{locationSharingEnabled:false,latitude:null,longitude:null}));
});
test('indexed radius matching excludes unavailable, unconsented and ineligible donors',async()=>{
  const ref=admin.firestore().doc('users/donor');
  await ref.update({locationSharingEnabled:true,latitude:31.18,longitude:74});
  assert.deepEqual(await nearbyDonors(31,74,'O+',15),[]);
  assert.deepEqual(await nearbyDonors(31,74,'O+',30),['donor']);
  await ref.update({isAvailable:false});
  assert.deepEqual(await nearbyDonors(31,74,'O+',30),[]);
  await ref.update({isAvailable:true,locationSharingEnabled:false});
  assert.deepEqual(await nearbyDonors(31,74,'O+',30),[]);
  await ref.update({locationSharingEnabled:true,lastDonationDate:admin.firestore.Timestamp.now()});
  assert.deepEqual(await nearbyDonors(31,74,'O+',30),[]);
});
test('cancelled and incompatible requests cannot be accepted or confirmed',async()=>{
  await admin.firestore().doc('blood_requests/request').update({status:'cancelled'});
  await assert.rejects(workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}}),{code:'failed-precondition'});
  await admin.firestore().doc('blood_requests/request').update({status:'pending',bloodGroup:'O-'});
  await assert.rejects(workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}}),{code:'failed-precondition'});
});
test('confirmation rejects unauthenticated and unrelated donors',async()=>{
  await assert.rejects(workflows.confirmDonation({data:{requestId:'request',donorId:'donor'}}),{code:'unauthenticated'});
  await assert.rejects(workflows.confirmDonation({auth:auth('donor'),data:{requestId:'request',donorId:'donor'}}),{code:'permission-denied'});
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await assert.rejects(workflows.confirmDonation({auth:auth('other'),data:{requestId:'request',donorId:'donor'}}),{code:'permission-denied'});
});
test('forged points ignored; concurrent confirmations award once; interval enforced',async()=>{
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'agree'}});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'ready'}});
  const call={auth:auth('receiver'),data:{requestId:'request',donorId:'donor',points:999999}};
  const results=await Promise.all([workflows.confirmDonation(call),workflows.confirmDonation(call)]);
  assert.equal(results[0].donationId,results[1].donationId);
  assert.equal((await admin.firestore().doc('users/donor').get()).data().rewardPoints,50);
  assert.equal((await admin.firestore().collection('donations').get()).size,1);
  await admin.firestore().doc('blood_requests/second').set(requestData);
  await assert.rejects(workflows.acceptDonation({auth:auth('donor'),data:{requestId:'second'}}),{code:'failed-precondition'});
});
test('deletion checks recent authentication and cleans private data, requests and files',async()=>{
  await assert.rejects(workflows.deleteAccount({auth:{uid:'donor',token:{auth_time:1}}}),{code:'failed-precondition'});
  await assert.rejects(workflows.deleteAccount({auth:auth('other'),data:{uid:'donor'}},true),{code:'permission-denied'});
  await admin.auth().createUser({uid:'delete-me',email:'delete-me@example.test'});
  await admin.firestore().doc('users/delete-me').set(profile('delete-me'));
  await admin.firestore().doc('users/delete-me/private/device').set({fcmToken:'test'});
  await admin.firestore().doc('notifications/delete-me').set({userId:'delete-me'});
  await admin.storage().bucket().file('profile_images/delete-me/avatar.jpg').save(Buffer.from('test'));
  await workflows.deleteAccount({auth:auth('delete-me')});
  assert.equal((await admin.firestore().doc('users/delete-me').get()).exists,false);
  assert.equal((await admin.firestore().doc('users/delete-me/private/device').get()).exists,false);
  assert.equal((await admin.storage().bucket().file('profile_images/delete-me/avatar.jpg').exists())[0],false);
  await assert.rejects(admin.auth().getUser('delete-me'),{code:'auth/user-not-found'});
});
test('storage restricts profile uploads and requires a confirmed donation for certificates',async()=>{
  const donor=env.authenticatedContext('donor').storage();
  const other=env.authenticatedContext('other').storage();
  await assertSucceeds(donor.ref('profile_images/donor/audit.png').put(Buffer.from('image'),{contentType:'image/png'}));
  await assertFails(other.ref('profile_images/donor/other.png').put(Buffer.from('image'),{contentType:'image/png'}));
  await assertFails(donor.ref('profile_images/donor/text.txt').put(Buffer.from('text'),{contentType:'text/plain'}));
  await assertFails(donor.ref('certificates/donor/missing/certificate.pdf').put(Buffer.from('pdf'),{contentType:'application/pdf'}));
  await admin.firestore().doc('donations/confirmed').set({donorId:'donor'});
  await assertSucceeds(donor.ref('certificates/donor/confirmed/certificate.pdf').put(Buffer.from('pdf'),{contentType:'application/pdf'}));
});

test('private profiles, patient data, donations and SOS coordinates are not readable by unrelated users',async()=>{
  await admin.firestore().doc('blood_requests/request').update({patientName:'Private patient',contactNumber:'+923001234567',latitude:31.123456,longitude:74.123456});
  await admin.firestore().doc('donations/private').set({donorId:'donor',requesterId:'receiver'});
  await admin.firestore().doc('sosRequests/private').set({receiverId:'receiver',latitude:31.123456});
  const other=env.authenticatedContext('other').firestore();
  for(const path of ['users/donor','blood_requests/request','donations/private','sosRequests/private'])await assertFails(getDoc(doc(other,path)));
  const summary=await workflows.getRequest({auth:auth('other'),data:{requestId:'request'}});
  for(const key of ['patientName','contactNumber','latitude','longitude','requesterPhone','reason'])assert.equal(summary[key],undefined);
  await assertSucceeds(getDoc(doc(env.authenticatedContext('receiver').firestore(),'blood_requests/request')));
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await assertFails(getDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/request')));
});

test('privacy cutover protects existing participant records without changing stored data',async()=>{
  const ref=admin.firestore().doc('blood_requests/request');
  const secrets={patientName:'PRIVATE_PATIENT',patientAge:42,patientGender:'private',reason:'PRIVATE_REASON',notes:'PRIVATE_NOTES',contactNumber:'PRIVATE_CONTACT',requesterPhone:'PRIVATE_PHONE',requesterName:'PRIVATE_OWNER',reviewNote:'PRIVATE_REVIEW',clarificationReply:'PRIVATE_REPLY',futureSensitiveField:'PRIVATE_FUTURE'};
  await ref.update({...secrets,quantity:2,participantIds:['receiver','donor','other'],acceptedDonorIds:['donor','other'],commitments:{donor:{status:'accepted',phone:'PRIVATE_ASSIGNMENT'},other:{status:'accepted',name:'PRIVATE_PEER'}}});
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  const before=(await ref.get()).data();
  for(const uid of ['donor','other']){
    const client=env.authenticatedContext(uid).firestore();
    await assertFails(getDoc(doc(client,ref.path)));
    await assertFails(getDocs(query(collection(client,'blood_requests'),where('participantIds','array-contains',uid))));
    await assertFails(updateDoc(doc(client,ref.path),{patientName:'tamper',requesterId:uid}));
    await assertFails(setDoc(doc(client,`${ref.path}/private/contact`),{phone:'tamper'}));
    const view=await workflows.getRequest({auth:auth(uid),data:{requestId:'request'}});
    assert.equal(view.canViewPrivate,false);
    assert.equal(view.requesterId,'receiver');
    assert.equal(view.commitments[uid].status,'accepted');
    assert.deepEqual(Object.keys(view.commitments),[uid]);
    assert.ok(!JSON.stringify(view).includes('PRIVATE_'));
    const page=await workflows.participantRequests({auth:auth(uid),data:{mode:'active',donorId:'receiver'}});
    assert.deepEqual(page.items.map(i=>i.id),['request']);
    assert.ok(!JSON.stringify(page).includes('PRIVATE_'));
  }
  for(const uid of ['receiver','admin']){
    await assertSucceeds(getDoc(doc(env.authenticatedContext(uid).firestore(),ref.path)));
    const view=await workflows.getRequest({auth:auth(uid),data:{requestId:'request'}});
    for(const [key,value] of Object.entries(secrets))assert.equal(view[key],value);
    await assertFails(updateDoc(doc(env.authenticatedContext(uid).firestore(),ref.path),{patientName:'direct write'}));
  }
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),ref.path)));
  assert.deepEqual((await ref.get()).data(),before,'read-only compatibility cutover must preserve every legacy field');
});

test('private contact and events remain owner/admin-only after acceptance',async()=>{
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  await admin.firestore().doc('blood_requests/request/private/contact').set({phone:'PRIVATE'});
  await admin.firestore().doc('blood_requests/request/events/private-event').set({detail:'PRIVATE'});
  for(const path of ['blood_requests/request/private/contact','blood_requests/request/events/private-event','users/receiver/private/contact']){
    for(const uid of ['donor','other'])await assertFails(getDoc(doc(env.authenticatedContext(uid).firestore(),path)));
    for(const uid of ['receiver','admin'])await assertSucceeds(getDoc(doc(env.authenticatedContext(uid).firestore(),path)));
  }
});

test('legacy single-donor assignments and completed responses survive private-root cutover',async()=>{
  await admin.firestore().doc('blood_requests/legacy').set({...requestData,acceptedDonorId:'donor',status:'accepted',patientName:'PRIVATE'});
  let page=await workflows.participantRequests({auth:auth('donor'),data:{mode:'active'}});
  assert.ok(page.items.some(i=>i.id==='legacy'));
  assert.equal((await workflows.getRequest({auth:auth('donor'),data:{requestId:'legacy'}})).commitments.donor.status,'accepted');
  await admin.firestore().doc('blood_requests/legacy').update({status:'fulfilled',commitments:{donor:{status:'completed'}},participantIds:['receiver','donor']});
  page=await workflows.participantRequests({auth:auth('donor'),data:{mode:'responses'}});
  assert.equal(page.items.find(i=>i.id==='legacy').responseStatus,'completed');
  assert.equal((await workflows.participantRequests({auth:auth('donor'),data:{mode:'active'}})).items.length,0);
  // Switching capability off must never turn participant access into private access.
  await admin.firestore().doc('users/donor').update({isDonor:false,isReceiver:true,role:'receiver'});
  const view=await workflows.getRequest({auth:auth('donor'),data:{requestId:'legacy'}});
  assert.equal(view.canViewPrivate,false);assert.equal(view.patientName,undefined);
});

test('participant paging is auth-scoped, bounded, rejects invalid cursors and inactive users',async()=>{
  const batch=admin.firestore().batch();
  for(let i=0;i<35;i++)batch.set(admin.firestore().doc(`blood_requests/page-${String(i).padStart(2,'0')}`),{...requestData,participantIds:['receiver','donor'],acceptedDonorIds:['donor'],commitments:{donor:{status:'accepted'}},patientName:'PRIVATE'});
  await batch.commit();
  const first=await workflows.participantRequests({auth:auth('donor'),data:{mode:'active'}});
  const second=await workflows.participantRequests({auth:auth('donor'),data:{mode:'active',cursor:first.cursor}});
  assert.equal(first.items.length,30);assert.equal(second.items.length,5);assert.equal(second.cursor,null);
  assert.equal(new Set([...first.items,...second.items].map(i=>i.id)).size,35);
  assert.equal((await workflows.participantRequests({auth:auth('other'),data:{mode:'active',uid:'donor'}})).items.length,0);
  for(const cursor of ['',22,'bad/path'])await assert.rejects(workflows.participantRequests({auth:auth('donor'),data:{mode:'active',cursor}}),{code:'invalid-argument'});
  await assert.rejects(workflows.participantRequests({auth:auth('donor'),data:{mode:'all'}}),{code:'invalid-argument'});
  await assert.rejects(workflows.participantRequests({data:{mode:'active'}}),{code:'unauthenticated'});
  await admin.firestore().doc('users/donor').update({status:'suspended'});
  await assert.rejects(workflows.participantRequests({auth:auth('donor'),data:{mode:'active'}}),{code:'permission-denied'});
  await assert.rejects(workflows.getRequest({auth:auth('donor'),data:{requestId:'page-00'}}),{code:'permission-denied'});
});

test('two units require two contributions; concurrent retries cannot over-credit or fulfill early',async()=>{
  await admin.firestore().doc('blood_requests/request').update({quantity:2,remainingUnits:2});
  await Promise.all(['donor','other'].map(donor=>workflows.acceptDonation({auth:auth(donor),data:{requestId:'request'}})));
  for (const donor of ['donor','other']) {
    await workflows.updateAssignment({auth:auth(donor),data:{requestId:'request',action:'agree'}});
    await workflows.updateAssignment({auth:auth(donor),data:{requestId:'request',action:'ready'}});
  }
  const confirm=donorId=>workflows.confirmDonation({auth:auth('receiver'),data:{requestId:'request',donorId}});
  await assert.rejects(workflows.confirmDonation({auth:auth('donor'),data:{requestId:'request',donorId:'donor'}}),{code:'permission-denied'});
  await Promise.all([confirm('donor'),confirm('donor')]);
  let r=(await admin.firestore().doc('blood_requests/request').get()).data();
  assert.equal(r.status,'partially_fulfilled');assert.equal(r.donatedUnits,1);assert.equal(r.remainingUnits,1);
  await confirm('other');
  r=(await admin.firestore().doc('blood_requests/request').get()).data();
  assert.equal(r.status,'fulfilled');assert.equal(r.remainingUnits,0);
  assert.equal((await admin.firestore().collection('donations').get()).size,2);
  for(const donor of ['donor','other'])assert.equal((await admin.firestore().doc(`users/${donor}`).get()).data().rewardPoints,50);
});

test('capacity, one active assignment, withdrawal, release and reassignment',async()=>{
  const accept=donor=>workflows.acceptDonation({auth:auth(donor),data:{requestId:'request'}});
  await accept('donor');
  await assert.rejects(accept('other'),{code:'failed-precondition'});
  await admin.firestore().doc('blood_requests/second').set(requestData);
  await assert.rejects(workflows.acceptDonation({auth:auth('donor'),data:{requestId:'second'}}),{code:'failed-precondition'});
  await assert.rejects(
    workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'ready'}}),
    {code:'failed-precondition'},
  );
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'agree'}});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'ready'}});
  assert.equal((await admin.firestore().doc('blood_requests/request').get()).data().commitments.donor.status,'awaiting_confirmation');
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'withdraw'}});
  await assertFails(getDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/request')));
  assert.equal((await admin.firestore().doc('users/donor').get()).data().activeRequestId,undefined);
  await accept('other');
  await assert.rejects(workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',donorId:'other',action:'release'}}),{code:'permission-denied'});
  await workflows.updateAssignment({auth:auth('receiver'),data:{requestId:'request',donorId:'other',action:'release'}});
  await accept('donor');
  assert.deepEqual((await admin.firestore().doc('blood_requests/request').get()).data().acceptedDonorIds,['donor']);
});

test('donor agreement is separate from actual donation confirmation',async()=>{
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'agree'}});
  let r=(await admin.firestore().doc('blood_requests/request').get()).data();
  assert.equal(r.commitments.donor.status,'agreed');
  await assert.rejects(workflows.confirmDonation({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}}),{code:'failed-precondition'});
  await workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'ready'}});
  await workflows.confirmDonation({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}});
  r=(await admin.firestore().doc('blood_requests/request').get()).data();
  assert.equal(r.commitments.donor.status,'completed');
});

test('expired requests cannot accept or complete and scheduled cleanup releases donors',async()=>{
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('blood_requests/request').update({requiredBy:admin.firestore.Timestamp.fromMillis(Date.now()-1000)});
  await assert.rejects(workflows.acceptDonation({auth:auth('other'),data:{requestId:'request'}}),{code:'failed-precondition'});
  await assert.rejects(workflows.updateAssignment({auth:auth('donor'),data:{requestId:'request',action:'agree'}}),{code:'failed-precondition'});
  await assert.rejects(workflows.confirmDonation({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}}),{code:'failed-precondition'});
  await workflows.expireRequests();
  assert.equal((await admin.firestore().doc('blood_requests/request').get()).data().status,'expired');
  assert.equal((await admin.firestore().doc('users/donor').get()).data().activeRequestId,undefined);
});

test('SOS response shares location only after acceptance and owner can resolve/cancel',async()=>{
  const sos=await workflows.createSosAlert({auth:auth('receiver'),data:{latitude:31.123456,longitude:74.123456,bloodGroup:'O+',urgency:'critical',contactNumber:'+923001234567'}});
  const alert=await workflows.getSos({auth:auth('receiver'),data:{sosId:sos.id}});
  assert.equal(alert.latitude,undefined);assert.equal(alert.requestId,sos.requestId);
  await assert.rejects(workflows.getSos({auth:auth('donor'),data:{sosId:sos.id}}),{code:'permission-denied'});
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:sos.requestId}});
  assert.equal((await workflows.getRequest({auth:auth('donor'),data:{requestId:sos.requestId}})).latitude,31.123456);
  await assert.rejects(workflows.resolveSos({auth:auth('other'),data:{sosId:sos.id}}),{code:'permission-denied'});
  await workflows.resolveSos({auth:auth('receiver'),data:{sosId:sos.id,cancel:true}});
  assert.equal((await admin.firestore().doc(`sosRequests/${sos.id}`).get()).data().status,'cancelled');
  assert.equal((await admin.firestore().doc(`blood_requests/${sos.requestId}`).get()).data().status,'cancelled');
  assert.equal((await admin.firestore().doc('users/donor').get()).data().activeRequestId,undefined);
});

test('acceptance never discloses phone and discovery never includes private profile fields',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31,longitude:74,address:'Private address'});
  await admin.firestore().doc('users/donor/private/contact').set({phoneNumber:'+923001234567'});
  const discovery=await workflows.findDonors({auth:auth('receiver'),data:{latitude:31,longitude:74,bloodGroup:'O+',radiusKm:15}});
  assert.equal(discovery.donors.length,1);
  for(const key of ['email','address','phoneNumber','lastDonationDate'])assert.equal(discovery.donors[0][key],undefined);
  const lookup={auth:auth('receiver'),data:{donorId:'donor',requestId:'request'}};
  await assert.rejects(workflows.getDonorContact(lookup),{code:'permission-denied'});
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await assert.rejects(workflows.getDonorContact(lookup),{code:'permission-denied'});
  await assert.rejects(workflows.getDonorContact({...lookup,auth:auth('other')}),{code:'permission-denied'});
});

test('discovery and personal export paginate beyond 100 records without exposing private data',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31,longitude:74});
  const batch=admin.firestore().batch();
  for(let i=0;i<125;i++)batch.set(admin.firestore().doc(`blood_requests/page-${String(i).padStart(3,'0')}`),{...requestData,patientName:'Private',latitude:31,longitude:74,requiredBy:admin.firestore.Timestamp.fromMillis(Date.now()+3600000)});
  await batch.commit();
  let cursor,items=[];
  do{const page=await workflows.discoverRequests({auth:auth('donor'),data:{cursor}});items.push(...page.items);cursor=page.cursor;}while(cursor);
  assert.equal(items.length,125);assert.ok(items.every(r=>!('patientName' in r)));
  items=[];cursor=null;
  do{const page=await require('../adminWorkflows').exportPage({auth:auth('receiver'),data:{collection:'blood_requests',cursor}});items.push(...page.items);cursor=page.cursor;}while(cursor);
  assert.equal(items.length,126);
  await assert.rejects(require('../adminWorkflows').exportPage({auth:auth('receiver'),data:{collection:'users',admin:true}}),{code:'permission-denied'});
});

test('admin mutations are validated and audited; feedback is separate from misuse reports',async()=>{
  const a=require('../adminWorkflows');
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  await assert.rejects(a.adminAction({auth:auth('donor'),data:{collection:'users',id:'other',updates:{status:'rejected'}}}),{code:'permission-denied'});
  await assert.rejects(a.adminAction({auth:auth('admin'),data:{collection:'users',id:'other',updates:{role:'admin'}}}),{code:'invalid-argument'});
  await a.adminAction({auth:auth('admin'),data:{collection:'users',id:'other',updates:{status:'rejected'}}});
  assert.equal((await admin.firestore().collection('audit_logs').get()).size,1);
  const report=await a.submitReport({auth:auth('receiver'),data:{title:'Help',description:'Support request',feedback:true}});
  assert.equal((await admin.firestore().collection('misuse_reports').get()).size,0);
  await a.adminAction({auth:auth('admin'),data:{collection:'feedback',id:report.id,updates:{status:'resolved'}}});
  assert.equal((await admin.firestore().doc(`feedback/${report.id}`).get()).data().status,'resolved');
  await assertFails(setDoc(doc(env.authenticatedContext('receiver').firestore(),'audit_logs/forged'),{action:'fake'}));
});

test('device registrations are isolated from other accounts and from each other',async()=>{
  const db=env.authenticatedContext('donor').firestore();
  await assertSucceeds(setDoc(doc(db,'users/donor/devices/one'),{fcmToken:'one'}));
  await assertSucceeds(setDoc(doc(db,'users/donor/devices/two'),{fcmToken:'two'}));
  await assertFails(getDoc(doc(env.authenticatedContext('other').firestore(),'users/donor/devices/one')));
  await assertSucceeds(deleteDoc(doc(db,'users/donor/devices/one')));
  assert.equal((await getDoc(doc(db,'users/donor/devices/two'))).data().fcmToken,'two');
});

test('not-ready state is owner-only, idempotent, and never exposes contact data',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31,longitude:74});
  const result=await voice.markDonorNotReady({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}});
  assert.equal(result.marked,true);
  await voice.markDonorNotReady({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}});
  const state=(await admin.firestore().doc('blood_requests/request/notReadyDonors/donor').get()).data();
  assert.equal(state.phoneNumber,undefined); assert.equal(state.contact,undefined);
  await assert.rejects(voice.markDonorNotReady({auth:auth('other'),data:{requestId:'request',donorId:'donor'}}),{code:'permission-denied'});
  await assertFails(getDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/request/notReadyDonors/donor')));
  await assertFails(setDoc(doc(env.authenticatedContext('receiver').firestore(),'blood_requests/request/notReadyDonors/forged'),{donorId:'donor'}));
});

test('busy donor call is rejected and free donor call remains subject to provider configuration',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31,longitude:74});
  await admin.firestore().doc('blood_requests/request').update({latitude:31,longitude:74});
  await admin.firestore().doc('callSessions/active').set({participantIds:['receiver','donor'],status:'ringing',expiresAt:admin.firestore.Timestamp.fromMillis(Date.now()+60000)});
  await assert.rejects(voice.createVoiceCallSession({auth:auth('receiver'),data:{requestId:'request',calleeId:'donor'}}),{code:'resource-exhausted'});
});

test('awareness campaigns are admin managed, donor-only, scheduled and deduplicated',async()=>{
  const a=require('../awarenessWorkflows');
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  const data={en:{title:'Help nearby',description:'Explore requests',button:'Explore'},ur:{title:'مدد کریں',description:'درخواستیں دیکھیں',button:'دیکھیں'},action:'requests',active:true,priority:10,startAt:Date.now()-1000,endAt:Date.now()+3600000};
  await assert.rejects(a.manageAwarenessBanner({auth:auth('donor'),data}),{code:'permission-denied'});
  const {id}=await a.manageAwarenessBanner({auth:auth('admin'),data});
  assert.equal((await a.donorAwarenessBanners({auth:auth('receiver')})).items.length,0);
  await admin.firestore().doc('users/receiver').update({isDonor:true});
  assert.equal((await a.donorAwarenessBanners({auth:auth('receiver')})).items.length,0);
  const feed=await a.donorAwarenessBanners({auth:auth('donor')});
  assert.equal(feed.items.length,1);
  const event={auth:auth('donor'),data:{id,revision:1,event:'view'}};
  await Promise.all([a.recordBannerEvent(event),a.recordBannerEvent(event)]);
  assert.equal((await admin.firestore().doc(`awareness_banners/${id}`).get()).data().views,1);
  await assert.rejects(a.recordBannerEvent({...event,auth:auth('receiver')}),{code:'permission-denied'});
  await assertFails(setDoc(doc(env.authenticatedContext('donor').firestore(),`awareness_banners/${id}`),data));
  await assertFails(getDoc(doc(env.authenticatedContext('receiver').firestore(),`awareness_banners/${id}`)));
  await assertSucceeds(getDoc(doc(env.authenticatedContext('admin').firestore(),`awareness_banners/${id}`)));
  await a.manageAwarenessBanner({auth:auth('admin'),data:{...data,id,active:false}});
  assert.equal((await a.donorAwarenessBanners({auth:auth('donor')})).items.length,0);
  assert.equal((await a.recordBannerEvent(event)).recorded,false);
});

test('donor invitations are private and omit answered or closed requests',async()=>{
  const {donorInvitations}=require('../donorInvitations');
  await admin.firestore().doc('blood_requests/request/invites/donor').set({donorId:'donor',requesterId:'receiver',status:'invited'});
  await admin.firestore().doc('notifications/invite_request_donor').set({userId:'donor',type:'donor_invite',requestId:'request'});
  assert.equal((await donorInvitations({auth:auth('donor'),data:{}})).items.length,1);
  assert.equal((await donorInvitations({auth:auth('other'),data:{}})).items.length,0);
  const path='blood_requests/request/invites/donor';
  await assertSucceeds(getDoc(doc(env.authenticatedContext('donor').firestore(),path)));
  await assertSucceeds(getDoc(doc(env.authenticatedContext('receiver').firestore(),path)));
  await assertFails(getDoc(doc(env.authenticatedContext('other').firestore(),path)));
  await assertFails(updateDoc(doc(env.authenticatedContext('donor').firestore(),path),{status:'confirmed'}));
  await admin.firestore().doc(path).update({status:'confirmed'});
  assert.equal((await donorInvitations({auth:auth('donor'),data:{}})).items.length,0);
  await admin.firestore().doc(path).update({status:'invited'});
  await admin.firestore().doc('blood_requests/request').update({status:'cancelled'});
  assert.equal((await donorInvitations({auth:auth('donor'),data:{}})).items.length,0);
});

test('donor search continues after a result limit without skipping the rest of a page',async()=>{
  const {nearbyDonorsPaged}=require('../nearbyDonors');
  for(const uid of ['donor','other']) await admin.firestore().doc(`users/${uid}`).update({latitude:31,longitude:74,locationSharingEnabled:true});
  const first=await nearbyDonorsPaged(31,74,'O+',5,null,1);
  assert.equal(first.matches.length,1); assert.ok(first.cursor);
  const second=await nearbyDonorsPaged(31,74,'O+',5,first.cursor,1);
  assert.equal(second.matches.length,1);
  assert.notEqual(first.matches[0].uid,second.matches[0].uid);
  assert.equal(second.cursor,null);
});

test('banner image uploads are administrator-only and limited to image formats',async()=>{
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  const donor=env.authenticatedContext('donor').storage();
  const manager=env.authenticatedContext('admin').storage();
  await assertFails(donor.ref('awareness_banners/donor.png').put(Buffer.from('image'),{contentType:'image/png'}));
  await assertFails(manager.ref('awareness_banners/file.txt').put(Buffer.from('text'),{contentType:'text/plain'}));
  await assertSucceeds(manager.ref('awareness_banners/admin.png').put(Buffer.from('image'),{contentType:'image/png'}));
});

test('invitations apply compatibility from donor to recipient',async()=>{
  await admin.firestore().doc('blood_requests/request').update({bloodGroup:'A+'});
  assert.equal((await voice.inviteDonor({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}})).invited,true);
});

test('donor cursors reject malformed and out-of-band values', async()=>{
  const {nearbyDonorsPaged}=require('../nearbyDonors');
  for(const cursor of ['', '|donor','31|donor|','31|donor||','31|','31|a/b','31|..','NaN|donor','90|donor',{},42]) {
    await assert.rejects(nearbyDonorsPaged(31,74,'O+',5,cursor,1),{code:'invalid-argument'});
  }
});

test('donor pagination spans full pages without gaps or duplicate donors',async()=>{
  const {nearbyDonorsPaged}=require('../nearbyDonors');
  const batch=admin.firestore().batch();
  for(let i=0;i<205;i++) {
    const uid=`paged${String(i).padStart(3,'0')}`;
    batch.set(admin.firestore().doc(`users/${uid}`),{...profile(uid),latitude:31,longitude:74,locationSharingEnabled:true});
  }
  await batch.commit();
  const found=[];let cursor=null;
  do {
    const page=await nearbyDonorsPaged(31,74,'O+',5,cursor,100);
    found.push(...page.matches.map(d=>d.uid));cursor=page.cursor;
    assert.ok(found.length<=205);
  } while(cursor);
  assert.equal(found.length,205);assert.equal(new Set(found).size,205);
});

test('invitation continuation is private and independent of deleted notifications',async()=>{
  const {donorInvitations}=require('../donorInvitations');
  const batch=admin.firestore().batch();
  for(let i=0;i<31;i++) {
    const id=`invitepage${String(i).padStart(2,'0')}`;
    batch.set(admin.firestore().doc(`blood_requests/${id}`),requestData);
    batch.set(admin.firestore().doc(`blood_requests/${id}/invites/donor`),{donorId:'donor',requesterId:'receiver',status:'invited'});
  }
  await batch.commit();
  const first=await donorInvitations({auth:auth('donor'),data:{}});
  const last=await donorInvitations({auth:auth('donor'),data:{cursor:first.cursor}});
  assert.equal(first.items.length,30);assert.equal(last.items.length,1);assert.equal(last.cursor,null);
  assert.equal(new Set([...first.items,...last.items].map(d=>d.id)).size,31);
  await assert.rejects(donorInvitations({auth:auth('donor'),data:{cursor:'invalid'}}),{code:'invalid-argument'});
});
