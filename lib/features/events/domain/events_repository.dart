import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';

/// The events and holidays the person is told about (API design 10.26). Methods throw [ApiFailure]. A parent names the
/// child, and reads what the child's Institution and Society tell students and parents.
abstract class EventsRepository {
  /// EVT-01: the events with a day between [from] and [to] (at most 366 days), earliest first; only holidays with
  /// [holidaysOnly].
  Future<List<SchoolEvent>> events({
    required DateTime from,
    required DateTime to,
    bool holidaysOnly = false,
    String? studentId,
  });

  /// EVT-03: one event; 404 for one that is not the person's to read.
  Future<SchoolEvent> event(String id, {String? studentId});
}
