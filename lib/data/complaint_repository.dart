import 'api_client.dart';
import '../models/complaint_models.dart';

class ComplaintRepository {
  final ApiClient _client;
  ComplaintRepository(this._client);

  Future<List<ComplaintSummary>> listMyComplaints() async {
    final res = await _client.dio.get('/complaints', queryParameters: {'limit': 100});
    return (res.data['data'] as List).map((c) => ComplaintSummary.fromJson(c as Map<String, dynamic>)).toList();
  }

  // Same shape as the list rows, but this is the only way to read a
  // complaint's staff `response` after it's been answered — the list is
  // capped at 100 and the detail screen should never depend on the row
  // still being in that page.
  Future<ComplaintSummary> getComplaint(String id) async {
    final res = await _client.dio.get('/complaints/$id');
    return ComplaintSummary.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> createComplaint({required String subject, required String description, String? serviceRequestId}) async {
    await _client.dio.post('/complaints', data: {
      'subject': subject,
      'description': description,
      if (serviceRequestId != null && serviceRequestId.isNotEmpty) 'serviceRequestId': serviceRequestId,
    });
  }
}
