import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/complaint_repository.dart';
import '../models/complaint_models.dart';
import 'auth_providers.dart';

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return ComplaintRepository(ref.watch(apiClientProvider));
});

final myComplaintsProvider = FutureProvider<List<ComplaintSummary>>((ref) async {
  return ref.watch(complaintRepositoryProvider).listMyComplaints();
});
