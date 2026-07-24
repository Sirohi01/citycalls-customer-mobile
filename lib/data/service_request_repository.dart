import 'api_client.dart';
import '../models/service_request_models.dart';

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
class ServiceRequestRepository {
  final ApiClient _client;
  ServiceRequestRepository(this._client);

  Future<List<ServiceRequestSummary>> listMyRequests() async {
    final res = await _client.dio.get('/service-requests', queryParameters: {'limit': 100});
    return (res.data['data'] as List).map((sr) => ServiceRequestSummary.fromJson(sr as Map<String, dynamic>)).toList();
  }

  Future<ServiceRequestDetail> getServiceRequest(String id) async {
    final res = await _client.dio.get('/service-requests/$id');
    return ServiceRequestDetail.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<AssignmentHistoryEntry>> getAssignmentHistory(String id) async {
    final res = await _client.dio.get('/service-requests/$id/assignment-history');
    return (res.data['data'] as List).map((e) => AssignmentHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelServiceRequest(String id, String reason) async {
    await _client.dio.post('/service-requests/$id/cancel', data: {'reason': reason});
  }

  Future<void> requestReschedule(String id, {required DateTime scheduledDate, required String scheduledSlot, String? reason}) async {
    await _client.dio.patch('/service-requests/$id/reschedule', data: {
      'scheduledDate': scheduledDate.toIso8601String(),
      'scheduledSlot': scheduledSlot,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> reopenServiceRequest(String id, String reason) async {
    await _client.dio.post('/service-requests/$id/reopen', data: {'reason': reason});
  }

  Future<void> submitFeedback(String id, int rating, String? remarks) async {
    await _client.dio.post('/service-requests/$id/feedback', data: {
      'rating': rating,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
    });
  }
}
