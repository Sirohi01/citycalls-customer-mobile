import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/push_notification_service.dart';
import 'auth_providers.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(customerRepositoryProvider));
});

// Foreground messages don't show a system notification banner on their own
// (that's an OS behavior for background/terminated apps only) — MainShell
// listens to this and shows an in-app SnackBar instead, since the user is
// already looking at the app when these arrive.
final foregroundPushMessageProvider = StreamProvider<RemoteMessage>((ref) {
  return FirebaseMessaging.onMessage;
});
