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
  assert.equal((await admin.firestore().doc('notifications/accepted_request_donor').get()).data().userId,'receiver');
  const confirm={auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}};
  await workflows.confirmDonation(confirm);
  await workflows.confirmDonation(confirm);
  assert.equal((await admin.firestore().collection('notifications').get()).size,3);
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
  await workflows.closeRequest({auth:auth('receiver'),data:{requestId:'request'}});
  await assertFails(updateDoc(ref,{status:'pending'}));
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
  await assertSucceeds(getDoc(doc(env.authenticatedContext('donor').firestore(),'blood_requests/request')));
});

test('two units require two contributions; concurrent retries cannot over-credit or fulfill early',async()=>{
  await admin.firestore().doc('blood_requests/request').update({quantity:2,remainingUnits:2});
  await Promise.all(['donor','other'].map(donor=>workflows.acceptDonation({auth:auth(donor),data:{requestId:'request'}})));
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

test('expired requests cannot accept or complete and scheduled cleanup releases donors',async()=>{
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  await admin.firestore().doc('blood_requests/request').update({requiredBy:admin.firestore.Timestamp.fromMillis(Date.now()-1000)});
  await assert.rejects(workflows.acceptDonation({auth:auth('other'),data:{requestId:'request'}}),{code:'failed-precondition'});
  await assert.rejects(workflows.confirmDonation({auth:auth('receiver'),data:{requestId:'request',donorId:'donor'}}),{code:'failed-precondition'});
  await workflows.expireRequests();
  assert.equal((await admin.firestore().doc('blood_requests/request').get()).data().status,'expired');
  assert.equal((await admin.firestore().doc('users/donor').get()).data().activeRequestId,undefined);
});

test('SOS response shares location only after acceptance and owner can resolve/cancel',async()=>{
  const sos=await workflows.createSosAlert({auth:auth('receiver'),data:{latitude:31.123456,longitude:74.123456,bloodGroup:'O+',urgency:'critical',contactNumber:'+923001234567'}});
  const alert=await workflows.getSos({auth:auth('donor'),data:{sosId:sos.id}});
  assert.equal(alert.latitude,undefined);assert.equal(alert.requestId,sos.requestId);
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:sos.requestId}});
  assert.equal((await workflows.getRequest({auth:auth('donor'),data:{requestId:sos.requestId}})).latitude,31.123456);
  await assert.rejects(workflows.resolveSos({auth:auth('other'),data:{sosId:sos.id}}),{code:'permission-denied'});
  await workflows.resolveSos({auth:auth('receiver'),data:{sosId:sos.id,cancel:true}});
  assert.equal((await admin.firestore().doc(`sosRequests/${sos.id}`).get()).data().status,'cancelled');
  assert.equal((await admin.firestore().doc(`blood_requests/${sos.requestId}`).get()).data().status,'cancelled');
  assert.equal((await admin.firestore().doc('users/donor').get()).data().activeRequestId,undefined);
});

test('contact is scoped to an assigned donor and discovery never includes private profile fields',async()=>{
  await admin.firestore().doc('users/donor').update({locationSharingEnabled:true,latitude:31,longitude:74,address:'Private address'});
  await admin.firestore().doc('users/donor/private/contact').set({phoneNumber:'+923001234567'});
  const discovery=await workflows.findDonors({auth:auth('receiver'),data:{latitude:31,longitude:74,bloodGroup:'O+',radiusKm:15}});
  assert.equal(discovery.donors.length,1);
  for(const key of ['email','address','phoneNumber','lastDonationDate'])assert.equal(discovery.donors[0][key],undefined);
  const lookup={auth:auth('receiver'),data:{donorId:'donor',requestId:'request'}};
  await assert.rejects(workflows.getDonorContact(lookup),{code:'permission-denied'});
  await workflows.acceptDonation({auth:auth('donor'),data:{requestId:'request'}});
  assert.equal((await workflows.getDonorContact(lookup)).phoneNumber,'+923001234567');
  await assert.rejects(workflows.getDonorContact({...lookup,auth:auth('other')}),{code:'permission-denied'});
});

test('discovery and personal export paginate beyond 100 records without exposing private data',async()=>{
  const batch=admin.firestore().batch();
  for(let i=0;i<125;i++)batch.set(admin.firestore().doc(`blood_requests/page-${String(i).padStart(3,'0')}`),{...requestData,patientName:'Private'});
  await batch.commit();
  let cursor,items=[];
  do{const page=await workflows.discoverRequests({auth:auth('donor'),data:{cursor}});items.push(...page.items);cursor=page.cursor;}while(cursor);
  assert.equal(items.length,126);assert.ok(items.every(r=>!('patientName' in r)));
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
