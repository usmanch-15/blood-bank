function createNotificationPushHandler(sendPushToUser) {
  return async (event) => {
    const data = event.data?.data();
    if (!data || !data.userId || data.pushSentDirectly) return;

    const delivery = await sendPushToUser(data.userId, {
      title: data.title || 'Smart Blood Bank',
      body: data.body || '',
      data: { type: data.type || 'general', relatedId: data.relatedId || '' },
      record: false,
    });
    await event.data.ref.update({ pushStatus: delivery.sent ? 'sent' : delivery.reason });
  };
}

module.exports = { createNotificationPushHandler };
