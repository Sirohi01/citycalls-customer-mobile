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
// The fallback below is a LAN address for local development and changes with
// whatever network the dev machine is on — it is not a deployable default.
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.7:4000/api/v1',
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _apiBaseUrl);
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

  const AuthState({
    this.step = AuthStep.enterMobile,
    this.isLoading = false,
    this.errorMessage,
    this.mobile,
    this.user,
    this.signupName,
    this.signupEmail,
  });

  AuthState copyWith({
    AuthStep? step,
    bool? isLoading,
    String? errorMessage,
    String? mobile,
    AuthUser? user,
    String? signupName,
    String? signupEmail,
  }) {
    return AuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      mobile: mobile ?? this.mobile,
      user: user ?? this.user,
      signupName: signupName ?? this.signupName,
      signupEmail: signupEmail ?? this.signupEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  AuthNotifier(this._repository) : super(const AuthState());

  Future<void> requestOtp(String mobile,
      {String? signupName, String? signupEmail}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      mobile: mobile,
      signupName: signupName,
      signupEmail: signupEmail,
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
      final result = await _repository.verifyOtp(mobile, otp);
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
