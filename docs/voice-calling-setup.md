# Voice calling setup and current blocker

The repository now contains the Agora client/session integration scaffold, authenticated Firebase call-session endpoints, and participant-only session rules. Calling remains disabled until the Agora App ID and App Certificate are configured server-side and the Flutter dependency is resolved on a developer machine.

## Recommended provider

Use **Agora RTC Voice Calling for Flutter**. It is compatible with this Flutter/Android application and supports authenticated channel joining with short-lived tokens. Agora's official Flutter voice quickstart requires an App ID, a token server for production tokens, microphone permission, engine initialization, channel join/leave events, and connection-state callbacks:

- https://docs.agora.io/en/realtime-media/rtc/voice-quickstart/flutter
- https://docs.agora.io/en/realtime-media/rtc/build/authenticate-users/deploy-token-server

The Agora dependency is declared in `pubspec.yaml`, but no Agora credential is present in this repository, so the call feature is not yet operational.

Before genuine calling can be implemented and verified, choose one provider and supply:

1. A provider project and application identifier.
2. Server-only credentials stored as Firebase Functions secrets or environment configuration.
3. A trusted callable/backend endpoint that issues short-lived tokens after checking the accepted request and both participant IDs.
4. Firestore call-session rules allowing only the two participants to read or transition a session.
5. Flutter SDK configuration and Android microphone/audio permissions.
6. FCM or an equivalent provider notification path for ringing and missed calls.
7. Two authenticated Android devices for testing accept, reject, timeout, reconnect, background, and cleanup states.

## Required implementation sequence

1. Create an Agora project and keep its App Certificate only in Firebase Functions secrets or another trusted server environment.
2. Add the compatible Agora Flutter RTC package to `pubspec.yaml` and request Android `RECORD_AUDIO` permission.
3. The repository provides `createVoiceCallSession`, `getVoiceCallToken`, and `updateVoiceCallSession`. Configure and deploy them only after review; they verify request participants, create a random channel, issue a short-lived RTC token server-side, and write the session under `callSessions/{sessionId}`.
4. Add Firestore rules allowing only the two participant UIDs to read the session and only the trusted callable/backend to create or transition it. Clients must not write provider tokens or privileged fields.
5. Use FCM for ringing/missed-call notifications and keep the request-specific conversation available while the call is accepted or pending.
6. On hang-up, update the call session only; never call `confirmDonation` automatically. The existing donor-agreement and receiver-confirmed donation workflow remains the source of truth for donation completion.
7. Verify answer, reject, timeout, reconnect, background, terminated-app notification, microphone denial, and cleanup on two real authenticated Android devices.

No provider credentials are present in the repository, and no production Firebase resources have been deployed or modified for calling. Do not add an App Certificate, token, service account, or `.env` secret to Flutter source control.
