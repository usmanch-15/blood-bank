
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

const workflows = require('./secureWorkflows');
const {nearbyDonors} = require('./nearbyDonors');
exports.acceptDonation = onCall(workflows.acceptDonation);
exports.confirmDonation = onCall(workflows.confirmDonation);
exports.deleteAccount = onCall(request => workflows.deleteAccount(request));

exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.userId) return;
    if (data.pushSentDirectly) return; // already sent by notificationService — avoid duplicate push

    const userSnap = await db.collection("users").doc(data.userId).get();
    const token = (await db.doc(`users/${data.userId}/private/device`).get()).data()?.fcmToken;
    if (userSnap.data()?.status !== 'approved' || userSnap.data()?.notificationsEnabled === false) return;
    if (!token) return; // user ne notification permission nahi di / token nahi mila

    try {
      await messaging.send({
        token,
        android: {notification: {channelId: 'blood_requests'}},
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

    const owner = (await db.doc(`users/${sos.receiverId}`).get()).data();
    if (owner?.status !== 'approved') return;
    let donorIds = await nearbyDonors(sos.latitude, sos.longitude, sos.bloodGroup, 15);
    let radiusKm = 15;
    if (!donorIds.length) {
      radiusKm = 30;
      donorIds = await nearbyDonors(sos.latitude, sos.longitude, sos.bloodGroup, radiusKm);
    }
    await sosRef.update({notifiedDonors: donorIds, radiusKm, status:'processed'});
    if (!donorIds.length) return;

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

exports.getDonorContact = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Login required.");
  }

  const callerData = (await db.doc(`users/${auth.uid}`).get()).data();
  if (callerData?.status !== 'approved') throw new HttpsError('permission-denied','Active account required.');
  if (callerData.isReceiver !== true) throw new HttpsError('permission-denied','Switch to receiver mode before requesting donor contact.');
  const contactLimit = db.doc(`rate_limits/contact_${auth.uid}`);
  await db.runTransaction(async tx => {
    const data = (await tx.get(contactLimit)).data();
    const recent = (data?.timestamps || []).filter(time => time > Date.now() - 3600000);
    if (recent.length >= 20) throw new HttpsError('resource-exhausted','Contact lookup limit reached. Try again later.');
    tx.set(contactLimit, {timestamps: [...recent, Date.now()]});
  });
  const { donorId } = request.data || {};
  if (typeof donorId !== 'string' || donorId.includes('/')) throw new HttpsError('invalid-argument','Invalid donor.');
  if (!donorId) {
    throw new HttpsError("invalid-argument", "donorId zaroori hai.");
  }

  const donorSnap = await db.collection("users").doc(donorId).get();
  if (!donorSnap.exists) {
    throw new HttpsError("not-found", "Donor account nahi mila.");
  }
  const donorData = donorSnap.data();
  if (donorData.isDonor !== true || donorData.status !== "approved" || donorData.isAvailable !== true) {
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

exports.adminDeleteUser = onCall(request => workflows.deleteAccount(request, true));

exports.dailyEligibilityCheck = onSchedule(
  { schedule: "every day 09:00", timeZone: "Asia/Karachi" },
  async () => {
    await checkEligibilityReminders();
  }
);
exports.notifyRequest = onCall(async request => {
  if (!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const requestId = request.data?.requestId;
  if (typeof requestId !== 'string' || requestId.includes('/')) throw new HttpsError('invalid-argument','Request required.');
  const ref = db.doc(`blood_requests/${requestId}`);
  const [req, user] = await Promise.all([ref.get(), db.doc(`users/${request.auth.uid}`).get()]);
  const r=req.data();
  if (!r || r.requesterId !== request.auth.uid || user.data()?.status !== 'approved' || !['pending','accepted'].includes(r.status)) {
    throw new HttpsError('permission-denied','An active request belonging to you is required.');
  }
  const ids = await nearbyDonors(r.latitude,r.longitude,r.bloodGroup,50);
  const requested = request.data.userIds;
  const recipients = Array.isArray(requested) ? ids.filter(uid=>requested.includes(uid)) : ids;
  for (const uid of recipients) {
    try {
      await db.doc(`notifications/request_${requestId}_${uid}`).create({
        userId:uid, title:'Blood donation request', body:`${r.bloodGroup} blood needed at ${r.hospitalName || 'a nearby hospital'}. Open the app for details.`,
        type:'blood_request',relatedId:requestId,isRead:false,createdAt:admin.firestore.Timestamp.now(),
      });
    } catch(e) { if(e.code !== 6) throw e; }
  }
  return {count:recipients.length};
});
