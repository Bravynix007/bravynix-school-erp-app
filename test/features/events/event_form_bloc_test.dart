import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_form_bloc.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/events.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockEventsRepository events;
  late MockInstitutionsRepository institutions;
  late MockMastersRepository masters;

  const lkg = MasterEntry(id: 'c1', name: 'LKG', parentId: 'k1');
  const first = MasterEntry(id: 'c2', name: 'Class 1', parentId: 'k2');
  const options = EventOptions(institutions: [], classes: [lkg, first]);

  setUp(() {
    events = MockEventsRepository();
    institutions = MockInstitutionsRepository();
    masters = MockMastersRepository();
    registerFallbackValue(planEvent);
    registerFallbackValue(schoolEvent());
    registerFallbackValue(EventScope.society);
    when(institutions.institutions).thenAnswer((_) async => [summary()]);
    when(() => masters.entries(MasterType.classCategories)).thenAnswer(
      (_) async => const [MasterEntry(id: 'k1', name: 'Pre-primary'), MasterEntry(id: 'k2', name: 'Primary')],
    );
    when(() => masters.entries(MasterType.predefinedClasses, parentId: 'k1')).thenAnswer((_) async => [lkg]);
    when(() => masters.entries(MasterType.predefinedClasses, parentId: 'k2')).thenAnswer((_) async => [first]);
  });

  EventFormBloc build({SchoolEvent? existing}) => EventFormBloc(events, institutions, masters, existing: existing);

  Future<EventFormBloc> open({SchoolEvent? existing}) async {
    final bloc = build(existing: existing)..add(const EventFormStarted());
    await bloc.stream.firstWhere((state) => state is EventFormEditing);
    return bloc;
  }

  EventFields fields({
    String title = 'Sports Day',
    String duration = '1 Day Event',
    DateTime? end,
    String description = '',
    bool isHoliday = false,
    HolidayType? holidayType,
    bool forStudents = false,
    bool forStaff = false,
    EventScope scope = EventScope.institution,
    String? institutionId = 'i1',
  }) => EventFields(
    title: title,
    startDate: DateTime(2026, 12, 5),
    endDate: end ?? DateTime(2026, 12, 5),
    durationLabel: duration,
    audience: EventAudience.everyone,
    description: description,
    isHoliday: isHoliday,
    holidayType: holidayType,
    holidayForStudents: forStudents,
    holidayForStaff: forStaff,
    scope: scope,
    institutionId: institutionId,
  );

  List<String> problemsOf(EventFormBloc bloc) => [
    for (final error in (bloc.state as EventFormEditing).failure!.fieldErrors) '${error.field}:${error.code}',
  ];

  test('offers the Institutions of a new event and every predefined class, category by category', () async {
    final bloc = await open();
    expect(bloc.state, EventFormEditing(EventOptions(institutions: [summary()], classes: const [lkg, first])));
    await bloc.close();
  });

  test('offers no Institution for an event that is changed, which keeps its scope, and reads none', () async {
    final bloc = await open(existing: schoolEvent());
    expect(bloc.state, const EventFormEditing(options));
    verifyNever(institutions.institutions);
    await bloc.close();
  });

  test('is told when what it offers cannot be read, and reads it again on Try again', () async {
    when(institutions.institutions).thenThrow(refusal('FORBIDDEN', status: 403));
    final bloc = build()..add(const EventFormStarted());
    await bloc.stream.firstWhere((state) => state is EventFormLoadFailed);
    when(institutions.institutions).thenAnswer((_) async => [summary()]);
    bloc.add(const EventFormStarted());
    await bloc.stream.firstWhere((state) => state is EventFormEditing);
    await bloc.close();
  });

  test('creates an event for an Institution, with an empty description or venue sent as none', () async {
    when(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => schoolEvent());
    final bloc = await open()
      ..add(EventFormSubmitted(fields(title: '  Sports Day  ', description: '   ')));
    await bloc.stream.firstWhere((state) => state is EventFormSaved);
    verify(() => events.create(planEvent, scope: EventScope.institution, institutionId: 'i1')).called(1);
    await bloc.close();
  });

  test('creates an event for the Society, which names no Institution even when one was chosen', () async {
    when(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => schoolEvent());
    final bloc = await open()
      ..add(EventFormSubmitted(fields(scope: EventScope.society)));
    await bloc.stream.firstWhere((state) => state is EventFormSaved);
    verify(() => events.create(planEvent, scope: EventScope.society)).called(1);
    await bloc.close();
  });

  test('changes the event it was opened on, and creates none', () async {
    final existing = schoolEvent();
    when(() => events.change(any(), any())).thenAnswer((_) async => existing);
    final bloc = await open(existing: existing)
      ..add(EventFormSubmitted(fields()));
    await bloc.stream.firstWhere((state) => state is EventFormSaved);
    verify(() => events.change(existing, planEvent)).called(1);
    verifyNever(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    );
    await bloc.close();
  });

  test('sends nothing without a title or a duration, and names both', () async {
    final bloc = await open()
      ..add(EventFormSubmitted(fields(title: '  ', duration: '')));
    await bloc.stream.firstWhere((state) => state is EventFormEditing && state.failure != null);
    expect(problemsOf(bloc), ['title:REQUIRED', 'durationLabel:REQUIRED']);
    verifyNever(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    );
    await bloc.close();
  });

  test('sends nothing for an end before the start', () async {
    final bloc = await open()
      ..add(EventFormSubmitted(fields(end: DateTime(2026, 12, 4))));
    await bloc.stream.firstWhere((state) => state is EventFormEditing && state.failure != null);
    expect(problemsOf(bloc), ['endDate:OUT_OF_RANGE']);
    await bloc.close();
  });

  test('wants an Institution for an Institution event, and none for a Society event or a change', () async {
    final bloc = await open()
      ..add(EventFormSubmitted(fields(institutionId: null)));
    await bloc.stream.firstWhere((state) => state is EventFormEditing && state.failure != null);
    expect(problemsOf(bloc), ['institutionId:REQUIRED']);
    await bloc.close();
  });

  test('wants a kind and somebody for a holiday', () async {
    final bloc = await open()
      ..add(EventFormSubmitted(fields(isHoliday: true)));
    await bloc.stream.firstWhere((state) => state is EventFormEditing && state.failure != null);
    expect(problemsOf(bloc), ['holidayType:REQUIRED', 'holidayForStudents:REQUIRED']);
    await bloc.close();
  });

  test('keeps the form and says why a save was refused', () async {
    when(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenThrow(refusal('SCOPE_NOT_ALLOWED', status: 403));
    final bloc = await open()
      ..add(EventFormSubmitted(fields()));
    await bloc.stream.firstWhere((state) => state is EventFormEditing && state.failure != null);
    expect((bloc.state as EventFormEditing).failure!.code, 'SCOPE_NOT_ALLOWED');
    await bloc.close();
  });

  test('does not save twice while a save is on its way', () async {
    when(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => schoolEvent());
    final bloc = await open()
      ..add(EventFormSubmitted(fields()))
      ..add(EventFormSubmitted(fields()));
    await bloc.stream.firstWhere((state) => state is EventFormSaved);
    verify(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).called(1);
    await bloc.close();
  });
}
