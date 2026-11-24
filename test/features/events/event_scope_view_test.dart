import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/domain/events_repository.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_scope_sheet.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/events.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

ApiFailure refusal(String code, {int status = 422, List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late MockEventsRepository events;
  late MockInstitutionsRepository institutions;
  final society = schoolEvent(canEdit: true);

  setUp(() {
    events = MockEventsRepository();
    institutions = MockInstitutionsRepository();
    registerFallbackValue(society);
    registerFallbackValue(EventScope.society);
    when(institutions.institutions).thenAnswer(
      (_) async => [summary(), summary(id: 'i2', code: 'LVS', name: 'Lake View School')],
    );
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => schoolEvent(scope: EventScope.institution, institutionId: 'i1'));
    getIt
      ..registerSingleton<EventsRepository>(events)
      ..registerSingleton<InstitutionsRepository>(institutions);
  });
  tearDown(getIt.reset);

  /// Opens the sheet on [event] from a button, and records what it closed with.
  Future<List<bool?>> pump(WidgetTester tester, {SchoolEvent? event, double textScale = 1}) async {
    final closed = <bool?>[];
    await tester.pumpAppScaled(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => closed.add(await showEventScopeSheet(context, event ?? society)),
            child: const Text('open'),
          ),
        ),
      ),
      textScale: textScale,
      size: const Size(400, 1000),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return closed;
  }

  Future<void> chooseInstitution(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(const Key('eventScope.institution')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('eventScope.save')));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the scope the event has, a Society event with no Institution to choose', (tester) async {
    await pump(tester);
    expect(find.text('Where does this event belong?'), findsOneWidget);
    expect(find.byKey(const Key('eventScope.scope')), findsOneWidget);
    expect(find.byKey(const Key('eventScope.institution')), findsNothing);
  });

  testWidgets('moves the event to an Institution chosen, and closes so the event is read again', (tester) async {
    final closed = await pump(tester);
    await tester.tap(find.text('One Institution'));
    await tester.pumpAndSettle();
    await chooseInstitution(tester, 'Lake View School');
    await save(tester);
    verify(() => events.changeScope(society, scope: EventScope.institution, institutionId: 'i2')).called(1);
    expect(closed, [true]);
  });

  testWidgets('opens on the Institution an Institution event belongs to, and moves it to the Society', (tester) async {
    final closed = await pump(
      tester,
      event: schoolEvent(canEdit: true, scope: EventScope.institution, institutionId: 'i2'),
    );
    expect(
      find.descendant(of: find.byKey(const Key('eventScope.institution')), matching: find.text('Lake View School')),
      findsOneWidget,
    );
    await tester.tap(find.text('The whole Society'));
    await tester.pumpAndSettle();
    await save(tester);
    verify(() => events.changeScope(any(), scope: EventScope.society)).called(1);
    expect(closed, [true]);
  });

  testWidgets('asks for the Institution of an Institution event, and sends nothing without it', (tester) async {
    await pump(tester);
    await tester.tap(find.text('One Institution'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(find.text('This field is required.'), findsOneWidget);
    verifyNever(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    );
  });

  testWidgets('says why a move was refused and keeps the sheet', (tester) async {
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenThrow(refusal('SERVER_ERROR', status: 500));
    final closed = await pump(tester);
    await tester.tap(find.text('One Institution'));
    await tester.pumpAndSettle();
    await chooseInstitution(tester, 'Sri Vidya High School');
    await save(tester);
    expect(find.byKey(const Key('eventScope.error')), findsOneWidget);
    expect(find.byKey(const Key('eventScope.reload')), findsNothing);
    expect(closed, isEmpty);
  });

  testWidgets('shows a refusal that names the Institution under it only, not also above the form', (tester) async {
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenThrow(refusal('VALIDATION_FAILED', status: 400, fields: [const FieldError.required('institutionId')]));
    await pump(tester);
    await tester.tap(find.text('One Institution'));
    await tester.pumpAndSettle();
    await chooseInstitution(tester, 'Sri Vidya High School');
    await save(tester);
    expect(find.text('This field is required.'), findsOneWidget);
    expect(find.byKey(const Key('eventScope.error')), findsNothing);
  });

  testWidgets('says under the Institution that the picture belongs to another one, in the app’s words', (tester) async {
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenThrow(
      refusal(
        'VALIDATION_FAILED',
        status: 400,
        fields: [const FieldError(field: 'institutionId', code: 'INVALID_VALUE', message: 'server words')],
      ),
    );
    await pump(tester);
    await tester.tap(find.text('One Institution'));
    await tester.pumpAndSettle();
    await chooseInstitution(tester, 'Sri Vidya High School');
    await save(tester);
    expect(
      find.text("This event's picture belongs to another Institution. Change or remove the picture first."),
      findsOneWidget,
    );
    expect(find.text('server words'), findsNothing);
  });

  testWidgets('on an event changed meanwhile, says so and closes on Read the event again', (tester) async {
    when(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenThrow(refusal('VERSION_CONFLICT', status: 409));
    final closed = await pump(tester);
    await tester.tap(find.text('One Institution'));
    await tester.pumpAndSettle();
    await chooseInstitution(tester, 'Sri Vidya High School');
    await save(tester);
    expect(find.byKey(const Key('eventScope.error')), findsOneWidget);
    expect(tester.widget<AppButton>(find.byKey(const Key('eventScope.save'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('eventScope.reload')));
    await tester.pumpAndSettle();
    expect(closed, [true]);
  });

  testWidgets('says why the Institutions could not be read, and reads them again on Try again', (tester) async {
    var calls = 0;
    when(institutions.institutions).thenAnswer((_) async {
      if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
      return [summary()];
    });
    await pump(tester);
    expect(find.byKey(const Key('eventScope.loadFailed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eventScope.save')), findsOneWidget);
  });

  testWidgets('offers no Try again for Institutions it was refused', (tester) async {
    when(institutions.institutions).thenThrow(refusal('FORBIDDEN', status: 403));
    await pump(tester);
    expect(find.byKey(const Key('eventScope.loadFailed')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('closes on Cancel without moving the event', (tester) async {
    final closed = await pump(tester);
    await tester.tap(find.byKey(const Key('eventScope.cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('eventScope.save')), findsNothing);
    expect(closed, [null]);
    verifyNever(
      () => events.changeScope(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    );
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      event: schoolEvent(canEdit: true, scope: EventScope.institution, institutionId: 'i2'),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
  });
}
