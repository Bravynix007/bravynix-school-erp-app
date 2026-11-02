import 'package:equatable/equatable.dart';

/// Where a due stands (PRD 11.4): 0 Cancelled, 1 Due, 2 Paid.
enum DueStatus {
  cancelled(0),
  due(1),
  paid(2);

  new(this.code);

  final int code;

  static DueStatus? fromCode(Object? code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }
}

/// How a due was paid (PRD 11.4): 1 Cash, 2 Bank transfer, 3 UPI, 4 Cheque.
enum PaymentMode {
  cash(1),
  bankTransfer(2),
  upi(3),
  cheque(4);

  new(this.code);

  final int code;

  static PaymentMode? fromCode(Object? code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}

/// One line of the Owner's list (BIL-01): what BravyNix charged one Institution for one period.
class PlatformDueLine extends Equatable {
  const new({
    required this.id,
    required this.invoiceNo,
    required this.institutionName,
    required this.periodStartDate,
    required this.periodEndDate,
    required this.totalAmount,
    required this.status,
    this.dueDate,
    this.paidDate,
    this.paymentMode,
    this.paymentReference,
  });

  final String id;
  final String invoiceNo;
  final String institutionName;

  /// School days, `2026-10-01`.
  final String periodStartDate;
  final String periodEndDate;

  /// An exact decimal string (API design 7.3), never a number.
  final String totalAmount;
  final DueStatus status;
  final String? dueDate;
  final String? paidDate;
  final PaymentMode? paymentMode;
  final String? paymentReference;

  /// Still Due after its due date. A due with no due date is never past it; [today] is a school day in IST.
  bool isOverdue(String today) => status == DueStatus.due && dueDate != null && dueDate!.compareTo(today) < 0;

  @override
  List<Object?> get props => [
    id,
    invoiceNo,
    institutionName,
    periodStartDate,
    periodEndDate,
    totalAmount,
    status,
    dueDate,
    paidDate,
    paymentMode,
    paymentReference,
  ];
}

/// One due as its Owner reads it (BIL-02): the line, and how the total was reached.
class PlatformDue extends PlatformDueLine {
  const new({
    required super.id,
    required super.invoiceNo,
    required super.institutionName,
    required super.periodStartDate,
    required super.periodEndDate,
    required super.totalAmount,
    required super.status,
    required this.studentCount,
    required this.ratePerStudentAmount,
    required this.baseAmount,
    required this.adjustmentAmount,
    super.dueDate,
    super.paidDate,
    super.paymentMode,
    super.paymentReference,
    this.adjustmentNote,
  });

  final int studentCount;
  final String ratePerStudentAmount;
  final String baseAmount;

  /// Signed: a deduction is negative.
  final String adjustmentAmount;

  /// Why BravyNix adjusted the total; written for the Owners to read.
  final String? adjustmentNote;

  @override
  List<Object?> get props => [
    ...super.props,
    studentCount,
    ratePerStudentAmount,
    baseAmount,
    adjustmentAmount,
    adjustmentNote,
  ];
}

/// BIL-01: "You are due ₹X" or "All dues are paid", and the dues, newest first.
class PlatformDues extends Equatable {
  const new({required this.totalDueAmount, required this.hasOpenDues, required this.dues});

  final String totalDueAmount;

  /// True only while [totalDueAmount] is above zero: a due of 0.00 is listed but owes nothing.
  final bool hasOpenDues;
  final List<PlatformDueLine> dues;

  @override
  List<Object?> get props => [totalDueAmount, hasOpenDues, dues];
}
