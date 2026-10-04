import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Optional services are explicit per environment. Never enforce App Check
/// before registering the actual app and verifying attestation in the console.
Future<void> configureFirebaseRuntime() async {
  const emulator = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  const host = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );
  if (emulator) {
    if (kReleaseMode) {
      throw StateError('Emulators are disabled in release builds.');
    }
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    return;
  }
  if (const bool.fromEnvironment('ENABLE_APP_CHECK')) {
    const webKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');
    if (kIsWeb && webKey.isEmpty) {
      throw StateError('RECAPTCHA_SITE_KEY is required.');
    }
    await FirebaseAppCheck.instance.activate(
      webProvider: kIsWeb ? ReCaptchaV3Provider(webKey) : null,
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(
      kReleaseMode && const bool.fromEnvironment('ENABLE_CRASHLYTICS'),
    );
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      crashlytics.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
