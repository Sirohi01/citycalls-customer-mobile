// Local models mirroring citycalls-api's contract, per docs/11-complete-api-contracts.md §1.1.
// Hand-written for now — regenerate from the synced OpenAPI spec once
// openapi/citycalls.yaml exists in this repo (see scripts/sync-contracts.sh).

class AuthUser {
  final String id;
  final String name;
  final String role;

  AuthUser({required this.id, required this.name, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  LoginResponse({required this.accessToken, required this.refreshToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

// Standard error envelope per docs/10-api-standards.md §4.
class ApiFieldError {
  final String field;
  final String code;
  final String message;

  ApiFieldError({required this.field, required this.code, required this.message});

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String,
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

// An active login on some device (citycalls-api's sessions.model.ts), from
// GET /auth/sessions. Only non-revoked, unexpired rows come back, and the
// refresh-token hash is stripped server-side.
class AuthSession {
  final String id;
  final String? device;
  final String? ipAddress;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  AuthSession({
    required this.id,
    this.device,
    this.ipAddress,
    this.createdAt,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      id: json['_id'] as String,
      device: json['device'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal(),
    );
  }
}
