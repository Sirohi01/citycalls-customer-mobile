import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// What a repository needs from a server connection. Lets one repository talk
// to a different server than the rest of the app (see SecondaryApiClient).
abstract class ApiTarget {
  Dio get dio;
  String get apiOrigin;
  String resolveUrl(String url);
}

class ApiClient implements ApiTarget {
  static const String _accessTokenKey = 'citycalls_access_token';
  static const String _refreshTokenKey = 'citycalls_refresh_token';
  static const String _retriedFlag = 'citycalls_retried_after_refresh';

  @override
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Flipped to true once a refresh has failed and the tokens have been
  // cleared. main.dart listens on this and sends the user back to login —
  // without it, every screen just silently shows an error forever after the
  // session expires, which is exactly what used to happen.
  final ValueNotifier<bool> sessionExpired = ValueNotifier(false);

  // A single in-flight refresh shared by every request that 401s at the same
  // time. Five providers refetching on one screen would otherwise fire five
  // parallel refreshes, and since the backend ROTATES the refresh token on
  // each call (auth.service.ts revokes the old session), all but the first
  // would fail and log a perfectly valid session out.
  Future<bool>? _refreshInFlight;

  // "Remember me" off: the tokens live only in memory for this app run, so
  // the next cold start lands on login. On (the default), they're kept in
  // secure storage and the session survives restarts.
  bool _persistTokens = true;
  String? _memoryAccessToken;
  String? _memoryRefreshToken;

  // No default here on purpose — the actual base URL is configured in one
  // place only, auth_providers.dart's `_apiBaseUrl`, so there's never a
  // question of which value is actually in effect.
  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 ||
            _isAuthRoute(error.requestOptions.path) ||
            // dio.fetch() below re-enters this same interceptor chain, so a
            // request that 401s AGAIN after a successful refresh would kick
            // off a second refresh. Marking the retry stops that loop at one
            // attempt and surfaces the real 401 to the caller.
            error.requestOptions.extra[_retriedFlag] == true) {
          return handler.next(error);
        }

        final refreshed = await _refreshAccessToken();
        if (!refreshed) return handler.next(error);

        try {
          handler.resolve(await _retry(error.requestOptions));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ));
  }

  // Login/OTP/refresh legitimately return 401 on bad credentials — retrying
  // those through the refresh path would be meaningless and would surface the
  // wrong error message to the user.
  bool _isAuthRoute(String path) =>
      path.contains('/auth/login') || path.contains('/auth/otp') || path.contains('/auth/refresh');

  Future<bool> _refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await readRefreshToken();
    if (refreshToken == null) {
      await _endSession();
      return false;
    }
    try {
      // Goes through the same Dio (and therefore the same adapter/base URL)
      // as everything else. _isAuthRoute() keeps this call out of the 401
      // branch above, so it can't recurse into another refresh.
      final res = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
      final data = res.data['data'] as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on DioException {
      await _endSession();
      return false;
    }
  }

  Future<void> _endSession() async {
    await clearTokens();
    sessionExpired.value = true;
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final token = await readAccessToken();
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedFlag] = true;
    return dio.fetch(options);
  }

  // [persist] is set at login from the "Remember me" checkbox; a refresh
  // omits it and keeps whichever mode the session started in.
  Future<void> saveTokens({required String accessToken, required String refreshToken, bool? persist}) async {
    if (persist != null) _persistTokens = persist;
    if (_persistTokens) {
      _memoryAccessToken = null;
      _memoryRefreshToken = null;
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } else {
      _memoryAccessToken = accessToken;
      _memoryRefreshToken = refreshToken;
      // Drop any session an earlier "remembered" login left on disk.
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    }
  }

  Future<void> clearTokens() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<String?> readRefreshToken() async =>
      _memoryRefreshToken ?? await _storage.read(key: _refreshTokenKey);

  // Sockets authenticate via a handshake `auth: {token}` payload (socket.io
  // has no header concept to intercept the way Dio's interceptor does above),
  // so SocketService needs the raw token, not just Dio's auto-attached header.
  Future<String?> readAccessToken() async =>
      _memoryAccessToken ?? await _storage.read(key: _accessTokenKey);

  // LOCAL-provider file URLs (files.model.ts) are API-relative (e.g.
  // "/uploads/...") — served by citycalls-api itself, not a CDN, so they need
  // this origin prefixed. CLOUDINARY urls are already absolute. Mirrors
  // citycalls-admin-web's useFiles.ts resolveFileUrl().
  @override
  String get apiOrigin => dio.options.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  // Same rule as resolveMediaUrl() in catalog_repository.dart, but for bare
  // URL strings that don't arrive wrapped in a File document — ServiceVisit's
  // beforeImages/afterImages are plain string arrays, not File refs.
  @override
  String resolveUrl(String url) => url.startsWith('http') ? url : '$apiOrigin$url';

  // Lets a SecondaryApiClient renew the shared session after a 401.
  Future<bool> refreshSession() => _refreshAccessToken();
}

// A second server that reuses [ApiClient]'s login: requests carry the same
// access token, and a 401 renews the session through the primary server once
// and retries. It never ends the session itself — if the other server still
// says 401, that request just fails and the user stays logged in.
class SecondaryApiClient implements ApiTarget {
  static const String _retriedFlag = 'citycalls_secondary_retried';

  @override
  final Dio dio;
  final ApiClient _session;

  SecondaryApiClient({required String baseUrl, required ApiClient session})
      : _session = session,
        dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _session.readAccessToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 ||
            error.requestOptions.extra[_retriedFlag] == true) {
          return handler.next(error);
        }
        if (!await _session.refreshSession()) return handler.next(error);
        final options = error.requestOptions;
        options.headers['Authorization'] = 'Bearer ${await _session.readAccessToken()}';
        options.extra[_retriedFlag] = true;
        try {
          handler.resolve(await dio.fetch(options));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ));
  }

  @override
  String get apiOrigin => dio.options.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');

  @override
  String resolveUrl(String url) => url.startsWith('http') ? url : '$apiOrigin$url';
}
