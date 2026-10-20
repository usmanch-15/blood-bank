const admin=require('./firebaseAdmin');
const {nearbyDonors}=require('./nearbyDonors');
const {sendPushToUsers}=require('./notificationService');
async function notifyPendingEmergency(event){
  const snap=event.data, r=snap?.data(); if(!r||!['urgent','critical','life_threatening'].includes(r.urgency)||r.reviewStatus!=='pending_review') return;
  const ids=await nearbyDonors(r.latitude,r.longitude,r.bloodGroup,50);
  if(!ids.length) return;
  await sendPushToUsers(ids,{title:r.urgency==='critical'?'Critical blood request nearby':'Urgent blood request nearby',body:`${r.bloodGroup} blood needed. Approximate area only; request pending admin review.`,data:{type:'request_review',relatedId:event.params.requestId}});
}
module.exports={notifyPendingEmergency};
