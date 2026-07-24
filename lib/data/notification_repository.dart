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

  Future<void> markRead(String id) async {
    await _client.dio.patch('/notifications/$id/read');
  }
}
