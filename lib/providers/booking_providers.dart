import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/booking_repository.dart';
import '../models/booking_models.dart';
import '../models/catalog_models.dart';
import 'auth_providers.dart';
import 'customer_providers.dart';

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

final symptomsProvider = FutureProvider<List<ServiceCategory>>((ref) {
  return ref.watch(bookingRepositoryProvider).listMasters('SYMPTOM');
});
