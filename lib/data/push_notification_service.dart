import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../app_navigator.dart';
import '../screens/my_complaints_screen.dart';
import 'customer_repository.dart';

// Registers this device's FCM token with the backend so
// PUSH-channel notifications (citycalls-api's src/lib/pushAdapter.ts) can
// actually reach it. Token registration, foreground listening, and routing
// a tapped notification to the screen it's about — permission is requested
// here too since Android 13+ and iOS both require an explicit runtime
// prompt, not just declaring it in the manifest/plist.
class PushNotificationService {
  final CustomerRepository _customerRepo;
  PushNotificationService(this._customerRepo);

  bool _tapHandlersAttached = false;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) await _registerSafely(token);

    // Tokens rotate (app reinstall, data clear, FCM-side refresh) — without
    // this, a device would silently stop receiving pushes after a rotation
    // until the next full app restart happened to re-register.
    messaging.onTokenRefresh.listen(_registerSafely);

    _attachTapHandlers(messaging);
  }

  // Tapping a push used to do nothing at all — the app only ever showed a
  // SnackBar for foreground messages and ignored the tap entirely, so a
  // notification about a job was a dead end.
  //
  // citycalls-api sends only `{triggerKey}` as the push data payload
  // (src/lib/notifications.ts), with no entity id, so this routes to the
  // right SCREEN rather than to the exact record. Deep-linking to a single
  // service request needs the backend to include its id in that payload.
  void _attachTapHandlers(FirebaseMessaging messaging) {
    if (_tapHandlersAttached) return;
    _tapHandlersAttached = true;

    FirebaseMessaging.onMessageOpenedApp.listen(_openFor);

    // A push that launched the app from terminated state isn't delivered
    // through onMessageOpenedApp — it's only readable once, here.
    messaging.getInitialMessage().then((message) {
      if (message != null) _openFor(message);
    });
  }

  void _openFor(RemoteMessage message) {
    final navigator = appNavigator;
    if (navigator == null) return;
    final triggerKey = (message.data['triggerKey'] ?? '').toString().toLowerCase();

    // Complaints aren't a tab, and MyComplaintsScreen has its own AppBar, so
    // it's safe to push as a route.
    if (triggerKey.contains('complaint')) {
      navigator.push(MaterialPageRoute(builder: (_) => const MyComplaintsScreen()));
      return;
    }

    // Everything else lives in a bottom tab. Unwind to the shell and switch
    // tabs rather than pushing the tab's screen on top of the stack — those
    // screens have no back affordance of their own.
    pendingShellTab.value = _tabFor(triggerKey);
    navigator.popUntil((route) => route.isFirst);
  }

  int _tabFor(String triggerKey) {
    if (triggerKey.contains('service_request') ||
        triggerKey.contains('estimate') ||
        triggerKey.contains('invoice') ||
        triggerKey.contains('payment') ||
        triggerKey.contains('visit') ||
        triggerKey.contains('technician')) {
      return ShellTab.bookings;
    }
    return ShellTab.alerts;
  }

  Future<void> _registerSafely(String token) async {
    try {
      await _customerRepo.registerFcmToken(token);
    } catch (_) {
      // Best-effort — a failed registration just means this device won't
      // get pushes until the next successful attempt (app resume, token
      // refresh), not worth surfacing to the user over.
    }
  }

  // Called on logout — without this, a device keeps receiving the outgoing
  // account's pushes (or worse, whoever logs in next on this device would
  // receive the previous account's tokens still registered against them,
  // since registerFcmToken uses $addToSet without ever clearing old owners).
  Future<void> unregisterCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _customerRepo.unregisterFcmToken(token);
    } catch (_) {
      // Best-effort on logout too — worst case the token lingers on the old
      // account until it naturally goes stale/gets replaced.
    }
  }
}
