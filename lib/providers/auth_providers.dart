import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/customer_repository.dart';
import '../models/auth_models.dart';

// The one place the API base URL is configured (ApiClient deliberately has no
// default of its own). Override per build without editing this file:
//
//   flutter run --dart-define=API_BASE_URL=http://<host>:4000/api/v1
//
// (scripts/run-local.sh does that with this Mac's current Wi-Fi IP.)
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // Live server: login, WhatsApp OTP, bookings and profile all go here, so
  // the app works on any network with no Mac IP to keep updating. For local
  // API testing run ./scripts/run-local.sh instead.
  defaultValue: 'https://api.citycalls.in/api/v1',
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _apiBaseUrl);
});

// Categories, services (and their photos/diagnostics) and the Home / Salon /
// HelpNow top banners are read from the live server while everything else
// uses [_apiBaseUrl], using the same login.
const String _catalogApiBaseUrl = String.fromEnvironment(
  'CATALOG_API_BASE_URL',
  defaultValue: 'https://api.citycalls.in/api/v1',
);

final catalogApiClientProvider = Provider<SecondaryApiClient>((ref) {
  return SecondaryApiClient(
    baseUrl: _catalogApiBaseUrl,
    session: ref.watch(apiClientProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(apiClientProvider));
});

final activeSessionsProvider = FutureProvider<List<AuthSession>>((ref) async {
  return ref.watch(authRepositoryProvider).listSessions();
});

enum AuthStep { enterMobile, otpSent, loggedIn }

class AuthState {
  final AuthStep step;
  final bool isLoading;
  final String? errorMessage;
  final String? mobile;
  final AuthUser? user;
  final String? signupName;
  final String? signupEmail;
  // From the login screen's "Remember me"; signup flows keep the default.
  final bool rememberMe;

  const AuthState({
    this.step = AuthStep.enterMobile,
    this.isLoading = false,
    this.errorMessage,
    this.mobile,
    this.user,
    this.signupName,
    this.signupEmail,
    this.rememberMe = true,
  });

  AuthState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? errorMessage,
    String? mobile,
    AuthUser? user,
    String? signupName,
    String? signupEmail,
    bool? rememberMe,
  }) {
    return AuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      mobile: mobile ?? this.mobile,
      user: user ?? this.user,
      signupName: signupName ?? this.signupName,
      signupEmail: signupEmail ?? this.signupEmail,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> requestOtp(String mobile,
      {String? signupName, String? signupEmail, bool rememberMe = true}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      mobile: mobile,
      signupName: signupName,
      signupEmail: signupEmail,
      rememberMe: rememberMe,
    );
    try {
      await _repository.requestOtp(mobile);
      state = state.copyWith(isLoading: false, step: AuthStep.otpSent);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: "Failed to connect to backend server");
    }
  }

  Future<void> verifyOtp(String otp) async {
    final mobile = state.mobile;
    if (mobile == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.verifyOtp(mobile, otp,
          rememberMe: state.rememberMe);
      state = state.copyWith(
          isLoading: false, step: AuthStep.loggedIn, user: result.user);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: "Failed to connect to backend server");
    }
  }

  void backToMobileEntry() {
    state = state.copyWith(step: AuthStep.enterMobile, errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
