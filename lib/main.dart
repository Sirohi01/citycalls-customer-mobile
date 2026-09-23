import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_navigator.dart';
import 'data/api_client.dart';
import 'providers/auth_providers.dart';
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
  ConsumerState<CityCallsCustomerApp> createState() => _CityCallsCustomerAppState();
}

class _CityCallsCustomerAppState extends ConsumerState<CityCallsCustomerApp> {
  // Held directly rather than re-read in dispose(): this is the root widget,
  // so its dispose runs while the ProviderScope is itself being torn down and
  // reading a provider there can throw.
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    // Refresh-token rotation failing (api_client.dart) means the session is
    // genuinely over. Before this existed, every screen simply kept showing
    // its error state and the user had no way to discover they needed to log
    // in again.
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
    final navigator = appNavigator;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OtpRequestScreen(sessionExpired: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final beautyMode = ref.watch(beautyModeProvider);
    return MaterialApp(
      title: 'CityCalls',
      navigatorKey: appNavigatorKey,
      theme: beautyMode ? AppTheme.beauty() : AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
