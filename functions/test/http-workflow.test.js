const {test,after} = require('node:test');
const assert = require('node:assert/strict');
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080' ||
    process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099') {
  throw Error('Run only against the demo Firebase emulators.');
}
const admin = require('../firebaseAdmin');
admin.initializeApp({projectId:'demo-blood-bank',storageBucket:'demo-blood-bank.appspot.com'});
after(()=>admin.app().delete());
async function account(role) {
  const uid=`http-${role}-${Date.now()}`, email=`${uid}@example.test`;
  await admin.auth().createUser({uid,email,password:'DemoAudit!123',emailVerified:true});
  await admin.firestore().doc(`users/${uid}`).set({uid,email,name:`HTTP ${role}`,role,
    status:'approved',bloodGroup:'O+',isDonor:role==='donor',isReceiver:role==='receiver',
    isAvailable:role==='donor',locationSharingEnabled:false,latitude:null,longitude:null,
    rewardPoints:0,isEligible:true,lastDonationDate:null});
  const response=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key',{
    method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,password:'DemoAudit!123',returnSecureToken:true})});
  assert.equal(response.status,200);
  return {uid,token:(await response.json()).idToken};
}
async function callable(name,data,token) {
  const response=await fetch(`http://127.0.0.1:5001/demo-blood-bank/us-central1/${name}`,{
    method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},
    body:JSON.stringify({data})});
  return {status:response.status,body:await response.json()};
}
test('real Auth JWTs and callable HTTP endpoints complete the request lifecycle',async()=>{
  const donor=await account('donor'),receiver=await account('receiver');
  const ref=admin.firestore().collection('blood_requests').doc();
  await ref.set({requesterId:receiver.uid,bloodGroup:'O+',hospitalName:'HTTP Audit Hospital',
    quantity:1,status:'pending',latitude:31,longitude:74,createdAt:admin.firestore.Timestamp.now()});
  assert.equal((await callable('acceptDonation',{requestId:ref.id},donor.token)).status,200);
  const active=await callable('participantRequests',{mode:'active'},donor.token);
  assert.equal(active.status,200);
  assert.ok(active.body.result.items.some(i=>i.id===ref.id));
  const donorView=await callable('getRequest',{requestId:ref.id},donor.token);
  assert.equal(donorView.status,200);
  assert.equal(donorView.body.result.canViewPrivate,false);
  assert.equal(donorView.body.result.requesterId,receiver.uid);
  assert.equal(typeof donorView.body.result.createdAt,'number');
  assert.equal((await callable('updateAssignment',{requestId:ref.id,action:'agree'},donor.token)).status,200);
  assert.equal((await callable('updateAssignment',{requestId:ref.id,action:'ready'},donor.token)).status,200);
  const args={requestId:ref.id,donorId:donor.uid};
  assert.equal((await callable('confirmDonation',args)).status,401);
  assert.equal((await callable('confirmDonation',args,receiver.token)).status,200);
  const duplicate=await callable('confirmDonation',args,receiver.token);
  assert.equal(duplicate.status,200);
  assert.equal(duplicate.body.result.alreadyConfirmed,true);
  assert.equal((await ref.get()).data().status,'fulfilled');
  assert.equal((await admin.firestore().doc(`users/${donor.uid}`).get()).data().rewardPoints,50);
  assert.equal((await callable('adminDeleteUser',{uid:donor.uid},receiver.token)).status,403);
  const sos=await callable('createSosAlert',{bloodGroup:'O+',latitude:31,longitude:74,urgency:'critical',contactNumber:'+923001234567',submissionId:`http-sos-${Date.now()}`},receiver.token);
  assert.equal(sos.status,200);
  const record=(await admin.firestore().doc(`sosRequests/${sos.body.result.id}`).get()).data();
  assert.equal(record.receiverId,receiver.uid);
  assert.equal(record.urgency,'critical');
  const reviewer=await account('admin');
  // Both dispute workflows write targetDonationId, including legacy records;
  // none requires the nonexistent reportType field.
  await admin.firestore().collection('misuse_reports').doc('legacy-dispute').set({status:'pending',targetDonationId:'legacy-donation'});
  await admin.firestore().collection('misuse_reports').doc('closed-dispute').set({status:'resolved',targetDonationId:'closed-donation'});
  await admin.firestore().collection('misuse_reports').doc('unrelated-report').set({status:'pending',targetConversationId:'conversation'});
  const analytics=await callable('adminAnalytics',{startMs:Date.now()-86400000,endMs:Date.now()+60000,forceRefresh:true},reviewer.token);
  assert.equal(analytics.status,200);
  assert.equal(analytics.body.result.counts.pending_review,1);
  assert.equal(analytics.body.result.counts.open,1);
  assert.equal(analytics.body.result.fulfilmentRate.denominator,2);
  assert.equal(analytics.body.result.openDonationDisputes,1);
  const rejected=await callable('reviewEmergencyRequest',{id:sos.body.result.id,sos:true,decision:'rejected',note:'Staging regression review'},reviewer.token);
  assert.equal(rejected.status,200);
  const linked=(await admin.firestore().doc(`blood_requests/${record.requestId}`).get()).data();
  assert.equal(linked.reviewStatus,'rejected');
  assert.equal(linked.status,'cancelled');
  assert.equal((await callable('acceptDonation',{requestId:record.requestId},donor.token)).status,400);
});
