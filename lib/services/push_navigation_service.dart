import '../screens/requests/request_tracking_screen.dart';
import '../screens/settings/my_reports_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

import '../screens/notification/sos_alert_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../screens/notification/notification_history_screen.dart';
import '../screens/donor/eligibility_status_screen.dart';

/// ✅ PHASE 4 — Push Notification Handling (foreground banner + tap-to-navigate)
/// ----------------------------------------------------------------------
/// Before this file: NotificationService.init() only requested permission
/// and saved the FCM token — there was no code reacting to a push actually
/// arriving. Practical effect:
///   - App backgrounded/killed → OS shows the system tray notification
///     automatically (because our Cloud Functions send a `notification`
///     payload, not just `data`) — this already worked, nothing to fix.
///   - App OPEN (foreground) → nothing shown at all. FCM does not display
///     a system tray banner for foreground messages by default, so pushes
///     were silently missed while using the app.
///   - Tapping any notification → just opened the app, never navigated
///     anywhere relevant (no SOS screen, no eligibility screen, etc).
/// This file fixes both gaps.
///
/// ⚠️ IMPORTANT — scope of tap-navigation, read before adding more cases:
/// lib/app/app.dart (SmartBloodBankApp) sets up a full Provider/controller
/// architecture (AuthController, RewardController, etc.) with its own
/// AppRoutes — but main.dart's actual running app (BloodBankApp) does NOT
/// use SmartBloodBankApp and has no MultiProvider wrapping it. That means
/// screens like RewardsScreen (needs RewardController) or SosEmergencyScreen
/// (needs ReceiverController) would throw a ProviderNotFoundException if
/// pushed here. This file therefore ONLY navigates to screens confirmed to
/// be self-contained (they fetch their own data directly via
/// FirebaseAuth/Firestore, no Provider dependency):
///   - NotificationHistoryScreen (safe — default destination)
///   - EligibilityStatusScreen (safe — used for donation_confirmed)
/// Flagged separately for Usman: which architecture (BloodBankApp vs
/// SmartBloodBankApp) should actually be kept is a bigger decision that
/// needs to be made deliberately, not silently inside this file.

/// Global key so we can navigate to a screen from OUTSIDE the widget tree —
/// e.g. when the user taps a push notification while the app is backgrounded,
/// or opens the app fresh from a terminated state by tapping a notification.
/// Attach this to MaterialApp(navigatorKey: rootNavigatorKey).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// MUST be a top-level (or static) function — FCM invokes this in a
/// separate background isolate when a push arrives while the app is fully
/// killed or backgrounded, so it needs its own Firebase.initializeApp() call.
/// Register it in main() via:
///   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Nothing else needed here — the OS already shows the system tray
  // notification on its own because our Cloud Functions send a
  // `notification` payload. This handler's job is just to exist (Android
  // logs a warning otherwise) and gives us a place to add custom logic
  // later (e.g. local badge counts) if needed.
}

class PushNavigationService {
  PushNavigationService._();
  static final PushNavigationService instance = PushNavigationService._();

  bool _initialized = false;
  bool _landingReady = false;
  RemoteMessage? _pendingMessage;

  void sessionLanded() {
    _landingReady = true;
    final pending = _pendingMessage;
    _pendingMessage = null;
    if (pending != null) _handleNotificationTap(pending);
  }

  /// Call once from main.dart, right after runApp(). Safe to call before
  /// the navigator is mounted — listeners just get registered immediately,
  /// and the one case that actually needs to navigate (a cold-start tap)
  /// waits for the first frame before pushing anything.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) App is OPEN (foreground) when the push arrives.
    FirebaseMessaging.onMessage.listen(_showForegroundBanner);

    // 2) App was BACKGROUNDED (not killed) and the user tapped the system
    //    notification to bring the app to the foreground.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 3) App was fully TERMINATED and got launched BY tapping a
    //    notification. (Returns null on a normal app launch.)
    RemoteMessage? initialMessage;
    try {
      initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    } catch (e) {
      debugPrint('Push startup unavailable: $e');
    }
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage!);
      });
    }
  }

  void _showForegroundBanner(RemoteMessage message) {
    final context = rootNavigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    final title = message.notification?.title ?? 'Smart Blood Bank';
    final body = message.notification?.body ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleNotificationTap(message),
        ),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (!_landingReady) {
      _pendingMessage = message;
      return;
    }
    openNotification(message.data['type'], message.data['relatedId']);
  }

  Future<void> openNotification(String? type, String? relatedId) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    final auth = navigator.context.read<AuthController>();
    if (!auth.isLoggedIn) return;
    try {
      if (type == 'report_update') {
        navigator.push(
          MaterialPageRoute(builder: (_) => const MyReportsScreen()),
        );
        return;
      }
      if ([
            'blood_request',
            'request_update',
            'general',
            'donation_confirmed',
          ].contains(type) &&
          relatedId != null &&
          relatedId.isNotEmpty &&
          !relatedId.contains('/')) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => RequestTrackingScreen(requestId: relatedId),
          ),
        );
        return;
      }
      if ((type == 'sosAlerts' || type == 'sos') &&
          relatedId != null &&
          !relatedId.contains('/')) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => SosAlertDetailScreen(requestId: relatedId),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Notification destination unavailable: $e');
    }

    switch (type) {
      case 'donation_confirmed':
      case 'rewardUpdates':
        if (!auth.isDonor) return;
        navigator.push(
          MaterialPageRoute(builder: (_) => const EligibilityStatusScreen()),
        );
        break;
      case 'sos':
      case 'adminAnnouncements':
      case 'general':
      default:
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
        );
    }
  }
}
