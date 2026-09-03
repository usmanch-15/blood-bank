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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAAvCmMqFvSrS0NFQAuLvL5hOWqJZq5kDI',
    // NOTE: No dedicated Web app is registered in the Firebase project, so the
    // Android appId is used here as a placeholder. This is enough for the SDK
    // to initialize on web (clearing the pre-existing FirebaseException). For
    // real web backend calls, register a Web app in the Firebase console and
    // replace this with its '1:1081691076539:web:...' appId.
    appId: '1:1081691076539:android:cb46f647e60989eae1769e',
    messagingSenderId: '1081691076539',
    projectId: 'blood-bank-98037',
    authDomain: 'blood-bank-98037.firebaseapp.com',
    storageBucket: 'blood-bank-98037.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAAvCmMqFvSrS0NFQAuLvL5hOWqJZq5kDI',
    appId: '1:1081691076539:android:cb46f647e60989eae1769e',
    messagingSenderId: '1081691076539',
    projectId: 'blood-bank-98037',
    storageBucket: 'blood-bank-98037.firebasestorage.app',
  );
}
