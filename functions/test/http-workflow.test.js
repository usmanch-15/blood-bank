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
  const args={requestId:ref.id,donorId:donor.uid};
  assert.equal((await callable('confirmDonation',args)).status,401);
  assert.equal((await callable('confirmDonation',args,receiver.token)).status,200);
  const duplicate=await callable('confirmDonation',args,receiver.token);
  assert.equal(duplicate.status,200);
  assert.equal(duplicate.body.result.alreadyConfirmed,true);
  assert.equal((await ref.get()).data().status,'fulfilled');
  assert.equal((await admin.firestore().doc(`users/${donor.uid}`).get()).data().rewardPoints,50);
  assert.equal((await callable('adminDeleteUser',{uid:donor.uid},receiver.token)).status,403);
  const sos=await callable('createSosAlert',{bloodGroup:'O+',latitude:31,longitude:74,urgency:'critical'},receiver.token);
  assert.equal(sos.status,200);
  const record=(await admin.firestore().doc(`sosRequests/${sos.body.result.id}`).get()).data();
  assert.equal(record.receiverId,receiver.uid);
  assert.equal(record.urgency,'critical');
});
