import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';

/// JSON → domain for BIL-01 and BIL-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class PlatformDueModels {
  static Map<String, dynamic> _object(Object? json) =>
      json is Map<String, dynamic> ? json : throw const FormatException('Expected a JSON object');

  static DueStatus _status(Map<String, dynamic> json) =>
      DueStatus.fromCode(json['dueStatus']) ?? (throw FormatException('Unknown due status ${json['dueStatus']}'));

  static PlatformDueLine line(Object? raw) {
    final json = _object(raw);
    return PlatformDueLine(
      id: json['id'] as String,
      invoiceNo: json['invoiceNo'] as String,
      institutionName: _object(json['institution'])['name'] as String,
      periodStartDate: json['periodStartDate'] as String,
      periodEndDate: json['periodEndDate'] as String,
      totalAmount: json['totalAmount'] as String,
      status: _status(json),
      dueDate: json['dueDate'] as String?,
      paidDate: json['paidDate'] as String?,
      paymentMode: PaymentMode.fromCode(json['paymentMode']),
      paymentReference: json['paymentReference'] as String?,
    );
  }

  static PlatformDue due(Object? raw) {
    final json = _object(raw);
    final base = line(json);
    return PlatformDue(
      id: base.id,
      invoiceNo: base.invoiceNo,
      institutionName: base.institutionName,
      periodStartDate: base.periodStartDate,
      periodEndDate: base.periodEndDate,
      totalAmount: base.totalAmount,
      status: base.status,
      dueDate: base.dueDate,
      paidDate: base.paidDate,
      paymentMode: base.paymentMode,
      paymentReference: base.paymentReference,
      studentCount: (json['studentCount'] as num).toInt(),
      ratePerStudentAmount: json['ratePerStudentAmount'] as String,
      baseAmount: json['baseAmount'] as String,
      adjustmentAmount: json['adjustmentAmount'] as String,
      adjustmentNote: json['adjustmentNote'] as String?,
    );
  }

  static PlatformDues dues(Object? raw) {
    final json = _object(raw);
    final banner = _object(json['banner']);
    final dues = json['dues'];
    if (dues is! List<dynamic>) throw const FormatException('Expected a JSON array');
    return PlatformDues(
      totalDueAmount: banner['totalDueAmount'] as String,
      hasOpenDues: banner['hasOpenDues'] as bool,
      dues: [for (final item in dues) line(item)],
    );
  }
}
