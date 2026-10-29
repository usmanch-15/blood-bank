const test = require('node:test');
const assert = require('node:assert/strict');
const { createNotificationPushHandler } = require('../notificationTrigger');

test('Worker notifications marked pushSentDirectly are not pushed again', async () => {
  let calls = 0;
  let updates = 0;
  const handler = createNotificationPushHandler(async () => {
    calls++;
    return { sent: true };
  });

  await handler({
    data: {
      data: () => ({ userId: 'recipient', pushSentDirectly: true }),
      ref: { update: async () => { updates++; } },
    },
  });

  assert.equal(calls, 0);
  assert.equal(updates, 0);
});

test('notifications without pushSentDirectly are pushed once by the trigger', async () => {
  const calls = [];
  const updates = [];
  const handler = createNotificationPushHandler(async (...args) => {
    calls.push(args);
    return { sent: true };
  });

  await handler({
    data: {
      data: () => ({ userId: 'recipient', title: 'New message', type: 'chat_message' }),
      ref: { update: async (value) => updates.push(value) },
    },
  });

  assert.equal(calls.length, 1);
  assert.equal(calls[0][0], 'recipient');
  assert.equal(calls[0][1].record, false);
  assert.deepEqual(updates, [{ pushStatus: 'sent' }]);
});
