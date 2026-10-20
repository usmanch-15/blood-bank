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

const admin = require('./firebaseAdmin');
if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();
const { sendPushToUsers } = require('./notificationService');

// Medical-review setting. Keep the current policy default unless a clinician changes it.
const DONATION_REMINDER_INTERVAL_DAYS = Number(process.env.DONATION_REMINDER_INTERVAL_DAYS || 90);

async function checkEligibilityReminders() {
  const now = Date.now();
  // Donors become eligible 90 days after lastDonationDate. We check for
  // donors whose eligibility window opened in the last 24 hours (i.e.
  // ran this job daily), so each donor gets exactly one reminder.
  const windowEnd = now - DONATION_REMINDER_INTERVAL_DAYS * 24 * 60 * 60 * 1000;
  const windowStart = windowEnd - 24 * 60 * 60 * 1000;

  const donorsSnap = await db
      .collection('users')
      .where('isDonor', '==', true)
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
    body: `You may be able to donate again after ${DONATION_REMINDER_INTERVAL_DAYS} days, subject to medical screening.`,
    data: { type: 'eligibilityReminders' },
  });

  return null;
}

module.exports = { checkEligibilityReminders, DONATION_REMINDER_INTERVAL_DAYS };
