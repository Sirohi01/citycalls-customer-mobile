import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository.dart';
import '../models/notification_models.dart';
import 'auth_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

final myNotificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return ref.watch(notificationRepositoryProvider).listMyNotifications();
});

class NotificationActions {
  final Ref _ref;
  NotificationActions(this._ref);

  Future<void> markRead(String id) async {
    await _ref.read(notificationRepositoryProvider).markRead(id);
    _ref.invalidate(myNotificationsProvider);
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions(ref));
