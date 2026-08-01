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
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

const { sendPushToUsers } = require("./notificationService");
const { checkSosRateLimit } = require("./rateLimiter");
const { sendSmsFallback, twilioAuthToken } = require("./smsFallback");
const { checkEligibilityReminders } = require("./eligibilityReminder");

const MIN_DAYS_BETWEEN_DONATIONS = 90;

/**
 * ✅ confirmDonation (callable) — UNCHANGED
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
 * ✅ sendPushNotification (Firestore trigger) — UPDATED
 * ----------------------------------------------------------------------
 * Ye trigger kisi bhi `notifications/{id}` doc create par FCM push bhejta
 * hai. Ab jo naya code sendPushToUser()/sendPushToUsers() (notificationService.js)
 * use karta hai, wo khud apna push bhej chuka hota hai AUR notification doc
 * bhi banata hai — is liye us doc par `pushSentDirectly: true` flag lagaya
 * jata hai. Ye trigger us flag ko check karke aisi docs ko skip karta hai,
 * warna device par HAR push 2 dafa jaata (duplicate).
 *
 * Jo purana code seedha `notifications` collection mein `.add()` karta hai
 * (jaise confirmDonation upar), us par ye flag nahi hoga, so ye trigger
 * unke liye pehle jaisa hi normal kaam karega.
 */
exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.userId) return;
    if (data.pushSentDirectly) return; // already sent by notificationService — avoid duplicate push

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
 * ✅ notifyNearbyDonorsOnSOS (Firestore trigger) — REWRITTEN (Phase 3)
 * ----------------------------------------------------------------------
 * Naya flow:
 *   1. checkSosRateLimit() — agar receiver ne last 60 min mein 3+ SOS
 *      bheji hain, request ko 'rate_limited' mark karke donors ko notify
 *      hi nahi karta (spam prevention).
 *   2. Matching blood-group ke eligible+available donors dhoondta hai
 *      (query same as before).
 *   3. sendPushToUsers() call karta hai — reliable push (retry + dead
 *      token cleanup + notification-preference check), notificationService.js se.
 *   4. Jin donors tak push nahi pahunch payi (no-token ya sab retries fail),
 *      unhe SMS fallback try karta hai (agar Twilio configured hai aur
 *      unka phone number hai).
 */
exports.notifyNearbyDonorsOnSOS = onDocumentCreated(
  { document: "sosRequests/{sosId}", secrets: [twilioAuthToken] },
  async (event) => {
    const sosRef = event.data?.ref;
    const sos = event.data?.data();
    if (!sos || !sos.bloodGroup || !sos.receiverId || !sosRef) return;

    const allowed = await checkSosRateLimit(sos.receiverId);
    if (!allowed) {
      await sosRef.update({
        status: "rate_limited",
        rateLimitedAt: admin.firestore.Timestamp.now(),
      });
      return; // spam request — donors ko notify nahi karna
    }

    const donorsSnap = await db
      .collection("users")
      .where("isDonor", "==", true)
      .where("bloodGroup", "==", sos.bloodGroup)
      .where("isAvailable", "==", true)
      .where("status", "==", "approved")
      .get();

    if (donorsSnap.empty) return;

    const donorIds = donorsSnap.docs.map((d) => d.id);

    const result = await sendPushToUsers(donorIds, {
      title: "🚨 SOS Blood Request",
      body: `Urgent: ${sos.bloodGroup} blood needed nearby. Tap to view.`,
      data: { type: "sosAlerts", relatedId: event.params.sosId },
    });

    // Push fail hui un donors ke liye SMS fallback try karo
    const smsCandidates = result.results.filter(
      (r) => !r.sent && (r.reason === "no-token" || r.reason === "max-retries-exceeded")
    );
    if (smsCandidates.length > 0) {
      await Promise.all(
        smsCandidates.map((r) =>
          sendSmsFallback(
            r.uid,
            `Urgent: ${sos.bloodGroup} blood needed nearby. Open the Smart Blood Bank app to respond.`
          )
        )
      );
    }
  }
);

/**
 * ✅ onBroadcastCreated (Firestore trigger) — NEW (Phase 3)
 * ----------------------------------------------------------------------
 * AdminBroadcastScreen ek `broadcasts/{id}` doc banati hai (status: 'pending')
 * — pehle ise koi function pick hi nahi karta tha. Ab ye trigger:
 *   1. `audience` field ke hisaab se target users dhoondta hai
 *      (all / donors / receivers / specific bloodGroup)
 *   2. sendPushToUsers() se sabko push bhejta hai
 *   3. broadcast doc ko status: 'sent' + sentCount/totalRecipients ke
 *      saath update karta hai (AdminBroadcastScreen isi ka wada karta hai)
 */
exports.onBroadcastCreated = onDocumentCreated(
  "broadcasts/{broadcastId}",
  async (event) => {
    const broadcastRef = event.data?.ref;
    const broadcast = event.data?.data();
    if (!broadcast || !broadcastRef) return;

    let query = db.collection("users").where("status", "==", "approved");

    if (broadcast.audience === "donors") {
      query = query.where("isDonor", "==", true);
    } else if (broadcast.audience === "receivers") {
      query = query.where("isReceiver", "==", true);
    } else if (broadcast.audience === "bloodGroup" && broadcast.bloodGroup) {
      query = query.where("bloodGroup", "==", broadcast.bloodGroup);
    }
    // audience === "all" → no extra filter, sirf approved users

    const usersSnap = await query.get();
    const uids = usersSnap.docs.map((d) => d.id);

    const result = await sendPushToUsers(uids, {
      title: broadcast.title || "Smart Blood Bank",
      body: broadcast.body || "",
      data: { type: "adminAnnouncements", relatedId: event.params.broadcastId },
    });

    await broadcastRef.update({
      status: "sent",
      sentAt: admin.firestore.Timestamp.now(),
      totalRecipients: result.total,
      sentCount: result.sent,
    });
  }
);

/**
 * ✅ getDonorContact (callable) — NEW
 * ----------------------------------------------------------------------
 * phoneNumber ab users/{uid} (top-level) par nahi likha jata — us doc ko
 * koi bhi signed-in user parh sakta tha, is liye phone number sab ko
 * dikh raha tha (security issue). Phone number ab sirf
 * users/{uid}/private/contact mein hai, jise sirf owner ya admin client-side
 * Firestore rules se parh sakte hain.
 *
 * Lekin receiver ko donor ko CALL karna hota hai — receiver na owner hai
 * na admin, is liye use number chahiye. Ye function wahi rasta hai:
 * receiver donorId ke saath is function ko call karta hai, Admin SDK
 * (jo rules bypass karta hai) private/contact se number nikaal ke deta
 * hai. Har call audit_logs mein likha jata hai — taake pata rahe kisne
 * kis donor ka number kab dekha (misuse detect karne ke liye).
 *
 * ⚠️ Abhi koi rate-limit nahi hai is function par — agar aage koi user
 * isko loop mein call karke sab donors ke number scrape kare, to koi
 * rok nahi. Agar production mein jaana hai to checkSosRateLimit() jaisa
 * hi ek per-user rate limit yahan bhi lagana chahiye.
 */
exports.getDonorContact = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const { donorId } = request.data;
  if (!donorId) {
    throw new HttpsError("invalid-argument", "donorId zaroori hai.");
  }

  const donorSnap = await db.collection("users").doc(donorId).get();
  if (!donorSnap.exists) {
    throw new HttpsError("not-found", "Donor account nahi mila.");
  }
  const donorData = donorSnap.data();
  if (donorData.isDonor !== true || donorData.status !== "approved") {
    // Sirf approved donors ka number diya jaye — random pending/rejected
    // accounts ya receivers ka number is function se kabhi na mile.
    throw new HttpsError(
      "permission-denied",
      "Ye user donor nahi hai ya approved nahi hai."
    );
  }

  const contactSnap = await db
      .collection("users")
      .doc(donorId)
      .collection("private")
      .doc("contact")
      .get();

  const phoneNumber = contactSnap.exists ? contactSnap.data().phoneNumber : null;

  // Audit trail — kisne kis donor ka number kab dekha.
  await db.collection("audit_logs").add({
    action: "donor_contact_viewed",
    viewedBy: auth.uid,
    donorId,
    createdAt: admin.firestore.Timestamp.now(),
  });

  if (!phoneNumber) {
    return { phoneNumber: null };
  }
  return { phoneNumber };
});

/**
 * ✅ dailyEligibilityCheck (Scheduled function) — NEW (Phase 3)
 * ----------------------------------------------------------------------
 * Har roz 09:00 Asia/Karachi par chalta hai. Jin donors ka 90-din
 * eligibility window aaj khula hai, unhe "You're eligible to donate
 * again!" push bhejta hai (logic eligibilityReminder.js mein hai).
 */
exports.dailyEligibilityCheck = onSchedule(
  { schedule: "every day 09:00", timeZone: "Asia/Karachi" },
  async () => {
    await checkEligibilityReminders();
  }
);