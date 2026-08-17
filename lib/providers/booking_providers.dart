import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';
import '../models/booking_models.dart';
import '../models/catalog_models.dart';
import 'auth_providers.dart';
import 'customer_providers.dart';
import 'catalog_providers.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.watch(apiClientProvider));
});

final customerProductsProvider = FutureProvider<List<CustomerProductSummary>>((ref) async {
  final customerId = (await ref.watch(myProfileProvider.future)).id;
  return ref.watch(bookingRepositoryProvider).listProducts(customerId);
});

final brandsProvider = FutureProvider<List<ServiceCategory>>((ref) {
  return ref.watch(bookingRepositoryProvider).listMasters('BRAND');
});

final productTypesProvider = FutureProvider<List<ServiceCategory>>((ref) {
  return ref.watch(bookingRepositoryProvider).listMasters('PRODUCT_TYPE');
});

// Scoped to the service being booked — shows only the symptoms actually
// linked to that appliance/service (Service.symptomIds), not every symptom
// across every product in the catalog.
final serviceSymptomsProvider = FutureProvider.family<List<ServiceCategory>, String>((ref, serviceId) {
  return ref.watch(bookingRepositoryProvider).listServiceSymptoms(serviceId);
});

// Re-resolves branch coverage using the booking address actually chosen in
// the wizard (not the earlier Service Detail screen's PIN, which may belong
// to a different saved address) — mirrors exactly what
// serviceRequests.service.ts's resolveBranch() does at submit time, so the
// slots shown here are for the same branch that will actually get the
// request.
final bookingBranchProvider = FutureProvider.family<CoverageResult, ({String serviceId, String pinCode})>((ref, args) {
  return ref.watch(catalogRepositoryProvider).checkCoverage(args.serviceId, args.pinCode);
});

final appointmentSlotsProvider = FutureProvider.family<AppointmentSlotsResult, ({String branchId, DateTime date})>((ref, args) {
  return ref.watch(bookingRepositoryProvider).getAppointmentSlots(args.branchId, args.date);
});
