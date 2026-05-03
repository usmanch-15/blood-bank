// GENERATED FILE - DO NOT EDIT
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static final FirebaseOptions web = FirebaseOptions(
    apiKey: 'XXX',
    appId: 'XXX',
    messagingSenderId: 'XXX',
    projectId: 'XXX',
    authDomain: 'XXX',
    storageBucket: 'XXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'XXX',
    appId: 'XXX',
    messagingSenderId: 'XXX',
    projectId: 'XXX',
    storageBucket: 'XXX',
  );
}
