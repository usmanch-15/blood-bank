
const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("./firebaseAdmin");

admin.initializeApp();
const db = admin.firestore();

const { sendPushToUsers, sendPushToUser } = require("./notificationService");
const { sendSmsFallback, twilioAuthToken } = require("./smsFallback");
const { checkEligibilityReminders } = require("./eligibilityReminder");
const donationHistory = require('./donationHistoryWorkflows');
const verification = require('./verificationWorkflows');
const emergencyReview = require('./emergencyReviewWorkflows');
const {notifyPendingEmergency} = require('./emergencyAlerts');
const {escalatePendingEmergencyReviews} = require('./emergencyEscalation');
exports.notifyPendingEmergency = onDocumentCreated('blood_requests/{requestId}', notifyPendingEmergency);

const workflows = require('./secureWorkflows');
const awareness = require('./awarenessWorkflows');
for (const name of ['manageAwarenessBanner', 'donorAwarenessBanners', 'recordBannerEvent']) exports[name] = onCall(awareness[name]);
exports.donorInvitations = onCall(require('./donorInvitations').donorInvitations);
const voice = require('./voiceWorkflows');
const {nearbyDonors} = require('./nearbyDonors');
const {notifyRequest} = require('./requestNotifications');
const {notifyChatMessage} = require('./chatNotifications');
const chatWorkflows = require('./chatWorkflows');
exports.onChatMessageCreated = onDocumentCreated('conversations/{conversationId}/messages/{messageId}', notifyChatMessage);
for (const name of ['createBloodRequest','acceptDonation','declineRequest','updateAssignment','closeRequest','getRequest','discoverRequests','findDonors','getSos','resolveSos']) exports[name] = onCall(workflows[name]);
const administration = require('./adminWorkflows');
for (const name of ['adminAction','submitReport','exportPage','adminRequestAction']) exports[name] = onCall(administration[name]);
exports.adminAnalytics = onCall(administration.adminAnalytics);
exports.donationHistory = onCall(donationHistory.donationHistory);
exports.submitDonationDispute = onCall(donationHistory.submitDonationDispute);
exports.acknowledgeDonation = onCall(donationHistory.acknowledgeDonation);
exports.disputeDonation = onCall(donationHistory.disputeDonation);
exports.submitVerification = onCall(verification.submitVerification);
exports.reviewVerification = onCall(verification.reviewVerification);
exports.revokeVerification = onCall(verification.revokeVerification);
exports.reviewEmergencyRequest = onCall(emergencyReview.reviewEmergencyRequest);
exports.replyEmergencyClarification = onCall(emergencyReview.replyEmergencyClarification);
for (const name of ['blockUser','unblockUser','markConversationRead','reportConversation','sharePhoneNumber']) exports[name] = onCall(chatWorkflows[name]);
exports.confirmDonation = onCall(workflows.confirmDonation);
exports.deleteAccount = onCall(request => workflows.deleteAccount(request));
exports.createSosAlert = onCall(workflows.createSosAlert);
exports.createVoiceCallSession = onCall({secrets: [voice.agoraCertificate]}, voice.createVoiceCallSession);
exports.getVoiceCallToken = onCall({secrets: [voice.agoraCertificate]}, voice.getVoiceCallToken);
exports.updateVoiceCallSession = onCall({secrets: [voice.agoraCertificate]}, voice.updateVoiceCallSession);
exports.inviteDonor = onCall(voice.inviteDonor);
exports.markDonorNotReady = onCall(voice.markDonorNotReady);

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
    let donorIds = [];
    let radiusKm = 50;
    for (const radius of [5, 10, 25, 50]) {
      donorIds = await nearbyDonors(
        sos.latitude,
        sos.longitude,
        sos.bloodGroup,
        radius,
      );
      if (donorIds.length) {
        radiusKm = radius;
        break;
      }
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
exports.notifyRequest = onCall(notifyRequest);

// Matching runs on the server even if the client closes after saving.
exports.onBloodRequestCreated = onDocumentCreated('blood_requests/{requestId}', async event => {
  const data = event.data?.data();
  if (!data || data.sosId || data.status !== 'pending' || !Number.isFinite(data.latitude) || !Number.isFinite(data.longitude)) return;
  let recipients = [];
  let selectedRadius = 5;
  // Keep automatic matching aligned with the client-supported radius choices.
  // The first radius with eligible recipients wins, limiting notification fan-out.
  for (const radius of [5, 10, 25, 50]) {
    selectedRadius = radius;
    recipients = (await nearbyDonors(data.latitude, data.longitude, data.bloodGroup, radius))
      .filter(uid => uid !== data.requesterId);
    if (recipients.length) break;
  }
  await notifyRequest({auth: {uid: data.requesterId}, data: {
    requestId: event.params.requestId, userIds: recipients, radiusKm: selectedRadius,
  }});
});

exports.expireOpenRequests = onSchedule('every 15 minutes', workflows.expireRequests);
exports.escalateEmergencyReviews = onSchedule('every 15 minutes', escalatePendingEmergencyReviews);
