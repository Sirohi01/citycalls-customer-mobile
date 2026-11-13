import 'dart:async';
import 'package:citycalls_customer/data/api_client.dart';
import 'package:citycalls_customer/data/booking_repository.dart';
import 'package:citycalls_customer/models/booking_models.dart';
import 'package:citycalls_customer/providers/booking_providers.dart';
import 'package:citycalls_customer/screens/booking/booking_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Quotes extends BookingRepository {
  final Future<Map<String, dynamic>> Function(BookingDraft) load;
  _Quotes(this.load, ApiClient client) : super(client, catalogClient: client);
  @override
  Future<Map<String, dynamic>> quote(BookingDraft draft) => load(draft);
}

BookingDraft draft(String mode) => BookingDraft(
      serviceId: 'service',
      serviceName: 'Household service',
      pinCode: '110001',
      hasProductStep: false,
      pricingMode: mode,
      unitPrice: 200,
      address: AddressDraft(
          line1: 'Test address',
          city: 'Delhi',
          state: 'Delhi',
          pinCode: '110001'),
    );

void main() {
  Widget screen(BookingDraft d,
          Future<Map<String, dynamic>> Function(BookingDraft) load) =>
      ProviderScope(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(
              _Quotes(load, ApiClient(baseUrl: 'https://test.invalid')))
        ],
        child: MaterialApp(home: BookingReviewScreen(draft: d)),
      );

  testWidgets('cannot confirm while authoritative price is loading',
      (tester) async {
    final quote = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(screen(draft('FIXED'), (_) => quote.future));
    expect(
        tester
            .widget<FilledButton>(
                find.byWidgetPredicate((w) => w is FilledButton))
            .onPressed,
        isNull);
    quote.complete({'total': 399});
    await tester.pumpAndSettle();
    expect(find.text('₹399.00'), findsOneWidget);
    expect(find.text('Booked hours'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.byWidgetPredicate((w) => w is FilledButton))
            .onPressed,
        isNotNull);
  });

  testWidgets('hour changes fetch a new price before confirmation',
      (tester) async {
    final plans = <int>[];
    await tester.pumpWidget(screen(draft('HOURLY'), (d) async {
      plans.add(d.hours);
      return {'total': d.hours * 200};
    }));
    await tester.pumpAndSettle();
    expect(find.text('Booked hours'), findsOneWidget);
    final hours = tester
        .widget<DropdownButton<int>>(find.byType(DropdownButton<int>).first);
    hours.onChanged!(3);
    await tester.pumpAndSettle();
    expect(plans, [1, 3]);
    expect(find.text('₹600.00'), findsOneWidget);
  });

  testWidgets('failed quote leaves booking confirmation disabled',
      (tester) async {
    await tester.pumpWidget(
        screen(draft('FIXED'), (_) async => throw StateError('offline')));
    await tester.pumpAndSettle();
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(
                find.byWidgetPredicate((w) => w is FilledButton))
            .onPressed,
        isNull);
  });
}
