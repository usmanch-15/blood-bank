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

const admin = require('firebase-admin');
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
  if (!userData) return false;
  if (userData.notificationsEnabled === false) return false;
  if (!category) return true;

  const prefs = userData.notificationPrefs || {};
  // Default to true if the specific preference field doesn't exist yet
  // (so users who haven't touched Settings still get notified).
  return prefs[category] !== false;
}

/**
 * Sends a single push notification to one user, with retry + dead-token
 * cleanup. Always writes a notification doc regardless of push success,
 * so the user can see it in-app even if the push itself failed.
 */
async function sendPushToUser(uid, { title, body, data = {} }) {
  const userRef = db.collection('users').doc(uid);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    console.warn(`sendPushToUser: user ${uid} not found`);
    return { uid, sent: false, reason: 'user-not-found' };
  }

  const userData = userSnap.data();
  const category = data.type;

  // Always record the notification in-app, even if push is disabled —
  // the in-app notification history should still show it.
  // pushSentDirectly=true tells the legacy sendPushNotification trigger
  // (in index.js) to NOT send a second push for this same doc.
  await db.collection('notifications').add({
    userId: uid,
    title,
    body,
    type: category || 'general',
    relatedId: data.requestId || data.relatedId || null,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    pushSentDirectly: true,
  });

  if (!isNotificationAllowed(userData, category)) {
    return { uid, sent: false, reason: 'user-opted-out' };
  }

  const token = userData.fcmToken;
  if (!token) {
    return { uid, sent: false, reason: 'no-token' };
  }

  const message = {
    token,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: { priority: 'high' },
    apns: { headers: { 'apns-priority': '10' } },
  };

  let lastError;
  for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
    try {
      await messaging.send(message);
      return { uid, sent: true };
    } catch (err) {
      lastError = err;

      // Dead token — clean it up immediately, no point retrying.
      if (
        err.code === 'messaging/registration-token-not-registered' ||
        err.code === 'messaging/invalid-registration-token'
      ) {
        await userRef.update({
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.warn(`Removed dead FCM token for user ${uid}`);
        return { uid, sent: false, reason: 'dead-token-cleaned' };
      }

      // Transient error — retry with exponential backoff.
      const delay = RETRY_BASE_DELAY_MS * Math.pow(2, attempt);
      console.warn(
        `sendPushToUser: attempt ${attempt + 1} failed for ${uid}: ` +
          `${err.code || err.message}. Retrying in ${delay}ms.`
      );
      await sleep(delay);
    }
  }

  console.error(
    `sendPushToUser: all ${MAX_RETRIES} attempts failed for ${uid}`,
    lastError
  );
  return { uid, sent: false, reason: 'max-retries-exceeded', error: String(lastError) };
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