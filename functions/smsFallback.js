/**
 * ✅ PHASE 3 — SMS Fallback for SOS
 * If a donor's push notification can't be delivered (no token, or push
 * failed), send them an SMS instead so they don't miss an emergency.
 *
 * SETUP REQUIRED:
 *   1. Create a free/paid Twilio account: https://www.twilio.com
 *   2. Get your Account SID, Auth Token, and a Twilio phone number
 *   3. Set them as Cloud Function config (from your terminal):
 *        firebase functions:config:set twilio.sid="ACxxxx" twilio.token="xxxx" twilio.phone="+1xxxxxxxxxx"
 *   4. npm install twilio --save   (inside your functions/ folder)
 *
 * Usage — call this AFTER sendPushToUser() fails or returns no-token:
 *
 *   const { sendSmsFallback } = require('./smsFallback');
 *   const pushResult = await sendPushToUser(uid, {...});
 *   if (!pushResult.sent && (pushResult.reason === 'no-token' || pushResult.reason === 'max-retries-exceeded')) {
 *     await sendSmsFallback(uid, 'Blood needed urgently nearby! Open the app to respond.');
 *   }
 */

const admin = require('firebase-admin');
const functions = require('firebase-functions');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

let twilioClient = null;
function getTwilioClient() {
  if (twilioClient) return twilioClient;
  const twilio = require('twilio');
  const config = functions.config().twilio || {};
  if (!config.sid || !config.token) {
    console.error('Twilio config missing — run firebase functions:config:set twilio.sid=... twilio.token=... twilio.phone=...');
    return null;
  }
  twilioClient = twilio(config.sid, config.token);
  return twilioClient;
}

/**
 * Sends a short SMS to the given user's registered phone number.
 * Silently no-ops (with a log) if Twilio isn't configured or the user
 * has no phone number on file.
 */
async function sendSmsFallback(uid, message) {
  const client = getTwilioClient();
  if (!client) return { sent: false, reason: 'twilio-not-configured' };

  const userSnap = await db.collection('users').doc(uid).get();
  if (!userSnap.exists) return { sent: false, reason: 'user-not-found' };

  const phoneNumber = userSnap.data().phoneNumber;
  if (!phoneNumber) return { sent: false, reason: 'no-phone-number' };

  const config = functions.config().twilio;

  try {
    await client.messages.create({
      body: message,
      from: config.phone,
      to: phoneNumber, // must be in E.164 format e.g. +923001234567
    });
    console.log(`SMS fallback sent to ${uid}`);
    return { sent: true };
  } catch (err) {
    console.error(`SMS fallback failed for ${uid}:`, err.message);
    return { sent: false, reason: 'twilio-error', error: err.message };
  }
}

module.exports = { sendSmsFallback };