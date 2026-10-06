import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The mobile number from the last login made with "Remember me" ticked —
/// pre-filled (with the box ticked) the next time the login screen opens.
class RememberedLoginStorage {
  static const _key = 'citycalls_remembered_mobile';
  static const _storage = FlutterSecureStorage();

  static Future<String?> readMobile() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveMobile(String mobile) async {
    try {
      await _storage.write(key: _key, value: mobile);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
