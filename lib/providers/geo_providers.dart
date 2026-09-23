import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/geo_repository.dart';
import '../models/geo_models.dart';
import 'auth_providers.dart';

final geoRepositoryProvider = Provider<GeoRepository>((ref) {
  return GeoRepository(ref.watch(apiClientProvider));
});

// Keyed on the PIN itself so a re-typed PIN is served from cache instead of
// re-hitting the API on every keystroke-triggered lookup.
final pincodeLookupProvider =
    FutureProvider.family<PincodeArea?, String>((ref, pinCode) async {
  return ref.watch(geoRepositoryProvider).lookupPincode(pinCode);
});
