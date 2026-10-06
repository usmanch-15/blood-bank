/**
 * ✅ PHASE 1 — Reliable FCM Push Service (Cloud Functions)
 *
 * Exports:
 *   sendPushToUser(uid, { title, body, data })
 *   sendPushToUsers(uids, { title, body, data })
 *
 * Behavior:
 *   - Reads the user's fcmToken + notificationPrefs from Firestore
 *   - Skips sending if notificationsEnabled == false, or if the
 *     specific category (data.type) is turned off in notificationPrefs
 *   - Retries transient failures up to 3 times with exponential backoff
 *   - On 'messaging/registration-token-not-registered' (dead token),
 *     removes the stale token from Firestore so we stop wasting sends
 *   - Writes a notification doc to the `notifications` collection so
 *     users see it in their in-app notification history
 *
 * ⚠️ IMPORTANT — pushSentDirectly flag:
 *   index.js also has an older `sendPushNotification` trigger that fires
 *   on ANY `notifications/{id}` doc creation and sends its own FCM push.
 *   Since this function ALSO writes a notification doc, without a guard
 *   every push sent through sendPushToUser() would go out to the device
 *   TWICE (once here, once via that trigger). We stamp `pushSentDirectly:
 *   true` on the doc we create so the old trigger knows to skip it.
 */

const admin = require('./firebaseAdmin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const messaging = admin.messaging();

const MAX_RETRIES = 3;
const RETRY_BASE_DELAY_MS = 500;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Determines whether this user currently wants to receive a push of the
 * given category, based on their Firestore notification preferences.
 *
 * @param {FirebaseFirestore.DocumentData} userData
 * @param {string|undefined} category e.g. 'sosAlerts' | 'rewardUpdates' |
 *   'adminAnnouncements'. If omitted, only the master switch is checked.
 */
function isNotificationAllowed(userData, category) {
  if (!userData || userData.status !== 'approved') return false;
  if (userData.notificationsEnabled === false) return false;
  if (!category) return true;

  const prefs = userData.notificationPrefs || {};
  // Default to true if the specific preference field doesn't exist yet
  // (so users who haven't touched Settings still get notified).
  const preference = category === 'donation_confirmed' ? 'rewardUpdates'
    : category === 'sos' ? 'sosAlerts' : category;
  return prefs[preference] !== false;
}

/**
 * Sends a single push notification to one user, with retry + dead-token
 * cleanup. Always writes a notification doc regardless of push success,
 * so the user can see it in-app even if the push itself failed.
 */
async function sendPushToUser(uid, { title, body, data = {}, record = true }) {
  const userRef=db.doc('users/'+uid),user=(await userRef.get()).data();
  if(!user)return {uid,sent:false,reason:'user-not-found'};
  let inbox;
  if(record){
    const key=require('node:crypto').createHash('sha256').update(uid+':'+(data.type||'general')+':'+(data.relatedId||data.requestId||title+body)).digest('hex');
    inbox=db.doc('notifications/'+key);
    try {await inbox.create({userId:uid,title,body,type:data.type||'general',relatedId:data.relatedId||data.requestId||null,isRead:false,createdAt:admin.firestore.Timestamp.now(),pushSentDirectly:true,pushStatus:'pending'});}
    catch(e){if(e.code!==6)throw e;if((await inbox.get()).data()?.pushStatus==='sent')return {uid,sent:true,reason:'already-sent'};}
  }
  if(!isNotificationAllowed(user,data.type)){if(inbox)await inbox.update({pushStatus:'opted_out'});return {uid,sent:false,reason:'user-opted-out'};}
  const devices=await userRef.collection('devices').get();
  const legacy=await userRef.collection('private').doc('device').get();
  const refs=[...devices.docs,...(legacy.exists?[legacy]:[])];
  const seen=new Set();let sent=false,attempted=false;
  for(const device of refs){
    const token=device.data()?.fcmToken;
    if(!token||seen.has(token))continue;seen.add(token);attempted=true;
    for(let attempt=0;attempt<MAX_RETRIES;attempt++){
      try{
        await messaging.send({token,notification:{title,body},data:Object.fromEntries(Object.entries(data).map(([k,v])=>[k,String(v)])),android:{priority:'high',notification:{channelId:'blood_requests',tag:data.relatedId||'blood-bank'}},apns:{headers:{'apns-priority':'10'}}});sent=true;break;
      }catch(e){
        if(['messaging/registration-token-not-registered','messaging/invalid-registration-token'].includes(e.code)){
          await db.runTransaction(async tx=>{const current=await tx.get(device.ref);if(current.data()?.fcmToken===token)tx.delete(device.ref);});break;
        }
        if(attempt<MAX_RETRIES-1)await sleep(RETRY_BASE_DELAY_MS*Math.pow(2,attempt));
      }
    }
  }
  if(inbox)await inbox.update({pushStatus:sent?'sent':attempted?'failed':'no_token'});
  return {uid,sent,reason:sent?'sent':attempted?'max-retries-exceeded':'no-token'};
}

/**
 * Sends a push to multiple users in parallel (bounded), returning a
 * summary of results. Use this for SOS alerts / broadcasts.
 */
async function sendPushToUsers(uids, { title, body, data = {} }) {
  if (!Array.isArray(uids) || uids.length === 0) {
    return { total: 0, sent: 0, results: [] };
  }

  // Cap concurrency to avoid hammering FCM / Firestore on large
  // broadcasts (e.g. announcements to thousands of users).
  const BATCH_SIZE = 50;
  const results = [];

  for (let i = 0; i < uids.length; i += BATCH_SIZE) {
    const batch = uids.slice(i, i + BATCH_SIZE);
    const batchResults = await Promise.all(
      batch.map((uid) => sendPushToUser(uid, { title, body, data }))
    );
    results.push(...batchResults);
  }

  const sentCount = results.filter((r) => r.sent).length;
  return { total: uids.length, sent: sentCount, results };
}

module.exports = { sendPushToUser, sendPushToUsers, isNotificationAllowed };
