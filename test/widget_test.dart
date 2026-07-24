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

void main() {
  testWidgets('Shows the mobile-number entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapped(const OtpRequestScreen()));

    expect(find.text('Get things fixed, fast'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Mobile number'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send OTP'), findsOneWidget);
  });

  testWidgets('Shows a validation error for an invalid mobile number', (WidgetTester tester) async {
    await tester.pumpWidget(_wrapped(const OtpRequestScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });
}
