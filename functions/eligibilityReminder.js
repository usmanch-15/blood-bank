/**
 * ✅ PHASE 3 — Automated Eligibility Reminders
 * Runs once a day. Finds donors whose 90-day eligibility window just
 * opened (i.e. lastDonationDate was exactly ~90 days ago) and sends them
 * a "You're eligible to donate again!" push notification.
 *
 * Add to functions/index.js:
 *
 *   const { checkEligibilityReminders } = require('./eligibilityReminder');
 *   exports.dailyEligibilityCheck = functions.pubsub
 *     .schedule('every day 09:00')
 *     .timeZone('Asia/Karachi')
 *     .onRun(checkEligibilityReminders);
 */

const admin = require('firebase-admin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const { sendPushToUsers } = require('./notificationService');

const MIN_DAYS_BETWEEN_DONATIONS = 90;

async function checkEligibilityReminders() {
  const now = Date.now();
  // Donors become eligible 90 days after lastDonationDate. We check for
  // donors whose eligibility window opened in the last 24 hours (i.e.
  // ran this job daily), so each donor gets exactly one reminder.
  const windowStart = now - MIN_DAYS_BETWEEN_DONATIONS * 24 * 60 * 60 * 1000;
  const windowEnd = windowStart + 24 * 60 * 60 * 1000;

  const donorsSnap = await db
      .collection('users')
      .where('role', '==', 'donor')
      .where('lastDonationDate', '>=', admin.firestore.Timestamp.fromMillis(windowStart))
      .where('lastDonationDate', '<', admin.firestore.Timestamp.fromMillis(windowEnd))
      .get();

  if (donorsSnap.empty) {
    console.log('No donors became eligible today.');
    return null;
  }

  const uids = donorsSnap.docs.map((d) => d.id);
  console.log(`Sending eligibility reminders to ${uids.length} donors`);

  await sendPushToUsers(uids, {
    title: "You're eligible to donate again! 🩸",
    body: 'It has been 90 days since your last donation. Someone nearby might need your help.',
    data: { type: 'rewardUpdates' }, // reuses existing category, or add a new 'eligibilityReminders' pref
  });

  return null;
}

module.exports = { checkEligibilityReminders };