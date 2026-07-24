import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String _accessTokenKey = 'citycalls_access_token';
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // No default here on purpose — the actual base URL is configured in one
  // place only, auth_providers.dart's `_apiBaseUrl`, so there's never a
  // question of which value is actually in effect.
  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {'Content-Type': 'application/json'})) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);
  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);

  // Sockets authenticate via a handshake `auth: {token}` payload (socket.io
  // has no header concept to intercept the way Dio's interceptor does above),
  // so SocketService needs the raw token, not just Dio's auto-attached header.
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  // LOCAL-provider file URLs (files.model.ts) are API-relative (e.g.
  // "/uploads/...") — served by citycalls-api itself, not a CDN, so they need
  // this origin prefixed. CLOUDINARY urls are already absolute. Mirrors
  // citycalls-admin-web's useFiles.ts resolveFileUrl().
  String get apiOrigin => dio.options.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
}
