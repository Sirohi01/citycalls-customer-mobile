import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:citycalls_customer/main.dart';

void main() {
  testWidgets('App boots to the login screen with required fields', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CityCallsCustomerApp()));

    expect(find.text('CityCalls'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Mobile number or email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('Shows validation errors when submitting an empty form', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CityCallsCustomerApp()));

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid mobile or email'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
