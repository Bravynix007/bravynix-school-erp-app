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
}
