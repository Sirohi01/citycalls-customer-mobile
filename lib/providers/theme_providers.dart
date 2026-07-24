import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _beautyModeKey = 'citycalls_beauty_mode';

// Mobile counterpart of citycalls-admin-web's useBeautyMode.ts — same
// localStorage-persisted on/off toggle, same "Beauty Mode" naming, just
// backed by secure storage (already the app's storage mechanism, see
// api_client.dart) instead of localStorage.
class BeautyModeNotifier extends StateNotifier<bool> {
  BeautyModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.read(key: _beautyModeKey);
    state = saved == 'true';
  }

  Future<void> toggle() async {
    state = !state;
    await _storage.write(key: _beautyModeKey, value: state.toString());
  }
}

final beautyModeProvider = StateNotifierProvider<BeautyModeNotifier, bool>((ref) {
  return BeautyModeNotifier();
});
