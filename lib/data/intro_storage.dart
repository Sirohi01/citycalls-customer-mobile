import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers whether the user has already finished the intro (splash2-4).
class IntroStorage {
  static const _key = 'intro_seen';
  static const _storage = FlutterSecureStorage();

  static Future<bool> isSeen() async {
    try {
      return await _storage.read(key: _key) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      await _storage.write(key: _key, value: 'true');
    } catch (_) {}
  }
}
