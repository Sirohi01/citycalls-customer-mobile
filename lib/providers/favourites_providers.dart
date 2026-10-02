import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'customer_providers.dart';

// Favourite services, saved on the device. The backend has no favourites
// endpoint, so they don't sync across phones. Keyed by customer id so two
// accounts on one phone keep separate lists.
class FavouritesNotifier extends AsyncNotifier<Set<String>> {
  static const _storage = FlutterSecureStorage();
  late String _key;

  @override
  Future<Set<String>> build() async {
    final customer = await ref.watch(myProfileProvider.future);
    _key = 'citycalls_favourite_services_${customer.id}';
    final raw = await _storage.read(key: _key);
    if (raw == null) return <String>{};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Adds or removes [serviceId]; returns true if it is now a favourite.
  Future<bool> toggle(String serviceId) async {
    final current = {...(state.valueOrNull ?? await future)};
    final added = current.add(serviceId);
    if (!added) current.remove(serviceId);
    state = AsyncData(current);
    await _storage.write(key: _key, value: jsonEncode(current.toList()));
    return added;
  }
}

final favouritesProvider =
    AsyncNotifierProvider<FavouritesNotifier, Set<String>>(
        FavouritesNotifier.new);
