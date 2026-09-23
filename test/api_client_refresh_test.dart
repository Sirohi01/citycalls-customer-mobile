import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citycalls_customer/data/api_client.dart';

// Exercises api_client.dart's 401 -> refresh -> retry interceptor against a
// stubbed transport, because that path is the one thing in the app that can
// silently sign a working user out and it never runs in a normal widget test.

/// Replaces Dio's transport. Every request is answered from [handler], and
/// each one is recorded so a test can assert on what was actually sent.
class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  _StubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) => ResponseBody.fromString(
      _encode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

String _encode(Map<String, dynamic> body) {
  final buffer = StringBuffer('{');
  var first = true;
  body.forEach((key, value) {
    if (!first) buffer.write(',');
    first = false;
    buffer.write('"$key":');
    if (value is Map<String, dynamic>) {
      buffer.write(_encode(value));
    } else if (value is String) {
      buffer.write('"$value"');
    } else {
      buffer.write('$value');
    }
  });
  buffer.write('}');
  return buffer.toString();
}

/// flutter_secure_storage talks over a platform channel that doesn't exist in
/// a test VM, so stand in for it with a plain in-memory map.
Map<String, String> _installFakeSecureStorage() {
  final store = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'write':
        store[call.arguments['key'] as String] = call.arguments['value'] as String;
        return null;
      case 'read':
        return store[call.arguments['key'] as String];
      case 'delete':
        store.remove(call.arguments['key'] as String);
        return null;
      case 'readAll':
        return Map<String, String>.from(store);
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(call.arguments['key'] as String);
    }
    return null;
  });
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> store;

  setUp(() {
    store = _installFakeSecureStorage();
  });

  test('a 401 triggers one refresh and replays the original request', () async {
    final client = ApiClient(baseUrl: 'http://test.local/api/v1');
    await client.saveTokens(accessToken: 'stale', refreshToken: 'good-refresh');

    var protectedCalls = 0;
    final adapter = _StubAdapter((options) {
      if (options.path.endsWith('/auth/refresh')) {
        return _json({
          'data': {'accessToken': 'fresh', 'refreshToken': 'rotated'}
        }, 200);
      }
      protectedCalls++;
      // Only the first attempt, carrying the stale token, is rejected.
      if (options.headers['Authorization'] == 'Bearer stale') {
        return _json({'message': 'Unauthorized'}, 401);
      }
      return _json({
        'data': {'ok': 'true'}
      }, 200);
    });
    client.dio.httpClientAdapter = adapter;

    final response = await client.dio.get('/customers/me');

    expect(response.statusCode, 200);
    expect(protectedCalls, 2, reason: 'original request should be replayed once');
    // The rotated pair must be persisted, or the next refresh reuses a token
    // the backend has already revoked.
    expect(store['citycalls_access_token'], 'fresh');
    expect(store['citycalls_refresh_token'], 'rotated');
    expect(client.sessionExpired.value, isFalse);
  });

  test('a failed refresh clears tokens and flags the session as expired', () async {
    final client = ApiClient(baseUrl: 'http://test.local/api/v1');
    await client.saveTokens(accessToken: 'stale', refreshToken: 'revoked');

    client.dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path.endsWith('/auth/refresh')) {
        return _json({'message': 'Session no longer valid'}, 401);
      }
      return _json({'message': 'Unauthorized'}, 401);
    });

    await expectLater(client.dio.get('/customers/me'), throwsA(isA<DioException>()));

    expect(store['citycalls_access_token'], isNull);
    expect(store['citycalls_refresh_token'], isNull);
    expect(client.sessionExpired.value, isTrue);
  });

  test('a request that 401s again after refreshing does not refresh twice', () async {
    final client = ApiClient(baseUrl: 'http://test.local/api/v1');
    await client.saveTokens(accessToken: 'stale', refreshToken: 'good-refresh');

    var refreshCalls = 0;
    final adapter = _StubAdapter((options) {
      if (options.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        return _json({
          'data': {'accessToken': 'fresh', 'refreshToken': 'rotated'}
        }, 200);
      }
      // Never satisfied — without the retry guard this loops.
      return _json({'message': 'Unauthorized'}, 401);
    });
    client.dio.httpClientAdapter = adapter;

    await expectLater(client.dio.get('/customers/me'), throwsA(isA<DioException>()));

    expect(refreshCalls, 1);
  });

  test('concurrent 401s share a single refresh', () async {
    final client = ApiClient(baseUrl: 'http://test.local/api/v1');
    await client.saveTokens(accessToken: 'stale', refreshToken: 'good-refresh');

    var refreshCalls = 0;
    client.dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        return _json({
          'data': {'accessToken': 'fresh', 'refreshToken': 'rotated'}
        }, 200);
      }
      if (options.headers['Authorization'] == 'Bearer stale') {
        return _json({'message': 'Unauthorized'}, 401);
      }
      return _json({
        'data': {'ok': 'true'}
      }, 200);
    });

    // Mirrors a screen whose providers all refetch at once — the backend
    // rotates the refresh token on every call, so a second concurrent refresh
    // would revoke a session that was about to work.
    final responses = await Future.wait([
      client.dio.get('/customers/me'),
      client.dio.get('/service-requests'),
      client.dio.get('/notifications/unread-count'),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
  });

  test('a 401 from the login route is surfaced, not refreshed', () async {
    final client = ApiClient(baseUrl: 'http://test.local/api/v1');

    var refreshCalls = 0;
    client.dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path.endsWith('/auth/refresh')) refreshCalls++;
      return _json({'message': 'Incorrect or expired OTP.'}, 401);
    });

    await expectLater(
      client.dio.post('/auth/otp/verify', data: {'mobile': '9999999999', 'otp': '000000'}),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 0);
    expect(client.sessionExpired.value, isFalse);
  });
}
