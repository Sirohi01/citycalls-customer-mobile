import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/service_request_repository.dart';
import '../models/reopen_models.dart';
import '../models/service_request_models.dart';
import '../models/visit_models.dart';
import 'auth_providers.dart';

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>((ref) {
  return ServiceRequestRepository(ref.watch(apiClientProvider));
});

final myServiceRequestsProvider = FutureProvider<List<ServiceRequestSummary>>((ref) async {
  return ref.watch(serviceRequestRepositoryProvider).listMyRequests();
});

final serviceRequestDetailProvider = FutureProvider.family<ServiceRequestDetail, String>((ref, id) async {
  return ref.watch(serviceRequestRepositoryProvider).getServiceRequest(id);
});

final assignmentHistoryProvider = FutureProvider.family<List<AssignmentHistoryEntry>, String>((ref, id) async {
  return ref.watch(serviceRequestRepositoryProvider).getAssignmentHistory(id);
});

final activityLogProvider = FutureProvider.family<List<ActivityLogEntry>, String>((ref, id) async {
  return ref.watch(serviceRequestRepositoryProvider).getActivityLog(id);
});

final serviceVisitsProvider = FutureProvider.family<List<ServiceVisit>, String>((ref, id) async {
  return ref.watch(serviceRequestRepositoryProvider).listVisits(id);
});

final reopenHistoryProvider = FutureProvider.family<List<ReopenRecord>, String>((ref, id) async {
  return ref.watch(serviceRequestRepositoryProvider).getReopenHistory(id);
});
