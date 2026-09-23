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

// Backs the Alerts tab badge. Kept as its own provider rather than deriving
// the count from myNotificationsProvider: that list is capped at 100 rows and
// only fetched once a notification screen is opened, so deriving from it would
// under-count and would force a full list fetch just to render a badge.
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).unreadCount();
});

class NotificationActions {
  final Ref _ref;
  NotificationActions(this._ref);

  Future<void> markRead(String id) async {
    await _ref.read(notificationRepositoryProvider).markRead(id);
    _ref.invalidate(myNotificationsProvider);
    _ref.invalidate(unreadNotificationCountProvider);
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions(ref));
