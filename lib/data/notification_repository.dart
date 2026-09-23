import 'api_client.dart';
import '../models/notification_models.dart';

class NotificationRepository {
  final ApiClient _client;
  NotificationRepository(this._client);
  Future<List<AppNotification>> listMyNotifications() async {
    final res = await _client.dio.get('/notifications',
        queryParameters: {'channel': 'IN_APP', 'limit': 100});
    return (res.data['data'] as List)
        .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  // Self-scoped, no permission gate (notifications.routes.ts) — backs the
  // unread badge on the Alerts tab. Scoped to IN_APP: the backend creates one
  // Notification doc per channel per event (PUSH/EMAIL/WHATSAPP/SMS/IN_APP),
  // but this app only ever lists and marks IN_APP ones read, so an unscoped
  // count included the other channels' docs and never reached zero.
  Future<int> unreadCount() async {
    final res = await _client.dio
        .get('/notifications/unread-count', queryParameters: {'channel': 'IN_APP'});
    return (res.data['data']['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _client.dio.patch('/notifications/$id/read');
  }
}
