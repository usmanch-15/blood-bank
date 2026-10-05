const {test,before,after,beforeEach} = require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc,updateDoc,getDoc,deleteDoc,writeBatch}=require('firebase/firestore');
const admin=require('../firebaseAdmin');
if(!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIREBASE_STORAGE_EMULATOR_HOST) throw Error('Use emulators:exec. Production tests are forbidden.');
const projectId='demo-blood-bank';
admin.initializeApp({projectId,storageBucket:`${projectId}.appspot.com`});
const workflows=require('../secureWorkflows');
const {nearbyDonors}=require('../nearbyDonors');
let env;
const profile=(uid,role='donor')=>({uid,email:`${uid}@example.test`,name:'Test User',role,status:'approved',bloodGroup:'O+',isDonor:role==='donor',isReceiver:role==='receiver',isAvailable:true,locationSharingEnabled:false,latitude:null,longitude:null,rewardPoints:0,isEligible:true,lastDonationDate:null});
const requestData={requesterId:'receiver',status:'pending',bloodGroup:'O+',quantity:1,hospitalName:"Children's Hospital"};
const auth=uid=>({uid,token:{auth_time:Math.floor(Date.now()/1000)}});
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
  assert.equal((await admin.firestore().doc('notifications/accepted_request').get()).data().userId,'receiver');
  const confirm={auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}};
  await workflows.confirmDonation(confirm);
  await workflows.confirmDonation(confirm);
  assert.equal((await admin.firestore().collection('notifications').get()).size,3);
  assert.equal((await admin.firestore().doc('notifications/fulfilled_request').get()).data().userId,'receiver');
});
test('ordinary accounts cannot resolve unrelated SOS or perform admin edits',async()=>{
  await admin.firestore().doc('sosRequests/sos').set({receiverId:'receiver',isResolved:false});
  const db=env.authenticatedContext('donor').firestore();
  await assertFails(updateDoc(doc(db,'sosRequests/sos'),{isResolved:true}));
  await assertFails(updateDoc(doc(db,'users/receiver'),{name:'Edited by donor'}));
  await admin.firestore().doc('users/admin').set({...profile('admin'),role:'admin'});
  const adminDb=env.authenticatedContext('admin').firestore();
  await assertSucceeds(updateDoc(doc(adminDb,'sosRequests/sos'),{isResolved:true}));
  await assertFails(updateDoc(doc(adminDb,'users/admin'),{status:'rejected'}));
});
test('SOS creation validates ownership, urgency and limits before writing',async()=>{
  const data={latitude:31,longitude:74,bloodGroup:'O+',urgency:'life_threatening'};
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
  await assertSucceeds(updateDoc(ref,{status:'cancelled'}));
  await assertFails(updateDoc(ref,{status:'pending'}));
});
test('request creation requires receiver capability, valid coordinates and no forged recipients',async()=>{
  const valid={...requestData,latitude:31,longitude:74,notifiedDonors:[]};
  const receiverDb=env.authenticatedContext('receiver').firestore();
  await assertSucceeds(setDoc(doc(receiverDb,'blood_requests/new'),valid));
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
