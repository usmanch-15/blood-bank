
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("./firebaseAdmin");

admin.initializeApp();
const db = admin.firestore();

const { sendPushToUsers, sendPushToUser } = require("./notificationService");
const { sendSmsFallback, twilioAuthToken } = require("./smsFallback");
const { checkEligibilityReminders } = require("./eligibilityReminder");

const workflows = require('./secureWorkflows');
const {nearbyDonors} = require('./nearbyDonors');
for (const name of ['createBloodRequest','acceptDonation','updateAssignment','closeRequest','getRequest','discoverRequests','findDonors','getSos','resolveSos']) exports[name] = onCall(workflows[name]);
const administration = require('./adminWorkflows');
for (const name of ['adminAction','submitReport','exportPage','adminRequestAction']) exports[name] = onCall(administration[name]);
exports.confirmDonation = onCall(workflows.confirmDonation);
exports.deleteAccount = onCall(request => workflows.deleteAccount(request));
exports.createSosAlert = onCall(workflows.createSosAlert);

exports.sendPushNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || !data.userId) return;
    if (data.pushSentDirectly) return; // already sent by notificationService — avoid duplicate push

    const delivery = await sendPushToUser(data.userId, {
      title: data.title || 'Smart Blood Bank', body: data.body || '',
      data: {type: data.type || 'general', relatedId: data.relatedId || ''},
      record: false,
    });
    await event.data.ref.update({pushStatus:delivery.sent?'sent':delivery.reason});
  }
);

exports.notifyNearbyDonorsOnSOS = onDocumentCreated(
  { document: "sosRequests/{sosId}", secrets: process.env.FUNCTIONS_EMULATOR === 'true' ? [] : [twilioAuthToken] },
  async (event) => {
    const sosRef = event.data?.ref;
    const sos = event.data?.data();
    if (!sos || !sos.bloodGroup || !sos.receiverId || !sosRef || sos.isResolved) return;

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

exports.getDonorContact = onCall(workflows.getDonorContact);

exports.adminDeleteUser = onCall(request => workflows.deleteAccount(request, true));

exports.dailyEligibilityCheck = onSchedule(
  { schedule: "every day 09:00", timeZone: "Asia/Karachi" },
  async () => {
    await checkEligibilityReminders();
  }
);
async function notifyRequest(request) {
  if (!request.auth) throw new HttpsError('unauthenticated','Sign in first.');
  const requestId = request.data?.requestId;
  if (typeof requestId !== 'string' || requestId.includes('/')) throw new HttpsError('invalid-argument','Request required.');
  const ref = db.doc(`blood_requests/${requestId}`);
  const [req, user] = await Promise.all([ref.get(), db.doc(`users/${request.auth.uid}`).get()]);
  const r=req.data();
  if (!r || r.requesterId !== request.auth.uid || user.data()?.status !== 'approved' || !workflows.openStatuses.includes(r.status) || workflows.expired(r)) {
    throw new HttpsError('permission-denied','An active request belonging to you is required.');
  }
  const ids = await nearbyDonors(r.latitude,r.longitude,r.bloodGroup,50);
  const requested = request.data.userIds;
  const recipients = ids.filter(uid => uid !== request.auth.uid &&
    (!Array.isArray(requested) || requested.includes(uid)));
  for (const uid of recipients) {
    try {
      await db.doc(`notifications/request_${requestId}_${uid}`).create({
        userId:uid, title:'Blood donation request', body:`${r.bloodGroup} blood needed at ${r.hospitalName || 'a nearby hospital'}. Open the app for details.`,
        type:'blood_request',relatedId:requestId,isRead:false,createdAt:admin.firestore.Timestamp.now(),
      });
    } catch(e) { if(e.code !== 6) throw e; }
  }
  if (recipients.length) await ref.update({notifiedDonors: admin.firestore.FieldValue.arrayUnion(...recipients)});
  return {count:recipients.length};
}
exports.notifyRequest = onCall(notifyRequest);

// Matching runs on the server even if the client closes after saving.
exports.onBloodRequestCreated = onDocumentCreated('blood_requests/{requestId}', async event => {
  const data = event.data?.data();
  if (!data || data.sosId || data.status !== 'pending' || !Number.isFinite(data.latitude) || !Number.isFinite(data.longitude)) return;
  let recipients = [];
  for (const radius of [10, 30, 50]) {
    recipients = (await nearbyDonors(data.latitude, data.longitude, data.bloodGroup, radius))
      .filter(uid => uid !== data.requesterId);
    if (recipients.length) break;
  }
  await notifyRequest({auth: {uid: data.requesterId}, data: {
    requestId: event.params.requestId, userIds: recipients,
  }});
});

exports.expireOpenRequests = onSchedule('every 15 minutes', workflows.expireRequests);
