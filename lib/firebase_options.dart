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

  // ── Web App (from Firebase Console → Project Settings → Web app) ──────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDcULNyjZU18QFe9wiOmOUMhUw3zSdyFxg',
    appId:             '1:1081691076539:web:547efc4692cdb66de1769e',
    messagingSenderId: '1081691076539',
    projectId:         'blood-bank-98037',
    authDomain:        'blood-bank-98037.firebaseapp.com',
    storageBucket:     'blood-bank-98037.firebasestorage.app',
  );

  // ── Android App (from google-services.json) ───────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyAAvCmMqFvSrS0NFQAuLvL5hOWqJZq5kDI',
    appId:             '1:1081691076539:android:cb46f647e60989eae1769e',
    messagingSenderId: '1081691076539',
    projectId:         'blood-bank-98037',
    storageBucket:     'blood-bank-98037.firebasestorage.app',
  );
}