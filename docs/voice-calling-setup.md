# Voice calling setup blocker

The repository currently has no voice SDK, provider account, call-token service, or call signaling implementation. The app therefore does not expose a call action that could be mistaken for a working call.

Before genuine calling can be implemented and verified, choose one provider and supply:

1. A provider project and application identifier.
2. Server-only credentials stored as Firebase Functions secrets or environment configuration.
3. A trusted callable/backend endpoint that issues short-lived tokens after checking the accepted request and both participant IDs.
4. Firestore call-session rules allowing only the two participants to read or transition a session.
5. Flutter SDK configuration and Android microphone/audio permissions.
6. FCM or an equivalent provider notification path for ringing and missed calls.
7. Two authenticated Android devices for testing accept, reject, timeout, reconnect, background, and cleanup states.

No provider credentials are present in the repository, and no production Firebase resources have been deployed or modified for calling.
