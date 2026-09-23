import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citycalls_customer/screens/otp_request_screen.dart';
import 'package:citycalls_customer/theme/app_theme.dart';

// Pumps the mobile-number entry screen directly rather than through
// CityCallsCustomerApp/SplashScreen — the splash makes a real network call
// (GET /customers/me) and its spinner runs an indeterminate animation, which
// leaves pumpAndSettle waiting on scheduled frames forever in a widget test.
Widget _wrapped(Widget child) => ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );

// The default 800x600 test viewport is wider than it is tall, which pushes
// this screen's submit button outside the hit-testable area and makes taps
// silently miss. A phone-shaped surface matches what the layout was built for.
void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Shows the mobile-number entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapped(const OtpRequestScreen()));

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Enter mobile number'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
  });

  testWidgets('Shows a validation error for an invalid mobile number', (WidgetTester tester) async {
    _usePhoneSurface(tester);
    await tester.pumpWidget(_wrapped(const OtpRequestScreen()));
    // AuthBackground animates the card in over 1s. Tapping mid-animation
    // misses the button, and pumpAndSettle can't be used here because that
    // widget also runs a looping background controller.
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Enter valid 10-digit number'), findsOneWidget);
  });

  // Guards the session-expired path added alongside refresh-token handling —
  // main.dart routes here with this flag when a refresh fails, and the user
  // needs to be told why they're suddenly back at login.
  testWidgets('Explains itself when the session expired', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapped(const OtpRequestScreen(sessionExpired: true)));
    await tester.pump();

    expect(find.text('Your session expired. Please sign in again.'), findsOneWidget);
  });
}
