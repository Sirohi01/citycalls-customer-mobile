import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citycalls_customer/main.dart';

void main() {
  testWidgets('App boots to the mobile-number entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CityCallsCustomerApp()));

    expect(find.text('CityCalls'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Mobile number'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send OTP'), findsOneWidget);
  });

  testWidgets('Shows a validation error for an invalid mobile number', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CityCallsCustomerApp()));

    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pump();

    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });
}
