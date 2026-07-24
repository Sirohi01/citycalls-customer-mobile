import 'api_client.dart';
import '../models/complaint_models.dart';

class ComplaintRepository {
  final ApiClient _client;
  ComplaintRepository(this._client);

  Future<List<ComplaintSummary>> listMyComplaints() async {
    final res = await _client.dio.get('/complaints', queryParameters: {'limit': 100});
    return (res.data['data'] as List).map((c) => ComplaintSummary.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<void> createComplaint({required String subject, required String description, String? serviceRequestId}) async {
    await _client.dio.post('/complaints', data: {
      'subject': subject,
      'description': description,
      if (serviceRequestId != null && serviceRequestId.isNotEmpty) 'serviceRequestId': serviceRequestId,
    });
  }
}
