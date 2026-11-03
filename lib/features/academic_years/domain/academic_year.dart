import 'package:equatable/equatable.dart';

/// One academic year of an Institution (API design 10.4h). Dates are school days, `YYYY-MM-DD`.
class AcademicYear extends Equatable {
  const new({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.version,
  });

  final String id;
  final String institutionId;
  final String name;
  final String startDate;
  final String endDate;

  /// Exactly one active year of an Institution is current.
  final bool isCurrent;

  /// What a change must send back, so one made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;

  @override
  List<Object?> get props => [id, institutionId, name, startDate, endDate, isCurrent, version];
}
