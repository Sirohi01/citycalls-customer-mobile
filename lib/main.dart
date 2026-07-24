import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

// Runs even if the app was fully terminated (not just backgrounded) — FCM
// invokes this in a separate isolate for that case, so it can't rely on any
// state from the running app and must be a top-level/static function.
@pragma('vm-entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No explicit FirebaseOptions/firebase_options.dart — on Android this reads
  // configuration from android/app/google-services.json (wired via the
  // google-services Gradle plugin) automatically; same for iOS once
  // GoogleService-Info.plist is added to the Xcode project.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(const ProviderScope(child: CityCallsCustomerApp()));
}

class CityCallsCustomerApp extends StatelessWidget {
  const CityCallsCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CityCalls',
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
