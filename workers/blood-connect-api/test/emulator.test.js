import test, { beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { FirestoreRestClient, FirestoreTimestamp } from '../src/firestore_rest.js';
import { callWorkflow, expireOpenRequestsForWorker } from '../src/workflows.js';

const require = createRequire(import.meta.url);
const projectId = 'demo-bloodbank';
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulatorHost) throw new Error('Run with firebase emulators:exec --only firestore.');
if (!['127.0.0.1:8080', 'localhost:8080'].includes(emulatorHost)) {
  throw new Error('Worker workflow tests are restricted to the local Firestore demo emulator.');
}

const env = { FIREBASE_PROJECT_ID: projectId, FIRESTORE_EMULATOR_HOST: emulatorHost };
const db = new FirestoreRestClient(env);
const functionsAdmin = require('../../../functions/firebaseAdmin.js');
if (!functionsAdmin.apps.length) {
  functionsAdmin.initializeApp({ projectId, storageBucket: `${projectId}.appspot.com` });
}
const { notifyChatMessage: notifyChatMessageFromFunction } =
  require('../../../functions/chatNotifications.js');
const { createNotificationPushHandler } =
  require('../../../functions/notificationTrigger.js');
const identity = (uid) => ({ uid });
const receiver = {
  uid: 'stage2-receiver',
  status: 'approved',
  role: 'receiver',
  isReceiver: true,
  name: 'Receiver',
};
const donor = {
  uid: 'stage2-donor',
  status: 'approved',
  role: 'donor',
  isDonor: true,
  isAvailable: true,
  name: 'Donor',
};
const outsider = { uid: 'stage2-outsider', status: 'approved', role: 'donor', isDonor: true };
const request = {
  requesterId: receiver.uid,
  status: 'accepted',
  acceptedDonorIds: [donor.uid],
  commitments: { [donor.uid]: { status: 'accepted' } },
  participantIds: [receiver.uid, donor.uid],
};
const conversation = {
  requestId: 'stage2-request',
  participantIds: [receiver.uid, donor.uid],
  unread: { [receiver.uid]: 0, [donor.uid]: 0 },
};
const stage1Receiver = {
  uid: 'stage1-receiver',
  status: 'approved',
  role: 'receiver',
  isReceiver: true,
  name: 'Stage One Receiver',
  latitude: 31.01,
  longitude: 74.02,
};
const stage1Donor = {
  uid: 'stage1-donor',
  status: 'approved',
  role: 'donor',
  isDonor: true,
  isAvailable: true,
  bloodGroup: 'O+',
  name: 'Stage One Donor',
  locationSharingEnabled: true,
  isEligible: true,
  latitude: 31.01,
  longitude: 74.02,
};
const stage1Outsider = {
  uid: 'stage1-outsider',
  status: 'approved',
  role: 'receiver',
};
const stage1Hospital = {
  name: 'Stage One Hospital',
  address: 'Hospital Road',
  latitude: 31.0543,
  longitude: 74.0532,
};

async function seed() {
  await Promise.all([
    db.doc(`users/${receiver.uid}`).set(receiver),
    db.doc(`users/${donor.uid}`).set(donor),
    db.doc(`users/${outsider.uid}`).set(outsider),
    db.doc('blood_requests/stage2-request').set(request),
    db.doc('conversations/stage2-conversation').set(conversation),
    db.doc(`users/${receiver.uid}/private/contact`).set({ phoneNumber: '+923001234567' }),
  ]);
  const [messages, chatNotifications] = await Promise.all([
    db.collection('conversations/stage2-conversation/messages').get(),
    db.collection('notifications').where('relatedId', '==', 'stage2-conversation').get(),
  ]);
  await Promise.all([
    ...messages.docs.map((message) => message.ref.delete()),
    ...chatNotifications.docs.map((notification) => notification.ref.delete()),
  ]);
  const oldReport = db.doc(`misuse_reports/chat_report_${receiver.uid}_stage2-conversation_${donor.uid}`);
  await oldReport.delete();
  await db.doc(`rate_limits/chat_reports_${receiver.uid}`).delete();
  for (const messageId of ['valid-message', 'blocked-message', 'phone-message']) {
    await db.doc(`conversations/stage2-conversation/messages/${messageId}`).delete();
    await db.doc(`notifications/chat_stage2-conversation_${messageId}`).delete();
  }
}

async function seedStage1() {
  const previousRequests = await db.collection('blood_requests')
    .where('requesterId', '==', stage1Receiver.uid).get();
  await Promise.all(previousRequests.docs.map(async (requestDoc) => {
    const events = await db.collection(`${requestDoc.ref.path}/events`).get();
    await Promise.all([
      ...events.docs.map((event) => event.ref.delete()),
      requestDoc.ref.delete(),
    ]);
  }));
  await Promise.all([
    db.doc(`users/${stage1Receiver.uid}`).set(stage1Receiver),
    db.doc(`users/${stage1Donor.uid}`).set(stage1Donor),
    db.doc(`users/${stage1Outsider.uid}`).set(stage1Outsider),
    db.doc('hospitals/stage1-hospital').set(stage1Hospital),
    db.doc(`users/${stage1Receiver.uid}/private/contact`).set({ phoneNumber: '+923001234567' }),
    db.doc('rate_limits/requests_stage1-receiver').delete(),
    db.doc('request_submission_guards/stage1-receiver').delete(),
    db.doc('rate_limits/sos_stage1-receiver').delete(),
    db.doc(`users/${stage1Donor.uid}/devices/emulator-device`).delete(),
  ]);
}

async function clearStage3Records() {
  const existingSos = (await db.doc('sosRequests/stage3-sos').get()).data();
  const records = [
    db.doc('sosRequests/stage3-sos'),
    db.doc('notifications/sos_stage3-sos_stage1-donor'),
    db.doc('rate_limits/donation_dispute_stage1-donor'),
    db.doc('rate_limits/donation_dispute_stage1-receiver'),
    db.doc('misuse_reports/donation_stage3-donation-request_stage1-donor'),
    db.doc('misuse_reports/donation_stage3-donation-request_stage1-receiver'),
    db.doc('notifications/donation_stage3-donation-request_stage1-donor'),
    db.doc('notifications/progress_stage3-donation-request_stage1-donor'),
    db.doc('donations/stage3-donation-request_stage1-donor'),
    db.doc('blood_requests/stage3-donation-request'),
  ];
  if (existingSos?.requestId) records.push(db.doc(`blood_requests/${existingSos.requestId}`));
  await Promise.all(records.map((ref) => ref.delete()));
}

function stage1Request(requestId, overrides = {}) {
  return {
    requestId,
    hospitalId: 'stage1-hospital',
    hospitalName: stage1Hospital.name,
    hospitalAddress: stage1Hospital.address,
    latitude: stage1Hospital.latitude,
    longitude: stage1Hospital.longitude,
    bloodGroup: 'O+',
    quantity: 2,
    urgency: 'normal',
    contactNumber: '+923001234567',
    requiredBy: Date.now() + 3_600_000,
    ...overrides,
  };
}

beforeEach(seed);

test('Stage 1 creates requests, idempotently accepts same IDs, and rejects recent duplicates', async () => {
  await seedStage1();
  const input = stage1Request('stage1-created');
  assert.deepEqual(
    await callWorkflow('createBloodRequest', identity(stage1Receiver.uid), input, env),
    { id: 'stage1-created', notificationStatus: 'complete' },
  );
  assert.deepEqual(
    await callWorkflow('createBloodRequest', identity(stage1Receiver.uid), input, env),
    { id: 'stage1-created', notificationStatus: 'complete' },
  );
  await assert.rejects(
    callWorkflow('createBloodRequest', identity(stage1Receiver.uid), stage1Request('stage1-duplicate'), env),
    { code: 'already-exists' },
  );
  const created = (await db.doc('blood_requests/stage1-created').get()).data();
  assert.equal(created.source, 'cloudflare');
  assert.equal(created.hospitalName, stage1Hospital.name);
  assert.equal((await db.collection('blood_requests/stage1-created/events').get()).size, 1);
});

test('Stage 1 returns the persisted request when FCM configuration fails and retries dispatch idempotently', async () => {
  await seedStage1();
  await db.doc(`users/${stage1Donor.uid}/devices/emulator-device`).set({
    fcmToken: 'synthetic-emulator-token',
  });
  const input = stage1Request('stage1-notification-retry');
  const envWithoutMessagingCredentials = { ...env };
  const first = await callWorkflow(
    'createBloodRequest',
    identity(stage1Receiver.uid),
    input,
    envWithoutMessagingCredentials,
  );
  assert.deepEqual(first, { id: 'stage1-notification-retry', notificationStatus: 'pending' });
  assert.equal((await db.doc('blood_requests/stage1-notification-retry').get()).exists, true);
  assert.equal((await db.collection('blood_requests/stage1-notification-retry/events').get()).size, 1);
  const retry = await callWorkflow(
    'createBloodRequest',
    identity(stage1Receiver.uid),
    input,
    envWithoutMessagingCredentials,
  );
  assert.deepEqual(retry, { id: 'stage1-notification-retry', notificationStatus: 'pending' });
  assert.equal((await db.collection('blood_requests/stage1-notification-retry/events').get()).size, 1);
  assert.deepEqual(
    (await db.doc('blood_requests/stage1-notification-retry').get()).data().notifiedDonors,
    [],
  );
  assert.equal(
    (await db.doc(`notifications/request_stage1-notification-retry_${stage1Donor.uid}`).get())
      .data().pushStatus,
    'failed',
  );
});

test('Stage 1 accepts, declines, and updates donor assignments', async () => {
  await seedStage1();
  await db.doc('blood_requests/stage1-accept').set({
    ...stage1Request('stage1-accept'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
    donatedUnits: 0,
    remainingUnits: 2,
  });
  assert.deepEqual(
    await callWorkflow('acceptDonation', identity(stage1Donor.uid), { requestId: 'stage1-accept' }, env),
    { accepted: true },
  );
  assert.equal(
    (await db.doc('blood_requests/stage1-accept').get()).data().commitments[stage1Donor.uid].status,
    'accepted',
  );
  assert.deepEqual(
    await callWorkflow('updateAssignment', identity(stage1Donor.uid), {
      requestId: 'stage1-accept',
      action: 'agree',
    }, env),
    { updated: true },
  );
  assert.equal(
    (await db.doc('blood_requests/stage1-accept').get()).data().commitments[stage1Donor.uid].status,
    'agreed',
  );

  await db.doc('blood_requests/stage1-decline').set({
    ...stage1Request('stage1-decline'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
    donatedUnits: 0,
    remainingUnits: 2,
  });
  assert.deepEqual(
    await callWorkflow('declineRequest', identity(stage1Donor.uid), { requestId: 'stage1-decline' }, env),
    { declined: true },
  );
  assert.equal(
    (await db.doc(`users/${stage1Donor.uid}`).get()).data().declinedRequestIds.includes('stage1-decline'),
    true,
  );
});

test('Stage 1 allows owner cancellation, rejects non-owner cancellation, and expires requests', async () => {
  await seedStage1();
  await db.doc('blood_requests/stage1-cancel').set({
    ...stage1Request('stage1-cancel'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
  });
  await assert.rejects(
    callWorkflow('closeRequest', identity(stage1Outsider.uid), {
      requestId: 'stage1-cancel',
      status: 'cancelled',
    }, env),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    callWorkflow('closeRequest', identity(stage1Donor.uid), {
      requestId: 'stage1-cancel',
      status: 'cancelled',
    }, env),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    callWorkflow('closeRequest', identity(stage1Receiver.uid), {
      requestId: 'stage1-cancel',
      status: 'fulfilled',
    }, env),
    { code: 'invalid-argument' },
  );
  assert.equal((await db.doc('blood_requests/stage1-cancel').get()).data().status, 'pending');
  assert.deepEqual(
    await callWorkflow('closeRequest', identity(stage1Receiver.uid), {
      requestId: 'stage1-cancel',
      status: 'cancelled',
    }, env),
    { closed: true },
  );
  assert.deepEqual(
    await callWorkflow('closeRequest', identity(stage1Receiver.uid), {
      requestId: 'stage1-cancel',
      status: 'cancelled',
    }, env),
    { closed: true },
  );
  assert.equal((await db.doc('blood_requests/stage1-cancel').get()).data().status, 'cancelled');

  await db.doc('users/stage1-admin').set({
    uid: 'stage1-admin',
    status: 'approved',
    role: 'admin',
  });
  await db.doc('blood_requests/stage1-admin-close').set({
    ...stage1Request('stage1-admin-close'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
  });
  assert.deepEqual(
    await callWorkflow('closeRequest', identity('stage1-admin'), {
      requestId: 'stage1-admin-close',
      status: 'cancelled',
    }, env),
    { closed: true },
  );
  assert.equal((await db.doc('blood_requests/stage1-admin-close').get()).data().status, 'cancelled');

  await db.doc('blood_requests/stage1-expired').set({
    ...stage1Request('stage1-expired', { requiredBy: Date.now() - 1000 }),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
  });
  await expireOpenRequestsForWorker(env);
  assert.equal((await db.doc('blood_requests/stage1-expired').get()).data().status, 'expired');
});

test('Stage 1 request locations are exact only for the owner and authorized donor', async () => {
  await seedStage1();
  await db.doc('blood_requests/stage1-privacy').set({
    ...stage1Request('stage1-privacy'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
  });
  const publicRequest = await callWorkflow(
    'getRequest',
    identity(stage1Donor.uid),
    { requestId: 'stage1-privacy' },
    env,
  );
  assert.equal(publicRequest.latitude, undefined);
  assert.equal(publicRequest.longitude, undefined);
  assert.equal(publicRequest.canViewPrivate, false);
  assert.equal(publicRequest.contactNumber, undefined);
  assert.equal(publicRequest.requesterPhone, undefined);

  const ownerRequest = await callWorkflow(
    'getRequest',
    identity(stage1Receiver.uid),
    { requestId: 'stage1-privacy' },
    env,
  );
  assert.equal(ownerRequest.latitude, 31.0543);
  assert.equal(ownerRequest.longitude, 74.0532);
  assert.equal(ownerRequest.canViewPrivate, true);

  await callWorkflow('acceptDonation', identity(stage1Donor.uid), {
    requestId: 'stage1-privacy',
  }, env);
  const participantRequest = await callWorkflow(
    'getRequest',
    identity(stage1Donor.uid),
    { requestId: 'stage1-privacy' },
    env,
  );
  assert.equal(participantRequest.latitude, 31.0543);
  assert.equal(participantRequest.longitude, 74.0532);
  assert.equal(participantRequest.requesterPhone, undefined);
});

test('Stage 1 request discovery filters by donor eligibility, compatibility, range and ownership', async () => {
  await seedStage1();
  await db.doc('blood_requests/stage1-discover').set({
    ...stage1Request('stage1-discover'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
  });
  const result = await callWorkflow(
    'discoverRequests',
    identity(stage1Donor.uid),
    { radiusKm: 10 },
    env,
  );
  assert.deepEqual(result.items.map((item) => item.id), ['stage1-discover']);
  assert.equal(result.items[0].requesterId, undefined);
  await assert.rejects(
    callWorkflow('discoverRequests', identity(stage1Receiver.uid), { radiusKm: 5 }, env),
    { code: 'permission-denied' },
  );
});

test('Stage 1 donor search returns matching nearby donors without private profile fields', async () => {
  await seedStage1();
  await db.doc(`users/${stage1Donor.uid}`).update({
    email: 'private@example.test',
    cnic: 'private-cnic',
    phoneNumber: '+923001234567',
  });
  const result = await callWorkflow('findDonors', identity(stage1Receiver.uid), {
    latitude: stage1Receiver.latitude,
    longitude: stage1Receiver.longitude,
    bloodGroup: 'O+',
    radiusKm: 10,
  }, env);
  assert.deepEqual(result.donors.map((entry) => entry.uid), [stage1Donor.uid]);
  assert.equal(result.donors[0].email, undefined);
  assert.equal(result.donors[0].cnic, undefined);
  assert.equal(result.donors[0].phoneNumber, undefined);
  await assert.rejects(
    callWorkflow('findDonors', identity(stage1Receiver.uid), {
      latitude: 200,
      longitude: 74,
      radiusKm: 5,
    }, env),
    { code: 'invalid-argument' },
  );
});

test('Stage 1 manual request notifications enforce owner access and deduplicate recipients', async () => {
  await seedStage1();
  await db.doc('blood_requests/stage1-notify').set({
    ...stage1Request('stage1-notify'),
    requesterId: stage1Receiver.uid,
    status: 'pending',
    participantIds: [stage1Receiver.uid],
    acceptedDonorIds: [],
    commitments: {},
    notifiedDonors: [],
  });
  const input = {
    requestId: 'stage1-notify',
    radiusKm: 10,
    userIds: [stage1Donor.uid],
  };
  await assert.rejects(
    callWorkflow('notifyRequest', identity(stage1Outsider.uid), input, env),
    { code: 'permission-denied' },
  );
  assert.deepEqual(
    await callWorkflow('notifyRequest', identity(stage1Receiver.uid), input, env),
    { count: 1, remaining: 0 },
  );
  assert.deepEqual(
    await callWorkflow('notifyRequest', identity(stage1Receiver.uid), input, env),
    { count: 0, remaining: 0 },
  );
  assert.deepEqual(
    (await db.doc('blood_requests/stage1-notify').get()).data().notifiedDonors,
    [stage1Donor.uid],
  );
  assert.equal(
    (await db.doc(`notifications/request_stage1-notify_${stage1Donor.uid}`).get())
      .data().pushStatus,
    'no_token',
  );
});

test('Stage 3A SOS saves, matches at configured radius, notifies once, authorizes reads, and resolves', async () => {
  await seedStage1();
  await clearStage3Records();
  await db.doc(`users/${stage1Donor.uid}`).update({ latitude: stage1Donor.latitude + 0.17 });
  const input = {
    submissionId: 'stage3-sos',
    bloodGroup: 'O+',
    urgency: 'critical',
    latitude: stage1Donor.latitude,
    longitude: stage1Donor.longitude,
    contactNumber: '+923001234567',
  };
  const created = await callWorkflow('createSosAlert', identity(stage1Receiver.uid), input, env);
  assert.equal(created.id, 'stage3-sos');
  assert.ok(created.requestId);
  const sos = (await db.doc('sosRequests/stage3-sos').get()).data();
  const request = (await db.doc(`blood_requests/${created.requestId}`).get()).data();
  assert.equal(sos.source, 'cloudflare');
  assert.equal(sos.status, 'processed');
  assert.equal(sos.radiusKm, 25);
  assert.equal(request.hospitalAddress, 'Emergency meeting point');
  assert.deepEqual(sos.notifiedDonors, [stage1Donor.uid]);
  const pushRecord = (await db.doc(`notifications/sos_stage3-sos_${stage1Donor.uid}`).get()).data();
  assert.equal(pushRecord.pushSentDirectly, true);
  assert.equal(pushRecord.pushStatus, 'no_token');

  assert.deepEqual(
    await callWorkflow('createSosAlert', identity(stage1Receiver.uid), input, env),
    { id: 'stage3-sos', requestId: created.requestId },
  );
  assert.deepEqual(
    await callWorkflow('getSos', identity(stage1Receiver.uid), { sosId: created.id }, env),
    {
      id: created.id,
      requestId: created.requestId,
      bloodGroup: 'O+',
      urgency: 'critical',
      status: 'processed',
      isResolved: false,
    },
  );
  await assert.rejects(
    callWorkflow('getSos', identity(stage1Outsider.uid), { sosId: created.id }, env),
    { code: 'permission-denied' },
  );
  await callWorkflow('acceptDonation', identity(stage1Donor.uid), {
    requestId: created.requestId,
  }, env);
  assert.equal(
    (await callWorkflow('getSos', identity(stage1Donor.uid), { sosId: created.id }, env)).id,
    created.id,
  );
  assert.deepEqual(
    await callWorkflow('resolveSos', identity(stage1Receiver.uid), {
      sosId: created.id,
      cancel: true,
    }, env),
    { resolved: true },
  );
  assert.equal((await db.doc(`sosRequests/${created.id}`).get()).data().status, 'cancelled');
  assert.equal((await db.doc(`blood_requests/${created.requestId}`).get()).data().status, 'cancelled');
});

test('Stage 3A donation confirmation, history, acknowledgement, dispute, and contact denial work', async () => {
  await seedStage1();
  await clearStage3Records();
  const requestId = 'stage3-donation-request';
  const donationId = `${requestId}_${stage1Donor.uid}`;
  await db.doc(`blood_requests/${requestId}`).set({
    ...stage1Request(requestId),
    requesterId: stage1Receiver.uid,
    status: 'accepted',
    participantIds: [stage1Receiver.uid, stage1Donor.uid],
    acceptedDonorIds: [stage1Donor.uid],
    commitments: {
      [stage1Donor.uid]: {
        status: 'awaiting_confirmation',
        donorConfirmedAt: FirestoreTimestamp.fromMillis(Date.now() - 60_000),
      },
    },
    donatedUnits: 0,
    remainingUnits: 1,
    quantity: 1,
  });
  const confirmation = await callWorkflow('confirmDonation', identity(stage1Receiver.uid), {
    requestId,
    donorId: stage1Donor.uid,
  }, env);
  assert.deepEqual(confirmation, {
    donationId,
    donatedUnits: 1,
    remainingUnits: 0,
  });
  assert.deepEqual(
    await callWorkflow('confirmDonation', identity(stage1Receiver.uid), {
      requestId,
      donorId: stage1Donor.uid,
    }, env),
    { donationId, alreadyConfirmed: true },
  );
  const donationRef = db.doc(`donations/${donationId}`);
  await donationRef.update({ phoneNumber: '+923001234567', privateContact: { phone: 'private' } });
  const donorHistory = await callWorkflow('donationHistory', identity(stage1Donor.uid), { limit: 50 }, env);
  assert.equal(donorHistory.items[0].id, donationId);
  assert.equal(donorHistory.items[0].statusLabel, 'completed');
  assert.equal(donorHistory.items[0].phoneNumber, undefined);
  assert.equal(donorHistory.items[0].privateContact, undefined);
  const receiverHistory = await callWorkflow('donationHistory', identity(stage1Receiver.uid), {}, env);
  assert.equal(receiverHistory.items[0].id, donationId);

  assert.deepEqual(
    await callWorkflow('acknowledgeDonation', identity(stage1Donor.uid), { donationId }, env),
    { acknowledged: true },
  );
  assert.deepEqual(
    await callWorkflow('acknowledgeDonation', identity(stage1Donor.uid), { donationId }, env),
    { alreadyAcknowledged: true },
  );
  assert.deepEqual(
    await callWorkflow('disputeDonation', identity(stage1Donor.uid), {
      donationId,
      reason: 'Please review this record.',
    }, env),
    { disputed: true },
  );
  assert.equal((await donationRef.get()).data().status, 'disputed');
  assert.deepEqual(
    await callWorkflow('disputeDonation', identity(stage1Donor.uid), {
      donationId,
      reason: 'Please review this record.',
    }, env),
    { alreadySubmitted: true },
  );
  const requesterDispute = {
    donationId,
    reason: 'Please correct the donation date.',
  };
  assert.deepEqual(
    await callWorkflow('submitDonationDispute', identity(stage1Receiver.uid), requesterDispute, env),
    { submitted: true },
  );
  assert.deepEqual(
    await callWorkflow('submitDonationDispute', identity(stage1Receiver.uid), requesterDispute, env),
    { alreadySubmitted: true },
  );
  await assert.rejects(
    callWorkflow('getDonorContact', identity(stage1Receiver.uid), {}, env),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    callWorkflow('acknowledgeDonation', identity(stage1Outsider.uid), { donationId }, env),
    { code: 'permission-denied' },
  );
});

test('chat workflow callables enforce participant scope and preserve callable results', async () => {
  const input = { conversationId: 'stage2-conversation' };

  assert.deepEqual(
    await callWorkflow('markConversationRead', identity(receiver.uid), input, env),
    { read: true },
  );
  assert.equal(
    (await db.doc('conversations/stage2-conversation').get()).data().unread[receiver.uid],
    0,
  );
  assert.deepEqual(
    await callWorkflow('blockUser', identity(receiver.uid), input, env),
    { blocked: true },
  );
  assert.deepEqual(
    (await db.doc('conversations/stage2-conversation').get()).data().blockedUserIds,
    [donor.uid],
  );
  assert.equal(
    (await db.doc('conversations/stage2-conversation').get()).data().blocks[receiver.uid].blockedUserId,
    donor.uid,
  );
  assert.deepEqual(
    await callWorkflow('unblockUser', identity(receiver.uid), input, env),
    { blocked: false },
  );

  const reportInput = { ...input, reason: 'Unwanted contact', messageId: 'sample' };
  assert.deepEqual(
    await callWorkflow('reportConversation', identity(receiver.uid), reportInput, env),
    { reported: true },
  );
  assert.deepEqual(
    await callWorkflow('reportConversation', identity(receiver.uid), reportInput, env),
    { alreadyReported: true },
  );
  await assert.rejects(
    callWorkflow('markConversationRead', identity(outsider.uid), input, env),
    { code: 'permission-denied' },
  );
});

test('notifyChatMessage verifies caller and message, increments unread once, and writes an FCM-suppressing inbox record', async () => {
  await db.doc('conversations/stage2-conversation/messages/valid-message').set({
    senderId: donor.uid,
    body: 'Available to help.',
  });
  const input = { conversationId: 'stage2-conversation', messageId: 'valid-message' };
  await assert.rejects(
    callWorkflow('notifyChatMessage', identity(donor.uid), {
      conversationId: 'stage2-conversation',
      messageId: 'missing-message',
    }, env),
    { code: 'permission-denied' },
  );
  await assert.rejects(
    callWorkflow('notifyChatMessage', identity(receiver.uid), input, env),
    { code: 'permission-denied' },
  );
  assert.deepEqual(
    await callWorkflow('notifyChatMessage', identity(donor.uid), input, env),
    { notified: true, sent: false },
  );
  assert.deepEqual(
    await callWorkflow('notifyChatMessage', identity(donor.uid), input, env),
    { notified: false },
  );

  const updated = (await db.doc('conversations/stage2-conversation').get()).data();
  assert.equal(updated.unread[receiver.uid], 1);
  const notification = (await db.doc('notifications/chat_stage2-conversation_valid-message').get()).data();
  assert.equal(notification.userId, receiver.uid);
  assert.equal(notification.pushSentDirectly, true);
  assert.equal(notification.pushStatus, 'no_token');

  await db.doc('conversations/stage2-conversation/messages/blocked-message').set({
    senderId: donor.uid,
    body: 'Blocked send.',
  });
  await db.doc('conversations/stage2-conversation').update({ blockedUserIds: [donor.uid] });
  assert.deepEqual(
    await callWorkflow('notifyChatMessage', identity(donor.uid), {
      conversationId: 'stage2-conversation',
      messageId: 'blocked-message',
    }, env),
    { notified: false },
  );
  assert.equal(
    (await db.doc('notifications/chat_stage2-conversation_blocked-message').get()).exists,
    false,
  );
  await assert.rejects(
    callWorkflow('notifyChatMessage', identity(outsider.uid), input, env),
    { code: 'permission-denied' },
  );
});

test('concurrent Worker and Firebase chat notification handlers create one inbox event and one unread increment', async () => {
  const conversationId = 'stage2-conversation';
  const messageId = 'cross-backend-race';
  const message = { senderId: donor.uid, body: 'Available to help.' };
  const event = {
    params: { conversationId, messageId },
    data: { data: () => message },
  };
  await db.doc(`conversations/${conversationId}/messages/${messageId}`).set(message);
  await db.doc(`conversations/${conversationId}`).update({
    requestId: 'stage2-request',
    unread: { [receiver.uid]: 0, [donor.uid]: 0 },
  });

  await Promise.all([
    callWorkflow('notifyChatMessage', identity(donor.uid), { conversationId, messageId }, env),
    notifyChatMessageFromFunction(event),
  ]);

  const notification = (await db.doc(`notifications/chat_${conversationId}_${messageId}`).get()).data();
  const currentConversation = (await db.doc(`conversations/${conversationId}`).get()).data();
  assert.equal(notification.userId, receiver.uid);
  assert.equal(currentConversation.unread[receiver.uid], 1);

  let pushCalls = 0;
  const pushHandler = createNotificationPushHandler(async () => {
    pushCalls++;
    return { sent: true };
  });
  await pushHandler({
    data: {
      data: () => notification,
      ref: { update: async () => {} },
    },
  });
  assert.equal(pushCalls, notification.pushSentDirectly ? 0 : 1);
});

test('phone sharing requires confirmation and writes a chat notification', async () => {
  const input = { conversationId: 'stage2-conversation', confirm: false };
  await assert.rejects(
    callWorkflow('sharePhoneNumber', identity(receiver.uid), input, env),
    { code: 'failed-precondition' },
  );
  assert.deepEqual(
    await callWorkflow('sharePhoneNumber', identity(receiver.uid), { ...input, confirm: true }, env),
    { shared: true },
  );
  const messagePage = await db.collection('conversations/stage2-conversation/messages').get();
  assert.equal(messagePage.size, 1);
  assert.equal(messagePage.docs[0].data().type, 'phone_share');
  const notification = (await db.doc(`notifications/chat_stage2-conversation_${messagePage.docs[0].id}`).get()).data();
  assert.equal(notification.pushSentDirectly, true);
  assert.equal(notification.userId, donor.uid);
  assert.equal((await db.doc('conversations/stage2-conversation').get()).data().unread[donor.uid], 1);
});
