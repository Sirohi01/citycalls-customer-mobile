import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_models.dart';
import 'auth_providers.dart';

// GET /customers/me — fetched once and reused wherever the customer's own
// profile is needed (Home, Profile screens), same pattern as auth_providers.
final myProfileProvider = FutureProvider<Customer>((ref) async {
  return ref.watch(customerRepositoryProvider).getMyProfile();
});

class ProfileSetupNotifier extends StateNotifier<AsyncValue<Customer>?> {
  final Ref _ref;
  ProfileSetupNotifier(this._ref) : super(null);

  Future<void> save({
    required String name,
    required String email,
    required bool whatsappConsent,
    required bool emailConsent,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _ref.read(customerRepositoryProvider).getMyProfile();
      final updated = await _ref.read(customerRepositoryProvider).updateProfile(
            profile.id,
            name: name,
            email: email,
          );
      _ref.invalidate(myProfileProvider);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileSetupProvider = StateNotifierProvider<ProfileSetupNotifier, AsyncValue<Customer>?>((ref) {
  return ProfileSetupNotifier(ref);
});
