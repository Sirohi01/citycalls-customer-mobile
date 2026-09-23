import 'package:flutter_test/flutter_test.dart';

import 'package:citycalls_customer/models/finance_models.dart';
import 'package:citycalls_customer/models/geo_models.dart';
import 'package:citycalls_customer/models/reopen_models.dart';
import 'package:citycalls_customer/models/visit_models.dart';

// Payloads below mirror citycalls-api's Mongoose documents field-for-field
// (serviceVisits.model.ts, reopenRecords.model.ts, geo.service.ts's
// AreaCheckResult, creditDebitNotes.model.ts). Nothing in the app verifies
// these shapes at compile time — the repos hand-roll fromJson — so a silent
// rename on the backend would otherwise only show up as a crash on a user's
// phone.

void main() {
  group('ServiceVisit', () {
    test('parses a completed visit with parts and photos', () {
      final visit = ServiceVisit.fromJson({
        '_id': '66f0000000000000000000a1',
        'serviceRequestId': '66f0000000000000000000b1',
        'visitNumber': 2,
        'technicianId': '66f0000000000000000000c1',
        'startedAt': '2026-09-20T04:30:00.000Z',
        'arrivedAt': '2026-09-20T05:10:00.000Z',
        'inspection': {
          'defectFound': 'Compressor failure',
          'symptoms': ['Not cooling', 'Loud noise'],
          'solutionType': 'REPLACEMENT',
        },
        'parts': [
          {'name': 'Compressor', 'qty': 1, 'unitPrice': 4500},
          {'name': 'Gas refill', 'qty': 2, 'unitPrice': 300},
        ],
        'labourCharge': 500,
        'beforeImages': ['/uploads/before-1.jpg'],
        'afterImages': ['https://res.cloudinary.com/x/after-1.jpg'],
        'workNotes': 'Replaced compressor and topped up refrigerant.',
        'completedAt': '2026-09-20T07:00:00.000Z',
        'completionProof': {'type': 'OTP', 'value': 'hashed-otp-never-shown'},
        'createdAt': '2026-09-20T04:30:00.000Z',
        'updatedAt': '2026-09-20T07:00:00.000Z',
      });

      expect(visit.visitNumber, 2);
      expect(visit.isCompleted, isTrue);
      expect(visit.hasDetails, isTrue);
      expect(visit.inspection.defectFound, 'Compressor failure');
      expect(visit.inspection.symptoms, ['Not cooling', 'Loud noise']);
      expect(visit.parts, hasLength(2));
      expect(visit.parts.first.lineTotal, 4500);
      expect(visit.partsTotal, 5100);
      expect(visit.labourCharge, 500);
      expect(visit.completionProofType, 'OTP');
      // The OTP is stored hashed server-side; the model must not expose it.
      expect(visit.completionProofUrl, isNull);
    });

    test('parses a just-checked-in visit with nothing recorded yet', () {
      final visit = ServiceVisit.fromJson({
        '_id': '66f0000000000000000000a2',
        'visitNumber': 1,
        'inspection': {'symptoms': []},
        'parts': [],
        'beforeImages': [],
        'afterImages': [],
      });

      expect(visit.isCompleted, isFalse);
      expect(visit.hasDetails, isFalse, reason: 'drives the "in progress" copy');
      expect(visit.inspection.isEmpty, isTrue);
      expect(visit.partsTotal, 0);
    });

    test('survives a visit document with the optional blocks absent', () {
      final visit = ServiceVisit.fromJson({'_id': '66f0000000000000000000a3'});

      expect(visit.visitNumber, 1);
      expect(visit.parts, isEmpty);
      expect(visit.inspection.symptoms, isEmpty);
      expect(visit.completionProofType, isNull);
    });
  });

  group('ReopenRecord', () {
    test('parses a pending customer-raised reopen', () {
      final record = ReopenRecord.fromJson({
        '_id': '66f0000000000000000000d1',
        'reason': 'Cooling problem returned after two days',
        'status': 'PENDING',
        'reopenCount': 1,
        'withinPolicyWindow': true,
        'warrantyApplied': false,
        'reopenedAt': '2026-09-21T06:00:00.000Z',
        'reopenedBy': {'_id': '66f0000000000000000000e1', 'name': 'Asha Verma'},
      });

      expect(record.status, 'PENDING');
      expect(reopenStatusLabel(record.status), 'Awaiting review');
      expect(record.reopenedByName, 'Asha Verma');
      expect(record.newServiceRequestId, isNull);
      expect(record.reopenedAt, isNotNull);
    });

    test('parses a rejected reopen with its reason', () {
      final record = ReopenRecord.fromJson({
        '_id': '66f0000000000000000000d2',
        'reason': 'Same issue',
        'status': 'REJECTED',
        'reopenCount': 2,
        'withinPolicyWindow': false,
        'warrantyApplied': false,
        'rejectionReason': 'Outside the 30-day warranty window',
        'reviewedAt': '2026-09-22T06:00:00.000Z',
      });

      expect(reopenStatusLabel(record.status), 'Rejected');
      expect(record.rejectionReason, 'Outside the 30-day warranty window');
      expect(record.withinPolicyWindow, isFalse);
    });

    test('reads newServiceRequestId whether populated or a raw id', () {
      final populated = ReopenRecord.fromJson({
        '_id': 'x',
        'reason': 'r',
        'status': 'APPROVED',
        'reopenCount': 1,
        'withinPolicyWindow': true,
        'newServiceRequestId': {'_id': '66f0000000000000000000f1', 'number': 'SR-1'},
      });
      final raw = ReopenRecord.fromJson({
        '_id': 'y',
        'reason': 'r',
        'status': 'APPROVED',
        'reopenCount': 1,
        'withinPolicyWindow': true,
        'newServiceRequestId': '66f0000000000000000000f1',
      });

      expect(populated.newServiceRequestId, '66f0000000000000000000f1');
      expect(raw.newServiceRequestId, '66f0000000000000000000f1');
    });
  });

  group('PincodeArea', () {
    test('uses city when the backend resolves one', () {
      final area = PincodeArea.fromJson({
        'serviceable': true,
        'branchId': '66f00000000000000000000a',
        'branchName': 'Ghaziabad',
        'city': 'Ghaziabad',
        'state': 'Uttar Pradesh',
        'country': 'India',
      });

      expect(area.serviceable, isTrue);
      expect(area.resolvedCity, 'Ghaziabad');
      expect(area.state, 'Uttar Pradesh');
    });

    test('falls back to district, which is what the branch lookup actually returns', () {
      // geo.service.ts's branch-match branch sets state + branchName but
      // leaves city unset — without the district fallback the City field
      // would simply stay blank after a successful lookup.
      final area = PincodeArea.fromJson({
        'serviceable': true,
        'branchName': 'Delhi Central',
        'state': 'Delhi',
        'district': 'New Delhi',
        'country': 'India',
      });

      expect(area.city, isNull);
      expect(area.resolvedCity, 'New Delhi');
    });

    test('handles an uncovered PIN', () {
      final area = PincodeArea.fromJson({'serviceable': false});
      expect(area.serviceable, isFalse);
      expect(area.resolvedCity, isNull);
    });
  });

  group('InvoiceNote', () {
    test('keeps credit and debit directions distinct', () {
      final credit = InvoiceNote.fromJson({
        '_id': '66f00000000000000000001a',
        'number': 'CN-DELCS-2627-000001',
        'amount': 250,
        'reason': 'Part returned unused',
        'createdAt': '2026-09-21T06:00:00.000Z',
      }, isCredit: true);

      final debit = InvoiceNote.fromJson({
        '_id': '66f00000000000000000001b',
        'number': 'DN-DELCS-2627-000001',
        'amount': 150,
        'reason': 'Additional gas refill',
      }, isCredit: false);

      expect(credit.isCredit, isTrue);
      expect(credit.amount, 250);
      expect(debit.isCredit, isFalse);
      expect(debit.createdAt, isNull);
    });
  });
}
