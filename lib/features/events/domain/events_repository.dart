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

  /// EVT-02: an Owner creates for the Society ([EventScope.society]) or for one Institution, an Admin only for an
  /// Institution they administer (403 SCOPE_NOT_ALLOWED otherwise). 400 for a field that is wrong, 404 for an
  /// Institution out of reach.
  Future<SchoolEvent> create(EventInput input, {required EventScope scope, String? institutionId});

  /// EVT-04: sends every field of [input] with the version that was read. 409 VERSION_CONFLICT when it changed
  /// meanwhile, 403 SCOPE_NOT_ALLOWED for an Admin and a Society event, 404 for one removed.
  Future<SchoolEvent> change(SchoolEvent event, EventInput input);

  /// EVT-06 (an Owner only): moves the event to the whole Society ([EventScope.society]) or to one Institution the Owner
  /// reaches, with the version that was read. 409 VERSION_CONFLICT when it changed meanwhile, 404 for an event that is
  /// gone or an Institution out of reach, 400 for an Institution that does not fit the scope.
  Future<SchoolEvent> changeScope(SchoolEvent event, {required EventScope scope, String? institutionId});

  /// EVT-05: removes the event from every list; nothing is deleted. 404 when it is already removed.
  Future<void> remove(String id);
}
