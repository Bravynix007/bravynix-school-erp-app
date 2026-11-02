import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';

/// A due of Sri Vidya High School for the last quarter of 2026, raised at ₹50.00 a student.
PlatformDueLine dueLine({
  String id = 'd1',
  String invoiceNo = 'BNX/FY2026-27/0007',
  String institutionName = 'Sri Vidya High School',
  String totalAmount = '80000.00',
  DueStatus status = DueStatus.due,
  String? dueDate = '2026-11-15',
  String? paidDate,
  PaymentMode? paymentMode,
  String? paymentReference,
}) => PlatformDueLine(
  id: id,
  invoiceNo: invoiceNo,
  institutionName: institutionName,
  periodStartDate: '2026-10-01',
  periodEndDate: '2026-12-31',
  totalAmount: totalAmount,
  status: status,
  dueDate: dueDate,
  paidDate: paidDate,
  paymentMode: paymentMode,
  paymentReference: paymentReference,
);

/// 1,650 students at ₹50.00 less a ₹2,500.00 rebate.
PlatformDue due({
  DueStatus status = DueStatus.due,
  String? dueDate = '2026-11-15',
  String? paidDate,
  PaymentMode? paymentMode,
  String? paymentReference,
  String adjustmentAmount = '-2500.00',
  String? adjustmentNote = 'Festive discount',
}) => PlatformDue(
  id: 'd1',
  invoiceNo: 'BNX/FY2026-27/0007',
  institutionName: 'Sri Vidya High School',
  periodStartDate: '2026-10-01',
  periodEndDate: '2026-12-31',
  totalAmount: '80000.00',
  status: status,
  dueDate: dueDate,
  paidDate: paidDate,
  paymentMode: paymentMode,
  paymentReference: paymentReference,
  studentCount: 1650,
  ratePerStudentAmount: '50.00',
  baseAmount: '82500.00',
  adjustmentAmount: adjustmentAmount,
  adjustmentNote: adjustmentNote,
);

/// The JSON of BIL-01's line for [dueLine].
Map<String, Object?> dueLineJson({int status = 1, Object? paymentMode, String? paidDate}) => {
  'id': 'd1',
  'invoiceNo': 'BNX/FY2026-27/0007',
  'institution': {'id': 'i1', 'name': 'Sri Vidya High School'},
  'periodStartDate': '2026-10-01',
  'periodEndDate': '2026-12-31',
  'totalAmount': '80000.00',
  'dueStatus': status,
  'dueDate': '2026-11-15',
  'paidDate': paidDate,
  'paymentMode': paymentMode,
  'paymentReference': null,
  'invoiceFile': null,
};
