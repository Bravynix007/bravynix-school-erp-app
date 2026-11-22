import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_form_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_form_page.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  late MockMastersRepository masters;
  final today = DateTime(2026, 11, 17);

  setUp(() {
    events = MockEventsRepository();
    institutions = MockInstitutionsRepository();
    masters = MockMastersRepository();
    registerFallbackValue(planEvent);
    registerFallbackValue(schoolEvent());
    registerFallbackValue(EventScope.society);
    when(institutions.institutions).thenAnswer(
      (_) async => [summary(), summary(id: 'i2', code: 'LVS', name: 'Lake View School')],
    );
    when(() => masters.entries(MasterType.classCategories)).thenAnswer(
      (_) async => const [MasterEntry(id: 'k1', name: 'Primary')],
    );
    when(() => masters.entries(MasterType.predefinedClasses, parentId: 'k1')).thenAnswer(
      (_) async => const [MasterEntry(id: 'c1', name: 'Class 1'), MasterEntry(id: 'c2', name: 'Class 2')],
    );
    when(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => schoolEvent());
  });

  /// Opens the form inside a router, so that what it closes with can be seen.
  Future<List<bool?>> pump(
    WidgetTester tester, {
    SchoolEvent? event,
    bool owner = true,
    double textScale = 1,
    Size size = const Size(400, 3000),
  }) async {
    final closed = <bool?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => closed.add(await context.push<bool>('/form')),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider(
            create: (_) => EventFormBloc(events, institutions, masters, existing: event)..add(const EventFormStarted()),
            child: EventFormView(event: event, owner: owner, today: today),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpAppScaled(
      Router(
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
      ),
      textScale: textScale,
      size: size,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return closed;
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
  }

  Future<void> choose(WidgetTester tester, String field, String text) async {
    await tester.ensureVisible(find.byKey(Key(field)));
    await tester.tap(find.byKey(Key(field)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('reading what the form offers', () {
    testWidgets('says plainly when the person may not see it', (tester) async {
      when(institutions.institutions).thenThrow(refusal('FORBIDDEN', status: 403));
      await pump(tester);
      expect(find.byKey(const Key('eventForm.forbidden')), findsOneWidget);
    });

    testWidgets('says why it could not read, and reads again on Try again', (tester) async {
      var calls = 0;
      when(institutions.institutions).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return [summary()];
      });
      await pump(tester);
      expect(find.byKey(const Key('eventForm.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eventForm.title')), findsOneWidget);
    });

    testWidgets('with no Institution to add to, says so and offers no Save', (tester) async {
      when(institutions.institutions).thenAnswer((_) async => []);
      await pump(tester);
      expect(find.byKey(const Key('eventForm.noInstitutions')), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });
  });

  group('adding an event', () {
    testWidgets('as an Owner offers the Society or an Institution, and sends the Society event with nothing else', (
      tester,
    ) async {
      final closed = await pump(tester);
      expect(find.text('Add event'), findsOneWidget);
      expect(find.byKey(const Key('eventForm.scope')), findsOneWidget);
      // The Society is chosen first, so no Institution is asked for.
      expect(find.byKey(const Key('eventForm.institution')), findsNothing);
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await save(tester);
      verify(
        () => events.create(
          EventInput(
            title: 'Sports Day',
            startDate: today,
            endDate: today,
            durationLabel: '1 Day Event',
            audience: EventAudience.everyone,
          ),
          scope: EventScope.society,
        ),
      ).called(1);
      expect(find.text('Event saved'), findsOneWidget);
      expect(closed, [true]);
    });

    testWidgets('as an Owner for an Institution asks which, and sends it', (tester) async {
      await pump(tester);
      await tester.ensureVisible(find.text('One Institution'));
      await tester.tap(find.text('One Institution'));
      await tester.pumpAndSettle();
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await save(tester);
      expect(find.text('This field is required.'), findsOneWidget);
      await choose(tester, 'eventForm.institution', 'Lake View School');
      await save(tester);
      verify(
        () => events.create(any(), scope: EventScope.institution, institutionId: 'i2'),
      ).called(1);
    });

    testWidgets('as an Admin offers only Institutions, and has the only one chosen', (tester) async {
      when(institutions.institutions).thenAnswer((_) async => [summary()]);
      await pump(tester, owner: false);
      expect(find.byKey(const Key('eventForm.scope')), findsNothing);
      expect(find.byKey(const Key('eventForm.institution')), findsOneWidget);
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await save(tester);
      verify(() => events.create(any(), scope: EventScope.institution, institutionId: 'i1')).called(1);
    });

    testWidgets('names a title and a duration left empty, and sends nothing', (tester) async {
      await pump(tester);
      await save(tester);
      expect(find.text('This field is required.'), findsNWidgets(2));
      verifyNever(
        () => events.create(
          any(),
          scope: any(named: 'scope'),
          institutionId: any(named: 'institutionId'),
        ),
      );
    });

    testWidgets('sends the audience, the picture, the description and the venue that were chosen', (tester) async {
      await pump(tester);
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await type(tester, 'eventForm.description', 'Races and a march past.');
      await type(tester, 'eventForm.venue', 'Playground');
      await tester.ensureVisible(find.text('Staff'));
      await tester.tap(find.descendant(of: find.byKey(const Key('eventForm.audience')), matching: find.text('Staff')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sports'));
      await tester.tap(find.descendant(of: find.byKey(const Key('eventForm.picture')), matching: find.text('Sports')));
      await tester.pumpAndSettle();
      await save(tester);
      verify(
        () => events.create(
          EventInput(
            title: 'Sports Day',
            startDate: today,
            endDate: today,
            durationLabel: '1 Day Event',
            audience: EventAudience.staff,
            description: 'Races and a march past.',
            venue: 'Playground',
            presetImageCode: 'sports',
          ),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('a holiday asks for its kind and for who it is for, and names what is missing', (tester) async {
      await pump(tester);
      await type(tester, 'eventForm.title', 'Diwali break');
      await type(tester, 'eventForm.duration', '3 Days Holiday');
      await tester.ensureVisible(find.byKey(const Key('eventForm.holiday')));
      await tester.tap(find.byKey(const Key('eventForm.holiday')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text('Choose who the holiday is for.'), findsOneWidget);
      expect(find.text('This field is required.'), findsOneWidget);
      verifyNever(
        () => events.create(
          any(),
          scope: any(named: 'scope'),
          institutionId: any(named: 'institutionId'),
        ),
      );
    });

    testWidgets('a holiday for students can be limited to classes, and sends the ones ticked', (tester) async {
      await pump(tester);
      await type(tester, 'eventForm.title', 'Diwali break');
      await type(tester, 'eventForm.duration', '3 Days Holiday');
      await tester.ensureVisible(find.byKey(const Key('eventForm.holiday')));
      await tester.tap(find.byKey(const Key('eventForm.holiday')));
      await tester.pumpAndSettle();
      await choose(tester, 'eventForm.holidayType', 'Vacation');
      // No class is offered until the holiday is for students.
      expect(find.byKey(const ValueKey('eventForm.class.c1')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('eventForm.forStudents')));
      await tester.tap(find.byKey(const Key('eventForm.forStudents')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('eventForm.class.c2')));
      await tester.tap(find.byKey(const ValueKey('eventForm.class.c2')));
      await tester.pumpAndSettle();
      await save(tester);
      verify(
        () => events.create(
          EventInput(
            title: 'Diwali break',
            startDate: today,
            endDate: today,
            durationLabel: '3 Days Holiday',
            audience: EventAudience.everyone,
            isHoliday: true,
            holidayType: HolidayType.vacation,
            holidayForStudents: true,
            holidayClassIds: const ['c2'],
          ),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('says above the form why a save was refused, and keeps what was written', (tester) async {
      when(
        () => events.create(
          any(),
          scope: any(named: 'scope'),
          institutionId: any(named: 'institutionId'),
        ),
      ).thenThrow(refusal('SCOPE_NOT_ALLOWED', status: 403));
      final closed = await pump(tester);
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await save(tester);
      expect(find.byKey(const Key('eventForm.error')), findsOneWidget);
      expect(find.textContaining('Only an Owner can add or change an event of the whole Society'), findsOneWidget);
      expect(find.text('Sports Day'), findsOneWidget);
      expect(closed, isEmpty);
    });

    testWidgets('puts a field the server refused under that field', (tester) async {
      when(
        () => events.create(
          any(),
          scope: any(named: 'scope'),
          institutionId: any(named: 'institutionId'),
        ),
      ).thenThrow(
        refusal(
          'VALIDATION_FAILED',
          status: 400,
          fields: const [FieldError(field: 'title', code: 'REQUIRED', message: '')],
        ),
      );
      await pump(tester);
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await save(tester);
      expect(find.text('This field is required.'), findsOneWidget);
      expect(find.byKey(const Key('eventForm.error')), findsNothing);
    });

    testWidgets('moves the end along with a start that comes after it', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('eventForm.start')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await type(tester, 'eventForm.title', 'Sports Day');
      await type(tester, 'eventForm.duration', '1 Day Event');
      await save(tester);
      verify(
        () => events.create(
          any(that: isA<EventInput>().having((input) => input.endDate, 'end', DateTime(2026, 11, 20))),
          scope: any(named: 'scope'),
        ),
      ).called(1);
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      await pump(tester, textScale: 2, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      // A date wider than the field it sits in cannot fit any box on a 320 px phone at this scale.
      expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
    });
  });

  group('changing an event', () {
    final existing = schoolEvent(
      isHoliday: true,
      holidayType: HolidayType.vacation,
      forStudents: true,
      classIds: ['c1'],
    );

    testWidgets('opens on the event, offers no scope or Institution, and sends the version that was read', (
      tester,
    ) async {
      when(() => events.change(any(), any())).thenAnswer((_) async => existing);
      final closed = await pump(tester, event: existing);
      expect(find.text('Edit event'), findsOneWidget);
      expect(find.text('Annual Day'), findsOneWidget);
      expect(find.byKey(const Key('eventForm.scope')), findsNothing);
      expect(find.byKey(const Key('eventForm.institution')), findsNothing);
      verifyNever(institutions.institutions);
      await type(tester, 'eventForm.title', 'Annual Day 2026');
      await save(tester);
      verify(
        () => events.change(
          existing,
          any(
            that: isA<EventInput>().having((input) => input.title, 'title', 'Annual Day 2026').having(
              (input) => input.holidayClassIds,
              'classes',
              ['c1'],
            ),
          ),
        ),
      ).called(1);
      expect(closed, [true]);
    });

    testWidgets('on an event changed meanwhile, says so and hands back to the list, which reads again', (tester) async {
      when(() => events.change(any(), any())).thenThrow(refusal('VERSION_CONFLICT', status: 409));
      final closed = await pump(tester, event: existing);
      await save(tester);
      expect(find.byKey(const Key('eventForm.error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('eventForm.backToList')));
      await tester.pumpAndSettle();
      expect(closed, [true]);
    });

    testWidgets('on an event removed meanwhile, Cancel hands back to the list too', (tester) async {
      when(() => events.change(any(), any())).thenThrow(refusal('NOT_FOUND', status: 404));
      final closed = await pump(tester, event: existing);
      await save(tester);
      expect(find.text('This event is no longer available.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(closed, [true]);
    });

    testWidgets('closes on Cancel without saving, and with nothing for the list to read', (tester) async {
      final closed = await pump(tester, event: existing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(closed, [null]);
      verifyNever(() => events.change(any(), any()));
    });
  });
}
