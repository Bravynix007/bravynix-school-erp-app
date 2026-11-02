import 'package:bravynix_school_erp/features/platform_dues/data/platform_due_models.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/platform_dues.dart';

void main() {
  test('reads the banner and every line of BIL-01', () {
    final dues = PlatformDueModels.dues({
      'banner': {'totalDueAmount': '80000.00', 'hasOpenDues': true},
      'dues': [
        dueLineJson(),
        {...dueLineJson(status: 2, paymentMode: 3, paidDate: '2026-11-01'), 'id': 'd2'},
      ],
    });
    expect(dues.totalDueAmount, '80000.00');
    expect(dues.hasOpenDues, isTrue);
    expect(dues.dues, hasLength(2));
    expect(dues.dues.first, dueLine());
    expect(dues.dues.last.status, DueStatus.paid);
    expect(dues.dues.last.paymentMode, PaymentMode.upi);
    expect(dues.dues.last.paidDate, '2026-11-01');
  });

  test('reads how the total was reached from BIL-02', () {
    final read = PlatformDueModels.due({
      ...dueLineJson(),
      'studentCount': 1650,
      'ratePerStudentAmount': '50.00',
      'baseAmount': '82500.00',
      'adjustmentAmount': '-2500.00',
      'adjustmentNote': 'Festive discount',
    });
    expect(read, due());
  });

  test('ignores fields it does not know, as /v1 only ever adds fields', () {
    final read = PlatformDueModels.line({...dueLineJson(), 'somethingNew': 1});
    expect(read, dueLine());
  });

  test('refuses a status or a body it does not know instead of showing a wrong due', () {
    expect(() => PlatformDueModels.line(dueLineJson(status: 7)), throwsFormatException);
    expect(() => PlatformDueModels.dues(<String, Object?>{'banner': {}, 'dues': 'x'}), throwsA(anything));
    expect(() => PlatformDueModels.dues('nope'), throwsFormatException);
  });

  test('a payment mode it does not know is left out, not guessed', () {
    expect(PlatformDueModels.line(dueLineJson(status: 2, paymentMode: 9)).paymentMode, isNull);
  });

  group('isOverdue', () {
    test('is true only for a Due past its date', () {
      expect(dueLine().isOverdue('2026-11-16'), isTrue);
      expect(dueLine().isOverdue('2026-11-15'), isFalse);
      expect(dueLine(dueDate: null).isOverdue('2030-01-01'), isFalse);
      expect(dueLine(status: DueStatus.paid).isOverdue('2030-01-01'), isFalse);
      expect(dueLine(status: DueStatus.cancelled).isOverdue('2030-01-01'), isFalse);
    });
  });
}
