import { firebaseAccessToken } from './firestore_rest.js';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

function isInvalidRegistrationToken(errorBody) {
  const details = errorBody?.error?.details;
  if (Array.isArray(details) && details.some((detail) => ['UNREGISTERED', 'NOT_FOUND'].includes(detail.errorCode))) {
    return true;
  }
  const message = String(errorBody?.error?.message || '');
  return message.includes('UNREGISTERED') || message.includes('NOT_FOUND');
}

export async function sendPush(env, token, payload, fetchImpl = fetch) {
  const projectId = String(env.FIREBASE_PROJECT_ID || '');
  if (!projectId) throw new Error('Firebase project configuration is missing.');

  const bearer = await firebaseAccessToken(env, FCM_SCOPE, fetchImpl);
  const response = await fetchImpl(
    `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(projectId)}/messages:send`,
    {
      method: 'POST',
      headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: payload.title, body: payload.body },
          data: Object.fromEntries(Object.entries(payload.data).map(([key, value]) => [key, String(value)])),
          android: {
            priority: 'HIGH',
            notification: {
              channelId: 'blood_requests',
              tag: payload.data.relatedId || 'blood-bank',
            },
          },
          apns: { headers: { 'apns-priority': '10' } },
        },
      }),
    },
  );

  if (response.ok) return { delivered: true, invalidToken: false, status: response.status };
  const errorBody = await response.json().catch(() => null);
  return {
    delivered: false,
    invalidToken: isInvalidRegistrationToken(errorBody),
    status: response.status,
  };
}
