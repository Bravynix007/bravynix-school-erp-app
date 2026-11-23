import 'dart:async';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_scope_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/events.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockEventsRepository events;
  late MockInstitutionsRepository institutions;
  final event = schoolEvent(canEdit: true);

  setUp(() {
    events = MockEventsRepository();
    institutions = MockInstitutionsRepository();
    registerFallbackValue(event);
    registerFallbackValue(EventScope.society);
    when(institutions.institutions).thenAnswer((_) async => [summary()]);
  });

  Future<EventScopeBloc> open() async {
    final bloc = EventScopeBloc(events, institutions, event)..add(const EventScopeStarted());
    await bloc.stream.firstWhere((state) => state is EventScopeEditing);
    return bloc;
  }

  Future<List<String>> problemsOf(EventScopeBloc bloc) async {
    final editing = (await bloc.stream.firstWhere(
      (state) => state is EventScopeEditing && state.failure != null,
    )) as EventScopeEditing;
    return [for (final error in editing.failure!.fieldErrors) '${error.field}:${error.code}'];
  }

  test('offers the Institutions of the Society to move the event to', () async {
    final bloc = await open();
    expect(bloc.state, EventScopeEditing([summary()]));
    await bloc.close();
  });

  test('is told when the Institutions cannot be read, and reads them again on Try again', () async {
    when(institutions.institutions).thenThrow(refusal('FORBIDDEN', status: 403));
    final bloc = EventScopeBloc(events, institutions, event)..add(const EventScopeStarted());
    await bloc.stream.firstWhere((state) => state is EventScopeLoadFailed);
    when(institutions.institutions).thenAnswer((_) async => [summary()]);
    bloc.add(const EventScopeStarted());
    await bloc.stream.firstWhere((state) => state is EventScopeEditing);
    await bloc.close();
  });

  test('moves the event to an Institution, and to the Society with no Institution even when one was chosen', () async {
    final moved = schoolEvent(scope: EventScope.institution, institutionId: 'i1');
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => moved);
    final bloc = await open()
      ..add(const EventScopeSubmitted(EventScope.institution, 'i1'));
    await bloc.stream.firstWhere((state) => state is EventScopeSaved);
    verify(() => events.changeScope(event, scope: EventScope.institution, institutionId: 'i1')).called(1);
    await bloc.close();

    final other = await open()
      ..add(const EventScopeSubmitted(EventScope.society, 'i1'));
    await other.stream.firstWhere((state) => state is EventScopeSaved);
    verify(() => events.changeScope(event, scope: EventScope.society)).called(1);
    await other.close();
  });

  test('sends nothing for an Institution event with no Institution, and names it', () async {
    final bloc = await open()
      ..add(const EventScopeSubmitted(EventScope.institution, null));
    expect(await problemsOf(bloc), ['institutionId:REQUIRED']);
    verifyNever(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    );
    await bloc.close();
  });

  test('keeps the sheet and says why a move was refused', () async {
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenThrow(refusal('VERSION_CONFLICT', status: 409));
    final bloc = await open()
      ..add(const EventScopeSubmitted(EventScope.institution, 'i1'));
    final editing = await bloc.stream.firstWhere(
      (state) => state is EventScopeEditing && state.failure != null,
    ) as EventScopeEditing;
    expect(editing.failure!.code, 'VERSION_CONFLICT');
    await bloc.close();
  });

  test('does not move twice while a move is on its way', () async {
    final pending = Completer<SchoolEvent>();
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) => pending.future);
    final bloc = await open()
      ..add(const EventScopeSubmitted(EventScope.institution, 'i1'))
      ..add(const EventScopeSubmitted(EventScope.institution, 'i1'));
    await bloc.stream.firstWhere((state) => state is EventScopeEditing && state.saving);
    await Future<void>.delayed(Duration.zero);
    pending.complete(event);
    await bloc.stream.firstWhere((state) => state is EventScopeSaved);
    verify(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).called(1);
    await bloc.close();
  });
}
