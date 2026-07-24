import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_providers.dart';
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

class CityCallsCustomerApp extends ConsumerWidget {
  const CityCallsCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beautyMode = ref.watch(beautyModeProvider);
    return MaterialApp(
      title: 'CityCalls',
      theme: beautyMode ? AppTheme.beauty() : AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
