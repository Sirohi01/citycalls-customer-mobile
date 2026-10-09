import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The mobile number of the last successful login on this phone. After a
/// logout the login screen offers it back ("Continue with +91 …") alongside
/// "Use a different number".
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
