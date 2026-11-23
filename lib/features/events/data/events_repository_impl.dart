import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/events/data/event_models.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';

class EventsRepositoryImpl implements EventsRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<List<SchoolEvent>> events({
    required DateTime from,
    required DateTime to,
    bool holidaysOnly = false,
    String? studentId,
  }) => _api.data(
    'events',
    query: {
      'from': Formatters.isoDay(from),
      'to': Formatters.isoDay(to),
      'holidays': holidaysOnly ? true : null,
      'studentId': studentId,
    },
    parse: EventModels.events,
  );

  @override
  Future<SchoolEvent> event(String id, {String? studentId}) => _api.data(
    'events/${Uri.encodeComponent(id)}',
    query: {'studentId': studentId},
    parse: EventModels.event,
  );

  @override
  Future<SchoolEvent> create(EventInput input, {required EventScope scope, String? institutionId}) => _api.data(
    'events',
    method: HttpMethod.post,
    body: EventModels.createBody(input, scope: scope, institutionId: institutionId),
    parse: EventModels.event,
  );

  @override
  Future<SchoolEvent> change(SchoolEvent event, EventInput input) => _api.data(
    'events/${Uri.encodeComponent(event.id)}',
    method: HttpMethod.patch,
    body: EventModels.changeBody(event, input),
    parse: EventModels.event,
  );

  @override
  Future<SchoolEvent> changeScope(SchoolEvent event, {required EventScope scope, String? institutionId}) => _api.data(
    'events/${Uri.encodeComponent(event.id)}/scope',
    method: HttpMethod.post,
    body: EventModels.scopeBody(event, scope: scope, institutionId: institutionId),
    parse: EventModels.event,
  );

  @override
  Future<void> remove(String id) =>
      _api.data('events/${Uri.encodeComponent(id)}', method: HttpMethod.delete, parse: (_) {});
}
