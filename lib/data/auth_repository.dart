import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/auth_models.dart';

class AuthException implements Exception {
  final String message;
  final List<ApiFieldError> errors;
  AuthException(this.message, this.errors);
}

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
class AuthRepository {
  final ApiClient _client;
  AuthRepository(this._client);

  Future<LoginResponse> login(String identifier, String password) async {
    try {
      final res = await _client.dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      final loginResponse = LoginResponse.fromJson(res.data['data'] as Map<String, dynamic>);
      await _client.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
      return loginResponse;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic> && body['errors'] != null) {
        final errors = (body['errors'] as List)
            .map((e) => ApiFieldError.fromJson(e as Map<String, dynamic>))
            .toList();
        throw AuthException(body['message'] as String? ?? 'Login failed', errors);
      }
      throw AuthException('Unable to reach the server. Please check your connection.', []);
    }
  }

  // Revokes the Session document server-side before dropping the local copy.
  // Clearing only the local token (the previous behaviour) left the refresh
  // token valid on the backend until it naturally expired, so a leaked token
  // stayed usable after the user had "logged out".
  Future<void> logout() async {
    final refreshToken = await _client.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } on DioException {
        // Best-effort — a network failure here must not block the user from
        // logging out locally, which is the part they actually see.
      }
    }
    await _client.clearTokens();
  }

  // Every device currently signed in to this account. Self-scoped
  // (auth.routes.ts gates these on authMiddleware alone), so a CUSTOMER role
  // can read and revoke its own sessions.
  Future<List<AuthSession>> listSessions() async {
    final res = await _client.dio.get('/auth/sessions');
    return (res.data['data'] as List)
        .map((s) => AuthSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeSession(String sessionId) async {
    await _client.dio.delete('/auth/sessions/$sessionId');
  }

  // Signs out everywhere, including this device — the caller is responsible
  // for clearing local tokens and returning to login afterwards.
  Future<void> revokeAllSessions() async {
    await _client.dio.post('/auth/sessions/revoke-all');
  }

  Future<void> requestOtp(String mobile) async {
    try {
      await _client.dio.post('/auth/otp/request', data: {'mobile': mobile});
    } on DioException catch (e) {
      throw _toAuthException(e, 'Failed to send OTP. Please try again.');
    }
  }

  Future<LoginResponse> verifyOtp(String mobile, String otp) async {
    try {
      final res = await _client.dio.post('/auth/otp/verify', data: {'mobile': mobile, 'otp': otp});
      final loginResponse = LoginResponse.fromJson(res.data['data'] as Map<String, dynamic>);
      await _client.saveTokens(
        accessToken: loginResponse.accessToken,
        refreshToken: loginResponse.refreshToken,
      );
      return loginResponse;
    } on DioException catch (e) {
      throw _toAuthException(e, 'Incorrect or expired OTP.');
    }
  }

  AuthException _toAuthException(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['errors'] != null) {
      final errors = (body['errors'] as List)
          .map((e) => ApiFieldError.fromJson(e as Map<String, dynamic>))
          .toList();
      return AuthException(body['message'] as String? ?? fallback, errors);
    }
    if (body is Map<String, dynamic> && body['message'] != null) {
      return AuthException(body['message'] as String, []);
    }
    return AuthException('Unable to reach the server. Please check your connection.', []);
  }
}
