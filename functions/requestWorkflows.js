const {HttpsError} = require('firebase-functions/v2/https');
const admin = require('./firebaseAdmin');
const {active, eligible, compatible, INTERVAL_MS, POINTS, distanceKm} = require('./donationPolicy');
const {nearbyDonors} = require('./nearbyDonors');
const db = admin.firestore();
const now = () => admin.firestore.Timestamp.now();
const fail = (code, message) => { throw new HttpsError(code, message); };
const openStatuses = ['pending', 'accepted', 'partially_fulfilled'];
function id(value) {
  if (typeof value !== 'string' || !value.length || value.length > 128 || value.includes('/')) fail('invalid-argument','Invalid identifier.');
  return value;
}
function uid(request) { if (!request.auth) fail('unauthenticated','Sign in first.'); return request.auth.uid; }
async function actor(request) {
  const caller = uid(request), user = (await db.doc(`users/${caller}`).get()).data();
  if (!active(user)) fail('permission-denied','Active account required.');
  return {...user, uid:caller};
}
const millis = value => value?.toMillis ? value.toMillis() : typeof value === 'number' ? value : 0;
const expired = r => millis(r.requiredBy) > 0 && millis(r.requiredBy) <= Date.now();
function assignments(r) {
  return r.commitments || (r.acceptedDonorId ? {[r.acceptedDonorId]: {status:'accepted', name:'Assigned donor'}} : {});
}
function participants(r) { return [...new Set([...(r.participantIds || []), r.requesterId, ...Object.keys(assignments(r)).filter(k => !['withdrawn','released'].includes(assignments(r)[k].status))])]; }
function assertOpen(r) { if (!r || !openStatuses.includes(r.status) || expired(r)) fail('failed-precondition','This request is closed or expired.'); }
function notification(tx, key, userId, requestId, title, body) {
  tx.set(db.doc(`notifications/${key}`), {userId, relatedId:requestId, type:'request_update', title, body, isRead:false, createdAt:now()});
}
function event(tx, ref, actorId, action, detail = '') {
  tx.create(ref.collection('events').doc(), {actorId, action, detail, createdAt:now()});
}
function text(value, max, required = false) {
  if (value == null && !required) return '';
  if (typeof value !== 'string' || value.trim().length > max || (required && !value.trim())) fail('invalid-argument','Check the required text fields.');
  return value.trim();
}
function coordinates(data) {
  if (!Number.isFinite(data.latitude) || Math.abs(data.latitude)>90 || !Number.isFinite(data.longitude) || Math.abs(data.longitude)>180) fail('invalid-argument','Select a valid hospital location.');
}
async function rateLimit(key, maximum, window = 3600000) {
  await db.runTransaction(async tx => {
    const ref = db.doc(`rate_limits/${key}`), d = (await tx.get(ref)).data();
    const times = (d?.timestamps || []).filter(t => t > Date.now()-window);
    if (times.length >= maximum) fail('resource-exhausted','Too many attempts. Please try again later.');
    tx.set(ref,{timestamps:[...times, Date.now()]});
  });
}
function requestData(data, user) {
  coordinates(data);
  if (!['A+','A-','B+','B-','AB+','AB-','O+','O-'].includes(data.bloodGroup)) fail('invalid-argument','Select a blood group.');
  const quantity = data.quantity;
  if (!Number.isInteger(quantity) || quantity<1 || quantity>50) fail('invalid-argument','Request 1–50 units.');
  const deadline = Number(data.requiredBy);
  if (!Number.isFinite(deadline) || deadline<=Date.now() || deadline>Date.now()+31*86400000) fail('invalid-argument','Select a future deadline within 31 days.');
  const urgency = text(data.urgency || 'normal',30).toLowerCase();
  if (!['normal','low','urgent','critical','life_threatening'].includes(urgency)) fail('invalid-argument','Invalid urgency.');
  const contact = text(data.contactNumber,20,true);
  if (!/^\+?[0-9]{10,15}$/.test(contact)) fail('invalid-argument','Enter a valid contact number.');
  const age = data.patientAge;
  if (age != null && (!Number.isInteger(age) || age<0 || age>130)) fail('invalid-argument','Invalid patient age.');
  return {requesterId:user.uid, requesterName:user.name || '', bloodGroup:data.bloodGroup,
    quantity, unitsRequired:quantity, donatedUnits:0, remainingUnits:quantity,
    hospitalName:text(data.hospitalName,100,true), hospitalAddress:text(data.hospitalAddress,300),
    location:text(data.hospitalAddress,300), latitude:data.latitude, longitude:data.longitude,
    patientName:text(data.patientName,100), patientAge:age ?? null, patientGender:text(data.patientGender,20),
    reason:text(data.reason,1000), contactNumber:contact, requesterPhone:contact, urgency,
    requiredBy:admin.firestore.Timestamp.fromMillis(deadline), createdAt:now(), status:'pending',
    participantIds:[user.uid], acceptedDonorIds:[], commitments:{}, notifiedDonors:[], schemaVersion:2};
}
async function createBloodRequest(request) {
  const user = await actor(request);
  if (!user.isReceiver) fail('permission-denied','Receiver account required.');
  const input = request.data || {};
  if (!input.contactNumber) input.contactNumber = (await db.doc(`users/${user.uid}/private/contact`).get()).data()?.phoneNumber;
  const data = requestData(input, user);
  // Client-generated ID makes retries of a successful submission idempotent.
  const requestId = id(request.data?.requestId), ref = db.doc(`blood_requests/${requestId}`);
  await rateLimit(`requests_${user.uid}`,20);
  await db.runTransaction(async tx => {
    const existing = await tx.get(ref);
    if (existing.exists) {
      if (existing.data().requesterId !== user.uid) fail('permission-denied','Request belongs to another account.');
      return;
    }
    tx.create(ref,data); event(tx,ref,user.uid,'created');
  });
  return {id:requestId};
}
async function acceptDonation(request) {
  const caller = uid(request), requestId = id(request.data?.requestId), ref = db.doc(`blood_requests/${requestId}`);
  return db.runTransaction(async tx => {
    const [snap, donorSnap] = await Promise.all([tx.get(ref), tx.get(db.doc(`users/${caller}`))]);
    const r=snap.data(), d=donorSnap.data();
    if (!active(d) || !d.isDonor || !d.isAvailable || !r || r.requesterId===caller) fail('permission-denied','Active available donor required.');
    const owner = (await tx.get(db.doc(`users/${r.requesterId}`))).data();
    if (!active(owner)) fail('permission-denied','Requester is inactive.');
    assertOpen(r);
    const commitments = assignments(r), mine = commitments[caller];
    if (['accepted','awaiting_confirmation'].includes(mine?.status)) return {accepted:true};
    if (mine?.status==='completed') fail('failed-precondition','You already contributed to this request.');
    if (d.activeRequestId && d.activeRequestId!==requestId) {
      const previous = (await tx.get(db.doc(`blood_requests/${d.activeRequestId}`))).data();
      if (previous && openStatuses.includes(previous.status) && !expired(previous)) fail('failed-precondition','Withdraw from your active donation first.');
    }
    if (!eligible(d,Date.now()) || !compatible(d.bloodGroup,r.bloodGroup)) fail('failed-precondition','Donation interval or blood group does not match.');
    const accepted = Object.keys(commitments).filter(k=>['accepted','awaiting_confirmation'].includes(commitments[k].status));
    if ((r.donatedUnits || 0)+accepted.length >= r.quantity) fail('failed-precondition','All remaining units have donor commitments.');
    commitments[caller]={status:'accepted',name:d.name || 'Donor',acceptedAt:now(),units:1};
    tx.update(ref,{commitments,acceptedDonorIds:[...accepted,caller],participantIds:[...new Set([...participants(r),caller])],status:r.donatedUnits ? 'partially_fulfilled':'accepted'});
    tx.update(donorSnap.ref,{activeRequestId:requestId});
    notification(tx,`accepted_${requestId}_${caller}`,r.requesterId,requestId,'Donor accepted',`${d.name || 'A donor'} committed one unit. Open request tracking.`);
    event(tx,ref,caller,'accepted');
    return {accepted:true};
  });
}
async function updateAssignment(request) {
  const caller=uid(request), requestId=id(request.data?.requestId), donorId=id(request.data?.donorId || caller);
  const action=request.data?.action, ref=db.doc(`blood_requests/${requestId}`);
  if (!['withdraw','release','ready'].includes(action)) fail('invalid-argument','Invalid assignment action.');
  return db.runTransaction(async tx=>{
    const [snap,u,donor]=await Promise.all([tx.get(ref),tx.get(db.doc(`users/${caller}`)),tx.get(db.doc(`users/${donorId}`))]);
    const r=snap.data(), user=u.data();
    if (!active(user) || !r) fail('permission-denied','Request unavailable.');
    const owner=caller===r.requesterId || user.role==='admin';
    if ((action==='release' && !owner) || (action!=='release' && caller!==donorId)) fail('permission-denied','Action not permitted.');
    const commitments=assignments(r), entry=commitments[donorId];
    if (!entry || !['accepted','awaiting_confirmation'].includes(entry.status)) fail('failed-precondition','No active assignment.');
    if (action==='ready') assertOpen(r);
    commitments[donorId]={...entry,status:action==='ready'?'awaiting_confirmation':action==='release'?'released':'withdrawn',updatedAt:now()};
    const accepted=Object.keys(commitments).filter(k=>['accepted','awaiting_confirmation'].includes(commitments[k].status));
    const updates={commitments,acceptedDonorIds:accepted};
    if (action!=='ready') {
      updates.participantIds=participants(r).filter(k=>k!==donorId);
      updates.acceptedDonorId=admin.firestore.FieldValue.delete();
      if (openStatuses.includes(r.status)) updates.status=expired(r)?'expired':r.donatedUnits?'partially_fulfilled':accepted.length?'accepted':'pending';
      if (donor.exists && donor.data().activeRequestId===requestId) tx.update(donor.ref,{activeRequestId:admin.firestore.FieldValue.delete()});
    }
    tx.update(ref,updates);
    notification(tx,`${action}_${requestId}_${donorId}`,owner?donorId:r.requesterId,requestId,action==='ready'?'Donation awaiting confirmation':'Assignment updated',action==='ready'?'Please confirm the donation after it has taken place.':'A donor assignment was released. Remaining units can be reassigned.');
    event(tx,ref,caller,action,donorId);
    return {updated:true};
  });
}
async function confirmDonation(request) {
  const caller=uid(request), requestId=id(request.data?.requestId), donorId=id(request.data?.donorId);
  const ref=db.doc(`blood_requests/${requestId}`), donorRef=db.doc(`users/${donorId}`);
  // Stable per-request/per-donor ID; never credit one donor twice.
  const donationRef=db.doc(`donations/${requestId}_${donorId}`);
  return db.runTransaction(async tx=>{
    const [snap,donor,user,existing,legacy]=await Promise.all([tx.get(ref),tx.get(donorRef),tx.get(db.doc(`users/${caller}`)),tx.get(donationRef),tx.get(db.doc(`donations/${requestId}`))]);
    const r=snap.data(),d=donor.data(),u=user.data();
    if (!active(u) || !active(d) || !r || (caller!==r.requesterId && u.role!=='admin')) fail('permission-denied','The requester or administrator must confirm completion.');
    if (existing.exists) return {donationId:existing.id,alreadyConfirmed:true};
    if (legacy.exists && legacy.data().donorId===donorId) return {donationId:legacy.id,alreadyConfirmed:true};
    assertOpen(r);
    const commitments=assignments(r), entry=commitments[donorId];
    // A requester/admin may only finalize a contribution after the donor has
    // explicitly marked the assignment ready. This prevents unilateral
    // completion, rewards, eligibility changes, and SOS resolution.
    if (!entry || entry.status !== 'awaiting_confirmation') fail('failed-precondition','The donor must confirm readiness first.');
    if (!d.isDonor || !eligible(d,Date.now()) || !compatible(d.bloodGroup,r.bloodGroup)) fail('failed-precondition','Donor interval or group does not match.');
    const total=(r.donatedUnits || 0)+1;
    if (total>r.quantity) fail('failed-precondition','Request is already filled.');
    const stamp=now(),next=admin.firestore.Timestamp.fromMillis(stamp.toMillis()+INTERVAL_MS);
    commitments[donorId]={...entry,status:'completed',completedAt:stamp,units:1};
    const accepted=Object.keys(commitments).filter(k=>['accepted','awaiting_confirmation'].includes(commitments[k].status));
    tx.create(donationRef,{donorId,requesterId:r.requesterId,donorName:d.name || '',bloodGroup:d.bloodGroup,donationDate:stamp,location:r.hospitalName,requestId,units:1,pointsEarned:POINTS,confirmedBy:caller});
    tx.update(donorRef,{lastDonationDate:stamp,nextEligibleDate:next,isEligible:false,rewardPoints:admin.firestore.FieldValue.increment(POINTS),activeRequestId:admin.firestore.FieldValue.delete()});
    tx.update(ref,{commitments,acceptedDonorIds:accepted,participantIds:participants(r),donatedUnits:total,remainingUnits:r.quantity-total,status:total===r.quantity?'fulfilled':'partially_fulfilled',...(total===r.quantity?{fulfilledAt:stamp}:{})});
    if (r.sosId && total===r.quantity) tx.update(db.doc(`sosRequests/${r.sosId}`),{isResolved:true,status:'resolved',resolvedAt:stamp});
    notification(tx,`donation_${requestId}_${donorId}`,donorId,requestId,'Donation confirmed',`One unit confirmed. You earned ${POINTS} points.`);
    notification(tx,`progress_${requestId}_${donorId}`,r.requesterId,requestId,total===r.quantity?'Request fulfilled':'Donation recorded',`${total} of ${r.quantity} units confirmed.`);
    event(tx,ref,caller,'donation_confirmed',donorId);
    return {donationId:donationRef.id,donatedUnits:total,remainingUnits:r.quantity-total};
  });
}
async function closeRequest(request) { return closeInternal(request,false); }
async function closeInternal(request, system) {
  const caller=uid(request), ref=db.doc(`blood_requests/${id(request.data?.requestId)}`);
  return db.runTransaction(async tx=>{
    const [snap,user]=await Promise.all([tx.get(ref),tx.get(db.doc(`users/${caller}`))]);
    const r=snap.data(),u=user.data();
    if (!r || (!system && (!active(u) || (r.requesterId!==caller && u.role!=='admin')))) fail('permission-denied','Only the requester or administrator can close this request.');
    if (system && !expired(r)) return {closed:false};
    if (!openStatuses.includes(r.status)) return {closed:true};
    const accepted=Object.keys(assignments(r)).filter(k=>['accepted','awaiting_confirmation'].includes(assignments(r)[k].status));
    const donors=await Promise.all(accepted.map(k=>tx.get(db.doc(`users/${k}`))));
    const status=expired(r)?'expired':'cancelled', commitments=assignments(r);
    for (const donor of donors) {
      commitments[donor.id]={...commitments[donor.id],status:'released'};
      if (donor.exists && donor.data().activeRequestId===ref.id) tx.update(donor.ref,{activeRequestId:admin.firestore.FieldValue.delete()});
      notification(tx,`closed_${ref.id}_${donor.id}`,donor.id,ref.id,'Request closed',`The request was ${status}. Your assignment has been released.`);
    }
    tx.update(ref,{status,commitments,acceptedDonorIds:[],closedAt:now()});
    if (r.sosId) tx.update(db.doc(`sosRequests/${r.sosId}`),{status,isResolved:true,resolvedAt:now()});
    event(tx,ref,caller,status);
    return {closed:true};
  });
}
function serialize(value) {
  if (value?.toMillis) return value.toMillis();
  if (Array.isArray(value)) return value.map(serialize);
  if (value && typeof value==='object') return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,serialize(v)]));
  return value;
}
function summary(r, requestId) {
  return serialize({id:requestId,bloodGroup:r.bloodGroup,hospitalName:r.hospitalName,quantity:r.quantity,donatedUnits:r.donatedUnits || 0,remainingUnits:r.remainingUnits ?? r.quantity,urgency:r.urgency,status:expired(r)&&openStatuses.includes(r.status)?'expired':r.status,requiredBy:r.requiredBy,createdAt:r.createdAt});
}
async function getRequest(request) {
  const user=await actor(request), requestId=id(request.data?.requestId), snap=await db.doc(`blood_requests/${requestId}`).get(),r=snap.data();
  if (!r) fail('not-found','Request no longer exists.');
  const permitted=user.role==='admin' || participants(r).includes(user.uid);
  if (!permitted && (!user.isDonor || !openStatuses.includes(r.status) || expired(r))) fail('permission-denied','Request is not available.');
  const donorParticipant = user.isDonor && participants(r).includes(user.uid);
  const donorView = donorParticipant ? {
    id:requestId, bloodGroup:r.bloodGroup, hospitalName:r.hospitalName,
    hospitalAddress:r.hospitalAddress, location:r.location, latitude:r.latitude,
    longitude:r.longitude, quantity:r.quantity, donatedUnits:r.donatedUnits || 0,
    remainingUnits:r.remainingUnits ?? r.quantity, urgency:r.urgency,
    status:expired(r)&&openStatuses.includes(r.status)?'expired':r.status,
    requiredBy:r.requiredBy, createdAt:r.createdAt, commitments:r.commitments,
    acceptedDonorIds:r.acceptedDonorIds, participantIds:r.participantIds
  } : null;
  return {...(permitted && !donorParticipant?serialize(r):donorView || summary(r,requestId)),id:requestId,canViewPrivate:permitted && !donorParticipant};
}
async function discoverRequests(request) {
  const user=await actor(request);
  if (!user.isDonor) fail('permission-denied','Donor account required.');
  let query=db.collection('blood_requests').orderBy(admin.firestore.FieldPath.documentId()).limit(40);
  if (request.data?.cursor) query=query.startAfter(id(request.data.cursor));
  const page=await query.get();
  const items=page.docs.filter(doc=>{const r=doc.data();return r.requesterId!==user.uid && openStatuses.includes(r.status) && !expired(r) && compatible(user.bloodGroup,r.bloodGroup) && eligible(user,Date.now()) && user.isAvailable;}).map(doc=>summary(doc.data(),doc.id));
  return {items,cursor:page.size===40?page.docs.at(-1).id:null};
}
async function findDonors(request) {
  const user=await actor(request), data=request.data || {}; coordinates(data);
  const radius=Math.min(50,Math.max(1,Number(data.radiusKm)||50));
  const ids=(await nearbyDonors(data.latitude,data.longitude,data.bloodGroup || null,radius)).filter(k=>k!==user.uid);
  const docs=await Promise.all(ids.map(k=>db.doc(`users/${k}`).get()));
  // Never return email, address, donation dates, patient info or exact coordinates.
  return {donors:docs.filter(doc=>doc.exists).map(doc=>{const d=doc.data();return {uid:doc.id,name:d.name,bloodGroup:d.bloodGroup,isEligible:true,isAvailable:true,status:'approved',latitude:Math.round(d.latitude*100)/100,longitude:Math.round(d.longitude*100)/100,distanceKm:distanceKm(data.latitude,data.longitude,d.latitude,d.longitude)};}).sort((a,b)=>a.distanceKm-b.distanceKm)};
}
async function createSosAlert(request) {
  const user=await actor(request);
  if (!user.isReceiver) fail('permission-denied','Receiver account required.');
  const data=request.data || {}; coordinates(data);
  if (!['urgent','critical','life_threatening'].includes(data.urgency)) fail('invalid-argument','Choose an emergency level.');
  const privateContact=(await db.doc(`users/${user.uid}/private/contact`).get()).data();
  const r=requestData({...data,quantity:1,requiredBy:Date.now()+6*3600000,hospitalName:data.hospitalName || 'Emergency meeting point',contactNumber:data.contactNumber || privateContact?.phoneNumber},user);
  await rateLimit(`sos_${user.uid}`,3);
  const ref=db.collection('sosRequests').doc(), requestRef=db.collection('blood_requests').doc();
  const batch=db.batch();
  batch.create(requestRef,{...r,sosId:ref.id});
  batch.create(ref,{receiverId:user.uid,requestId:requestRef.id,bloodGroup:r.bloodGroup,latitude:r.latitude,longitude:r.longitude,urgency:r.urgency,triggerTime:now(),requiredBy:r.requiredBy,isResolved:false,status:'queued',notifiedDonors:[]});
  await batch.commit(); return {id:ref.id,requestId:requestRef.id};
}
async function getSos(request) {
  const user=await actor(request), snap=await db.doc(`sosRequests/${id(request.data?.sosId)}`).get(),s=snap.data();
  if (!s) fail('not-found','SOS no longer exists.');
  const linked = s.requestId ? (await db.doc(`blood_requests/${s.requestId}`).get()).data() : null;
  const participant = linked && participants(linked).includes(user.uid);
  if (s.receiverId!==user.uid && user.role!=='admin' && !participant) fail('permission-denied','SOS unavailable.');
  return {id:snap.id,requestId:s.requestId,bloodGroup:s.bloodGroup,urgency:s.urgency,status:s.status,isResolved:s.isResolved};
}
async function resolveSos(request) {
  const user=await actor(request), ref=db.doc(`sosRequests/${id(request.data?.sosId)}`),s=(await ref.get()).data();
  if (!s || (s.receiverId!==user.uid && user.role!=='admin')) fail('permission-denied','Only the owner can resolve this SOS.');
  if (s.requestId) await closeRequest({auth:request.auth,data:{requestId:s.requestId}});
  await ref.update({isResolved:true,status:request.data?.cancel?'cancelled':'resolved',resolvedAt:now()});
  return {resolved:true};
}
async function getDonorContact(request) {
  const user=await actor(request), donorId=id(request.data?.donorId), requestId=id(request.data?.requestId);
  const r=(await db.doc(`blood_requests/${requestId}`).get()).data();
  if (!r || (r.requesterId!==user.uid && user.role!=='admin') || !participants(r).includes(donorId)) fail('permission-denied','Contact is shared after a donor accepts your request.');
  await rateLimit(`contact_${user.uid}`,20);
  const contact=(await db.doc(`users/${donorId}/private/contact`).get()).data();
  await db.collection('audit_logs').add({action:'donor_contact_viewed',viewedBy:user.uid,donorId,requestId,createdAt:now()});
  return {phoneNumber:contact?.phoneNumber || null};
}
async function expireRequests() {
  // Page every open request; legacy records without deadlines stay visible for migration.
  let cursor;
  do {
    let q=db.collection('blood_requests').where('status','in',openStatuses).orderBy(admin.firestore.FieldPath.documentId()).limit(100);
    if(cursor)q=q.startAfter(cursor);
    const page=await q.get();
    for(const doc of page.docs)if(expired(doc.data()))await closeInternal({auth:{uid:'system'},data:{requestId:doc.id}},true);
    cursor=page.size===100?page.docs.at(-1).id:null;
  } while(cursor);
}
module.exports={createBloodRequest,acceptDonation,updateAssignment,confirmDonation,closeRequest,getRequest,discoverRequests,findDonors,createSosAlert,getSos,resolveSos,getDonorContact,actor,rateLimit,serialize,expired,openStatuses,expireRequests};
