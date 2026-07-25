/**
 * ✅ PHASE 3 — Rate Limiting for SOS Requests
 * Prevents one user from spamming SOS alerts (donor fatigue + abuse).
 * Default: max 3 SOS requests per user per 60 minutes.
 *
 * Usage in your sosRequests onCreate trigger (functions/index.js):
 *
 *   const { checkSosRateLimit } = require('./rateLimiter');
 *
 *   exports.notifyNearbyDonorsOnSOS = functions.firestore
 *     .document('sosRequests/{sosId}')
 *     .onCreate(async (snap, context) => {
 *       const data = snap.data();
 *       const allowed = await checkSosRateLimit(data.receiverId);
 *       if (!allowed) {
 *         await snap.ref.update({
 *           status: 'rate_limited',
 *           rateLimitedAt: admin.firestore.FieldValue.serverTimestamp(),
 *         });
 *         return; // Don't notify donors for this spam request
 *       }
 *       // ... proceed with normal donor search + notify logic
 *     });
 */

const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const MAX_SOS_PER_WINDOW = 3;
const WINDOW_MINUTES = 60;

/**
 * Returns true if the user is still within their allowed SOS quota,
 * false if they've hit the rate limit and this request should be
 * suppressed (not notify donors).
 *
 * Tracks usage in a rate_limits/{uid} document with a rolling list of
 * recent SOS timestamps.
 */
async function checkSosRateLimit(uid) {
  if (!uid) return false;

  const rateLimitRef = db.collection('rate_limits').doc(uid);
  const windowStart = Date.now() - WINDOW_MINUTES * 60 * 1000;

  return db.runTransaction(async (transaction) => {
    const doc = await transaction.get(rateLimitRef);
    const data = doc.exists ? doc.data() : { sosTimestamps: [] };

    // Keep only timestamps within the current rolling window.
    const recentTimestamps = (data.sosTimestamps || []).filter(
      (ts) => ts > windowStart
    );

    if (recentTimestamps.length >= MAX_SOS_PER_WINDOW) {
      console.warn(
        `Rate limit hit for user ${uid}: ${recentTimestamps.length} ` +
          `SOS requests in the last ${WINDOW_MINUTES} minutes`
      );
      return false;
    }

    recentTimestamps.push(Date.now());
    transaction.set(
      rateLimitRef,
      { sosTimestamps: recentTimestamps, lastSosAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    return true;
  });
}

module.exports = { checkSosRateLimit, MAX_SOS_PER_WINDOW, WINDOW_MINUTES };