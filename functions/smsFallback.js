/**
 * ✅ PHASE 3 — SMS Fallback for SOS
 * If a donor's push notification can't be delivered (no token, or push
 * failed after retries), send them an SMS instead so they don't miss an
 * emergency.
 *
 * ⚠️ UPDATED: `functions.config()` is deprecated/shut down by Google, so
 * this now uses `firebase-functions/params` instead — the modern way to
 * pass config into 2nd-gen (v2) Cloud Functions.
 *   - TWILIO_SID / TWILIO_PHONE  → non-secret, stored in a .env file
 *   - TWILIO_AUTH_TOKEN          → secret, stored in Secret Manager
 *
 * SETUP REQUIRED (run once from inside the functions/ folder):
 *   1. Create a Twilio account: https://www.twilio.com — get your
 *      Account SID, Auth Token, and a Twilio phone number.
 *   2. npm install twilio --save
 *   3. Create functions/.env.<your-project-id> with:
 *        TWILIO_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 *        TWILIO_PHONE=+1xxxxxxxxxx
 *      (find your project id: firebase use  → shows current project)
 *   4. Store the secret (this prompts you to paste the token — it is
 *      never written to disk or committed to git):
 *        firebase functions:secrets:set TWILIO_AUTH_TOKEN
 *
 * Usage — call this AFTER sendPushToUser()/sendPushToUsers() fails or
 * returns no-token / max-retries-exceeded for a given uid:
 *
 *   const { sendSmsFallback } = require('./smsFallback');
 *   await sendSmsFallback(uid, 'Blood needed urgently nearby! Open the app to respond.');
 *
 * Any exported Cloud Function that (directly or indirectly, via another
 * required module) calls sendSmsFallback() MUST declare the secret in its
 * options, e.g.:
 *   const { twilioAuthToken } = require('./smsFallback');
 *   exports.myTrigger = onDocumentCreated(
 *     { document: '...', secrets: [twilioAuthToken] },
 *     handler
 *   );
 * Without this, twilioAuthToken.value() will be empty at runtime even if
 * the secret was set, because gen2 functions only get access to secrets
 * they explicitly list.
 */

const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const { defineString, defineSecret } = require('firebase-functions/params');

const twilioSid = defineString('TWILIO_SID');
const twilioPhone = defineString('TWILIO_PHONE');
const twilioAuthToken = defineSecret('TWILIO_AUTH_TOKEN');

let twilioClient = null;
function getTwilioClient() {
  const sid = twilioSid.value();
  const token = twilioAuthToken.value();

  if (!sid || !token) {
    console.error(
      'Twilio not configured — set TWILIO_SID in functions/.env.<project-id> ' +
        'and run: firebase functions:secrets:set TWILIO_AUTH_TOKEN'
    );
    return null;
  }

  if (twilioClient) return twilioClient;
  const twilio = require('twilio');
  twilioClient = twilio(sid, token);
  return twilioClient;
}

/**
 * Sends a short SMS to the given user's registered phone number.
 * Silently no-ops (with a log) if Twilio isn't configured or the user
 * has no phone number on file.
 *
 * NOTE: phoneNumber currently lives on the TOP-LEVEL users/{uid} doc
 * (written by auth_service.dart / donor_profile_screen.dart), not in the
 * users/{uid}/private subcollection the firestore.rules comments describe
 * as the intended long-term home for it. Reading it from here matches
 * how the app actually writes it today — see the note I've flagged
 * separately about migrating phoneNumber into the private subcollection.
 */
async function sendSmsFallback(uid, message) {
  const client = getTwilioClient();
  if (!client) return { sent: false, reason: 'twilio-not-configured' };

  const userSnap = await db.collection('users').doc(uid).get();
  if (!userSnap.exists) return { sent: false, reason: 'user-not-found' };

  const phoneNumber = userSnap.data().phoneNumber;
  if (!phoneNumber) return { sent: false, reason: 'no-phone-number' };

  try {
    await client.messages.create({
      body: message,
      from: twilioPhone.value(),
      to: phoneNumber, // must be in E.164 format e.g. +923001234567
    });
    console.log(`SMS fallback sent to ${uid}`);
    return { sent: true };
  } catch (err) {
    console.error(`SMS fallback failed for ${uid}:`, err.message);
    return { sent: false, reason: 'twilio-error', error: err.message };
  }
}

module.exports = { sendSmsFallback, twilioAuthToken };