import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';

/// The class timetable of an Institution's current year (TT-01). Methods throw [ApiFailure].
abstract class TimetableRepository {
  /// TT-01: the entries of [week], by day and period. 422 CURRENT_YEAR_REQUIRED when the Institution has no current
  /// year, 403 NOT_ASSIGNED for a teacher and a section they neither lead nor teach, 404 for a section out of reach and
  /// for a child that is not the parent's, 403 CHILD_ACCESS_BLOCKED or 423 SECTION_BLOCKED for a blocked child.
  Future<List<TimetableEntry>> week(TimetableWeek week);
}
