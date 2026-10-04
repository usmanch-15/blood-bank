
const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const { defineString, defineSecret } = require('firebase-functions/params');

const twilioSid = defineString('TWILIO_SID', {default:''});
const twilioPhone = defineString('TWILIO_PHONE', {default:''});
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

async function sendSmsFallback(uid, message) {
  const client = getTwilioClient();
  if (!client) return { sent: false, reason: 'twilio-not-configured' };

  const userSnap = await db.collection('users').doc(uid).get();
  if (!userSnap.exists) return { sent: false, reason: 'user-not-found' };

  const data = userSnap.data();
  if (data.status !== 'approved' || data.notificationsEnabled === false || data.notificationPrefs?.sosAlerts === false) return {sent:false,reason:'disabled'};
  const phoneNumber = (await userSnap.ref.collection('private').doc('contact').get()).data()?.phoneNumber;
  const authUser = await admin.auth().getUser(uid);
  if (!phoneNumber || authUser.phoneNumber !== phoneNumber) return {sent:false,reason:'unverified-phone'};
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