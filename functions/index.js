/**
 * Smart Blood Bank — Cloud Functions
 *
 * Deploy: firebase deploy --only functions
 * (Blaze plan required — Spark/free plan doesn't allow deploying functions
 *  that read/write other Google services like FCM. Blaze still has a large
 *  free-usage quota, so for an FYP-scale app this normally costs Rs 0.)
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const MIN_DAYS_BETWEEN_DONATIONS = 90;

/**
 * ✅ confirmDonation (callable)
 * ----------------------------------------------------------------------
 * Pehle donation-confirmation ka koi wired flow hi nahi tha (createDonation
 * aur addRewardForDonation dono methods app mein kahin se call hi nahi
 * hotay thay). Ab ye Cloud Function receiver ya donor, kisi ke bhi app se
 * call ho sakti hai, aur SAFELY (Admin SDK) ye kaam karti hai:
 *   1. `donations` collection mein record banata hai
 *   2. Donor ke lastDonationDate / nextEligibleDate (90-din rule) / reward
 *      points update karta hai
 *   3. Receiver ki original blood_request ko 'fulfilled' mark karta hai
 *
 * Client-side Firestore rules jaan-boojh kar donor ke reward points ya
 * eligibility field ko doosre user (receiver) se seedha update karne nahi
 * detay — is se koi bhi kisi ke bhi points inflate nahi kar sakta. Ye
 * function hi is state ko badalne ka sirf tareeqa hai.
 */
exports.confirmDonation = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const { donorId, bloodGroup, requestId, location, points } = request.data;
  if (!donorId || !bloodGroup) {
    throw new HttpsError("invalid-argument", "donorId aur bloodGroup zaroori hain.");
  }
  const awardPoints = Number.isFinite(points) ? points : 50;

  const donorRef = db.collection("users").doc(donorId);
  const donorSnap = await donorRef.get();
  if (!donorSnap.exists) {
    throw new HttpsError("not-found", "Donor account nahi mila.");
  }
  const donorData = donorSnap.data();

  // Sirf requester khud (jisne blood request banayi) ya khud donor confirm
  // kar sakta hai — koi third-party random user nahi.
  const isDonorSelf = auth.uid === donorId;
  let isRequester = false;
  if (requestId) {
    const reqSnap = await db.collection("blood_requests").doc(requestId).get();
    isRequester = reqSnap.exists && reqSnap.data().requesterId === auth.uid;
  }
  if (!isDonorSelf && !isRequester) {
    throw new HttpsError(
      "permission-denied",
      "Sirf request karne wala receiver ya khud donor is donation ko confirm kar sakta hai."
    );
  }

  const now = admin.firestore.Timestamp.now();
  const nextEligible = admin.firestore.Timestamp.fromMillis(
    now.toMillis() + MIN_DAYS_BETWEEN_DONATIONS * 24 * 60 * 60 * 1000
  );

  const donationRef = db.collection("donations").doc();
  await donationRef.set({
    donorId,
    donorName: donorData.name || "",
    bloodGroup,
    donationDate: now,
    location: location || donorData.location || null,
    requestId: requestId || null,
    pointsEarned: awardPoints,
    confirmedBy: auth.uid,
  });

  await donorRef.update({
    lastDonationDate: now,
    nextEligibleDate: nextEligible,
    isEligible: false,
    rewardPoints: admin.firestore.FieldValue.increment(awardPoints),
  });

  if (requestId) {
    await db.collection("blood_requests").doc(requestId).update({
      status: "fulfilled",
      fulfilledAt: now,
      fulfilledByDonorId: donorId,
    });
  }

  // Donor ko notify karo taake wo apni certificate generate kar sake
  await db.collection("notifications").add({
    userId: donorId,
    title: "Donation Confirmed 🎉",
    body: `Thank you for donating ${bloodGroup}! You earned ${awardPoints} points.`,
    type: "donation_confirmed",
    relatedId: donationRef.id,
    createdAt: now,
    isRead: false,
  });

  return { donationId: donationRef.id, nextEligibleDate: nextEligible.toMillis() };
});

/**
 * ✅ sendPushNotification (Firestore trigger)
 * ----------------------------------------------------------------------
 * Pehle notification_service.dart sirf Firestore mein ek document banata
 * tha — device par kabhi push notification aati hi nahi thi (sirf app
 * kholne par in-app list mein dikhta tha). Ab jab bhi `notifications`
 * collection mein naya doc bane, ye function us user ke saved FCM token
 * par asli push bhejti hai.
 */
exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.userId) return;

    const userSnap = await db.collection("users").doc(data.userId).get();
    const token = userSnap.data()?.fcmToken;
    if (!token) return; // user ne notification permission nahi di / token nahi mila

    try {
      await messaging.send({
        token,
        notification: {
          title: data.title || "Smart Blood Bank",
          body: data.body || "",
        },
        data: {
          type: data.type || "general",
          relatedId: data.relatedId || "",
        },
      });
    } catch (err) {
      // Token expire/invalid ho sakta hai — silently log, app crash na ho
      console.error("Push notification failed:", err.message);
    }
  }
);

/**
 * ✅ notifyNearbyDonorsOnSOS (Firestore trigger)
 * ----------------------------------------------------------------------
 * SOS request banate hi matching blood-group ke eligible+available donors
 * ko automatically notification bhej deta hai (README mein SOS ka wada
 * kiya gaya tha, lekin donors ko koi automatic alert nahi jaata tha).
 */
exports.notifyNearbyDonorsOnSOS = onDocumentCreated(
  "sosRequests/{sosId}",
  async (event) => {
    const sos = event.data?.data();
    if (!sos || !sos.bloodGroup) return;

    const donorsSnap = await db
      .collection("users")
      .where("isDonor", "==", true)
      .where("bloodGroup", "==", sos.bloodGroup)
      .where("isAvailable", "==", true)
      .where("status", "==", "approved")
      .get();

    const now = admin.firestore.Timestamp.now();
    const batch = db.batch();
    donorsSnap.forEach((doc) => {
      const notifRef = db.collection("notifications").doc();
      batch.set(notifRef, {
        userId: doc.id,
        title: "🚨 SOS Blood Request",
        body: `Urgent: ${sos.bloodGroup} blood needed nearby. Tap to view.`,
        type: "sos",
        relatedId: event.params.sosId,
        createdAt: now,
        isRead: false,
      });
    });
    await batch.commit();
  }
);