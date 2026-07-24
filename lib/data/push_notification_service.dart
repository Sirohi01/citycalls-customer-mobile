import 'package:firebase_messaging/firebase_messaging.dart';
import 'customer_repository.dart';

// Registers this device's FCM token with the backend so
// PUSH-channel notifications (citycalls-api's src/lib/pushAdapter.ts) can
// actually reach it. Token registration/foreground listening only —
// permission is requested here too since Android 13+ and iOS both require
// an explicit runtime prompt, not just declaring it in the manifest/plist.
class PushNotificationService {
  final CustomerRepository _customerRepo;
  PushNotificationService(this._customerRepo);

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) await _registerSafely(token);

    // Tokens rotate (app reinstall, data clear, FCM-side refresh) — without
    // this, a device would silently stop receiving pushes after a rotation
    // until the next full app restart happened to re-register.
    messaging.onTokenRefresh.listen(_registerSafely);
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
