import 'package:citycalls_customer/data/permission_queue.dart';
import 'package:citycalls_customer/models/booking_models.dart';
import 'package:citycalls_customer/providers/location_providers.dart';
import 'package:flutter_test/flutter_test.dart';

BookingDraft _draft({bool hasProductStep = true}) => BookingDraft(
      serviceId: 's1',
      serviceName: 'AC Repair',
      pinCode: '110001',
      hasProductStep: hasProductStep,
    );

void main() {
  group('BookingDraft steps', () {
    test('Home Appliances keeps all 5 steps', () {
      final d = _draft();
      expect(d.totalSteps, 5);
      expect([2, 3, 4, 5].map(d.stepNumber), [2, 3, 4, 5]);
    });

    test('other categories skip the appliance step and renumber', () {
      final d = _draft(hasProductStep: false);
      expect(d.totalSteps, 4);
      expect([2, 3, 4, 5].map(d.stepNumber), [1, 2, 3, 4]);
    });

    test('copyWith keeps the skip flag and the address preference', () {
      final d = BookingDraft(
        serviceId: 's1',
        serviceName: 'Sofa Cleaning',
        pinCode: '110001',
        hasProductStep: false,
        preferredAddressId: 'a1',
        preferCurrentLocation: true,
      ).copyWith(symptoms: ['x']);
      expect(d.hasProductStep, isFalse);
      expect(d.preferredAddressId, 'a1');
      expect(d.preferCurrentLocation, isTrue);
    });
  });

  group('CurrentPlace', () {
    CurrentPlace place(String pin) => CurrentPlace(
          label: 'Rohini, Delhi',
          city: 'Delhi',
          state: 'Delhi',
          pinCode: pin,
          latitude: 28.7,
          longitude: 77.1,
        );

    test('only a 6-digit PIN can drive the availability check', () {
      expect(place('110085').hasPin, isTrue);
      expect(place('').hasPin, isFalse);
      expect(place('1100').hasPin, isFalse);
      expect(place('11008a').hasPin, isFalse);
    });
  });

  group('PermissionQueue', () {
    test('runs prompts one after another, even if one fails', () async {
      final log = <String>[];
      final first = PermissionQueue.run(() async {
        log.add('first start');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        log.add('first end');
        return 1;
      });
      final failing = PermissionQueue.run<int>(() async {
        log.add('failing');
        throw StateError('denied');
      });
      final third = PermissionQueue.run(() async {
        log.add('third');
        return 3;
      });

      expect(await first, 1);
      await expectLater(failing, throwsStateError);
      expect(await third, 3);
      expect(log, ['first start', 'first end', 'failing', 'third']);
    });
  });
}
