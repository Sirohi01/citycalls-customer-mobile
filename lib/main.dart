import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_navigator.dart';
import 'data/api_client.dart';
import 'data/session_actions.dart';
import 'providers/auth_providers.dart';
import 'providers/realtime_providers.dart';
import 'providers/theme_providers.dart';
import 'screens/otp_request_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

@pragma('vm-entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const ProviderScope(child: CityCallsCustomerApp()));
}

class CityCallsCustomerApp extends ConsumerStatefulWidget {
  const CityCallsCustomerApp({super.key});

  @override
  ConsumerState<CityCallsCustomerApp> createState() =>
      _CityCallsCustomerAppState();
}

class _CityCallsCustomerAppState extends ConsumerState<CityCallsCustomerApp> {
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ref.read(apiClientProvider);
    _apiClient.sessionExpired.addListener(_onSessionExpired);
  }

  @override
  void dispose() {
    _apiClient.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    if (!_apiClient.sessionExpired.value) return;
    _apiClient.sessionExpired.value = false;
    if (SplashScreen.bootstrapping) return;
    final navigator = appNavigator;
    if (navigator == null) return;
    // The tokens are already gone, so only the local side needs tearing down:
    // the next login must not see the expired account's cached data, and a
    // socket still holding its JWT would keep running.
    ref.read(socketServiceProvider).disconnect();
    resetSessionState(ProviderScope.containerOf(context));
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => const OtpRequestScreen(sessionExpired: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final beautyMode = ref.watch(beautyModeProvider);
    return MaterialApp(
      title: 'CityCalls',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: beautyMode ? AppTheme.beauty() : AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
