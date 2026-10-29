const admin = require('./firebaseAdmin');
const {liveConversation} = require('./requestPolicy');
const {active} = require('./donationPolicy');
// Stable notification ID makes Firestore event retries idempotent. The existing
// notifications trigger handles preferences, devices and delivery.
async function notifyChatMessage(event) {
  const message = event.data?.data();
  if (!message || typeof message.senderId !== 'string') return;
  const db = admin.firestore();
  const {conversationId, messageId} = event.params;
  await db.runTransaction(async tx => {
    const conversation = (await tx.get(db.doc(`conversations/${conversationId}`))).data();
    const ids = conversation?.participantIds;
    if (!Array.isArray(ids) || ids.length !== 2 || new Set(ids).size !== 2 || !ids.includes(message.senderId)) return;
    const recipient = ids.find(id => id !== message.senderId);
    if (Array.isArray(conversation.blockedUserIds) && conversation.blockedUserIds.includes(message.senderId)) return;
    const [sender, receiver, request] = await Promise.all([
      tx.get(db.doc(`users/${message.senderId}`)), tx.get(db.doc(`users/${recipient}`)),
      tx.get(db.doc(`blood_requests/${conversation.requestId}`)),
    ]);
    const r = request.data();
    if (!active(sender.data()) || !active(receiver.data()) || !liveConversation(conversation,r,message.senderId)) return;
    const unreadRef = db.doc(`conversations/${conversationId}`);
    const ref = db.doc(`notifications/chat_${conversationId}_${messageId}`);
    const existing = await tx.get(ref);
    if (existing.exists) return;
    tx.set(unreadRef,{unread:{[recipient]:admin.firestore.FieldValue.increment(1)}},{merge:true});
    tx.create(ref, {userId:recipient, type:'chat_message', relatedId:conversationId,
      title:'New message', body:'Open the app to view your message.',
      isRead:false, createdAt:admin.firestore.Timestamp.now()});
  });
}
module.exports = {notifyChatMessage};
