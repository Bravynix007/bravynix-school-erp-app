import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/bloc/event_form_bloc.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_form_page.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/events.dart';
import '../../helpers/files.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/network_images.dart';
import '../../helpers/pump_app.dart';

ApiFailure refusal(String code, {int status = 422, List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late MockEventsRepository events;
  late MockInstitutionsRepository institutions;
  late MockClassCatalogue catalogue;
  late MockFilesRepository files;
  final today = DateTime(2026, 11, 17);

  setUp(() {
    events = MockEventsRepository();
    institutions = MockInstitutionsRepository();
    catalogue = MockClassCatalogue();
    files = MockFilesRepository();
    registerFallbackValue(photo);
    registerFallbackValue(FilePurpose.eventImage);
    registerFallbackValue(planEvent);
    registerFallbackValue(schoolEvent());
    registerFallbackValue(EventScope.society);
    when(institutions.institutions).thenAnswer(
      (_) async => [summary(), summary(id: 'i2', code: 'LVS', name: 'Lake View School')],
    );
    const primary = NamedRef(id: 'k1', code: 'PRIMARY', name: 'Primary');
    when(catalogue.all).thenAnswer(
      (_) async => const [
        ClassChoice(
          predefinedClass: NamedRef(id: 'c1', code: 'C1', name: 'Class 1'),
          category: primary,
        ),
        ClassChoice(
          predefinedClass: NamedRef(id: 'c2', code: 'C2', name: 'Class 2'),
          category: primary,
        ),
      ],
    );
    when(
      () => events.create(
        any(),
        scope: any(named: 'scope'),
        institutionId: any(named: 'institutionId'),
      ),
    ).thenAnswer((_) async => schoolEvent());
    when(
      () => files.upload(
        any(),
        purpose: any(named: 'purpose'),
        institutionId: any(named: 'institutionId'),
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => uploadedPhoto);
    // The picture field starts its own upload and picker from these.
    getIt
      ..registerSingleton<FilesRepository>(files)
      ..registerSingleton<FilePicking>(FakeFilePicking(result: photo));
  });
  tearDown(getIt.reset);

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
            create: (_) =>
                EventFormBloc(events, institutions, catalogue, existing: event)..add(const EventFormStarted()),
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

    testWidgets('sends the title and the duration without their spaces, and an empty description or venue as none', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, 'eventForm.title', '  Sports Day  ');
      await type(tester, 'eventForm.duration', '  1 Day Event  ');
      await type(tester, 'eventForm.description', '   ');
      await type(tester, 'eventForm.venue', '  ');
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
    });

    testWidgets('offers every picture under its own name', (tester) async {
      await pump(tester);
      final picture = find.byKey(const Key('eventForm.picture'));
      for (final name in [
        'None',
        'Assembly',
        'Celebration',
        'Cultural',
        'Exam',
        'Festival',
        'Holiday',
        'Meeting',
        'Science',
        'Sports',
        'Trip',
      ]) {
        expect(
          find.descendant(of: picture, matching: find.text(name)),
          findsOneWidget,
          reason: name,
        );
      }
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

  group('the picture of an event', () {
    Future<void> addPhoto(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Add photo'));
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo.gallery')));
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester tester) async {
      await type(tester, 'eventForm.title', 'Poster day');
      await type(tester, 'eventForm.duration', '1 Day');
    }

    void verifyUploadedFor(String institutionId) => verify(
      () => files.upload(
        any(),
        purpose: FilePurpose.eventImage,
        institutionId: institutionId,
        onProgress: any(named: 'onProgress'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).called(1);

    testWidgets('is uploaded for an Institution and sent as its file, with no preset', (tester) async {
      when(institutions.institutions).thenAnswer((_) async => [summary()]);
      await pump(tester, owner: false);
      await fill(tester);
      await addPhoto(tester);
      verifyUploadedFor('i1');
      expect(find.text('Change photo'), findsOneWidget);
      await save(tester);
      verify(
        () => events.create(
          any(
            that: isA<EventInput>()
                .having((input) => input.imageFileId, 'file', 'f1')
                .having(
                  (input) => input.presetImageCode,
                  'preset',
                  isNull,
                ),
          ),
          scope: EventScope.institution,
          institutionId: 'i1',
        ),
      ).called(1);
    });

    testWidgets('of a Society event is uploaded for the first Institution the Owner reaches', (tester) async {
      await pump(tester);
      await fill(tester);
      await addPhoto(tester);
      verifyUploadedFor('i1');
      await save(tester);
      verify(
        () => events.create(
          any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', 'f1')),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('waits for the Institution to be chosen when there are several, and starts again when it changes', (
      tester,
    ) async {
      await pump(tester);
      await tester.ensureVisible(find.text('One Institution'));
      await tester.tap(find.text('One Institution'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eventForm.pictureWaits')), findsOneWidget);
      expect(find.text('Add photo'), findsNothing);
      await choose(tester, 'eventForm.institution', 'Sri Vidya High School');
      expect(find.byKey(const Key('eventForm.pictureWaits')), findsNothing);
      await addPhoto(tester);
      verifyUploadedFor('i1');
      expect(find.text('Change photo'), findsOneWidget);
      // A picture sent for one Institution is not valid for another, so it is let go.
      await choose(tester, 'eventForm.institution', 'Lake View School');
      expect(find.text('Add photo'), findsOneWidget);
      await fill(tester);
      await save(tester);
      verify(
        () => events.create(
          any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', isNull)),
          scope: EventScope.institution,
          institutionId: 'i2',
        ),
      ).called(1);
    });

    testWidgets('drops the preset chosen before it', (tester) async {
      await pump(tester);
      await fill(tester);
      await tester.ensureVisible(find.text('Sports'));
      await tester.tap(find.descendant(of: find.byKey(const Key('eventForm.picture')), matching: find.text('Sports')));
      await tester.pumpAndSettle();
      await addPhoto(tester);
      await save(tester);
      verify(
        () => events.create(
          any(
            that: isA<EventInput>()
                .having((input) => input.imageFileId, 'file', 'f1')
                .having((input) => input.presetImageCode, 'preset', isNull),
          ),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('is dropped for a preset chosen after it, and the tile is empty again', (tester) async {
      await pump(tester);
      await fill(tester);
      await addPhoto(tester);
      expect(find.text('Change photo'), findsOneWidget);
      await tester.ensureVisible(find.text('Exam'));
      await tester.tap(find.descendant(of: find.byKey(const Key('eventForm.picture')), matching: find.text('Exam')));
      await tester.pumpAndSettle();
      expect(find.text('Add photo'), findsOneWidget);
      await save(tester);
      verify(
        () => events.create(
          any(
            that: isA<EventInput>()
                .having((input) => input.imageFileId, 'file', isNull)
                .having((input) => input.presetImageCode, 'preset', 'exam'),
          ),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('holds the form until it has been sent, and says so', (tester) async {
      final release = Completer<void>();
      when(
        () => files.upload(
          any(),
          purpose: any(named: 'purpose'),
          institutionId: any(named: 'institutionId'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        await release.future;
        return uploadedPhoto;
      });
      await pump(tester);
      await fill(tester);
      await addPhoto(tester);
      expect(find.byKey(const Key('eventForm.uploadingWait')), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pump();
      verifyNever(
        () => events.create(
          any(),
          scope: any(named: 'scope'),
          institutionId: any(named: 'institutionId'),
        ),
      );
      release.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eventForm.uploadingWait')), findsNothing);
      await save(tester);
      verify(
        () => events.create(
          any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', 'f1')),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('of an event that has one is shown, kept when it is saved and taken off with Remove', (tester) async {
      const image = EventImage(id: 'f7', url: 'https://files.test/public/f7');
      final withImage = schoolEvent(image: image, canEdit: true);
      when(() => events.change(any(), any())).thenAnswer((_) async => withImage);
      await withNetworkImages(() async {
        await pump(tester, event: withImage);
        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Change photo'), findsOneWidget);
        await save(tester);
        verify(
          () =>
              events.change(withImage, any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', 'f7'))),
        ).called(1);

        await pump(tester, event: withImage);
        await tester.ensureVisible(find.text('Remove photo'));
        await tester.tap(find.text('Remove photo'));
        await tester.pumpAndSettle();
        expect(find.text('Add photo'), findsOneWidget);
        await save(tester);
        verify(
          () => events.change(
            withImage,
            any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', isNull)),
          ),
        ).called(1);
      });
    });

    testWidgets('of an event that has one is uploaded for that Institution when it is replaced', (tester) async {
      const image = EventImage(id: 'f7', url: 'https://files.test/public/f7');
      final withImage = schoolEvent(image: image, scope: EventScope.institution, institutionId: 'i2', canEdit: true);
      when(() => events.change(any(), any())).thenAnswer((_) async => withImage);
      await withNetworkImages(() async {
        await pump(tester, event: withImage);
        await tester.ensureVisible(find.text('Change photo'));
        await tester.tap(find.text('Change photo'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('photo.gallery')));
        await tester.pumpAndSettle();
        verifyUploadedFor('i2');
        await save(tester);
        verify(
          () =>
              events.change(withImage, any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', 'f1'))),
        ).called(1);
      });
    });

    testWidgets('is let go when the scope changes the Institution it is uploaded for, and so is a send in flight', (
      tester,
    ) async {
      await pump(tester);
      await fill(tester);
      await tester.ensureVisible(find.text('One Institution'));
      await tester.tap(find.text('One Institution'));
      await tester.pumpAndSettle();
      await choose(tester, 'eventForm.institution', 'Lake View School');
      await addPhoto(tester);
      verifyUploadedFor('i2');
      // Back to the whole Society: the picture was sent for Lake View, so it is not kept, and the tile is empty.
      await tester.ensureVisible(find.text('The whole Society'));
      await tester.tap(find.text('The whole Society'));
      await tester.pumpAndSettle();
      expect(find.text('Add photo'), findsOneWidget);
      await save(tester);
      verify(
        () => events.create(
          any(that: isA<EventInput>().having((input) => input.imageFileId, 'file', isNull)),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('does not stay held by a send the scope change abandoned', (tester) async {
      final release = Completer<void>();
      when(
        () => files.upload(
          any(),
          purpose: any(named: 'purpose'),
          institutionId: any(named: 'institutionId'),
          onProgress: any(named: 'onProgress'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async {
        await release.future;
        return uploadedPhoto;
      });
      await pump(tester);
      await fill(tester);
      await tester.ensureVisible(find.text('One Institution'));
      await tester.tap(find.text('One Institution'));
      await tester.pumpAndSettle();
      await choose(tester, 'eventForm.institution', 'Lake View School');
      await addPhoto(tester);
      expect(find.byKey(const Key('eventForm.uploadingWait')), findsOneWidget);
      await tester.ensureVisible(find.text('The whole Society'));
      await tester.tap(find.text('The whole Society'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('eventForm.uploadingWait')), findsNothing);
      await save(tester);
      verify(
        () => events.create(
          any(),
          scope: EventScope.society,
        ),
      ).called(1);
    });

    testWidgets('of an event that has one is dropped for a preset chosen instead', (tester) async {
      const image = EventImage(id: 'f7', url: 'https://files.test/public/f7');
      final withImage = schoolEvent(image: image, scope: EventScope.institution, institutionId: 'i2', canEdit: true);
      when(() => events.change(any(), any())).thenAnswer((_) async => withImage);
      await withNetworkImages(() async {
        await pump(tester, event: withImage);
        await tester.ensureVisible(find.text('Exam'));
        await tester.tap(find.descendant(of: find.byKey(const Key('eventForm.picture')), matching: find.text('Exam')));
        await tester.pumpAndSettle();
        await save(tester);
        verify(
          () => events.change(
            withImage,
            any(
              that: isA<EventInput>()
                  .having((input) => input.imageFileId, 'file', isNull)
                  .having((input) => input.presetImageCode, 'preset', 'exam'),
            ),
          ),
        ).called(1);
      });
    });

    testWidgets('puts a refusal that names the picture under it', (tester) async {
      when(() => events.change(any(), any())).thenThrow(
        refusal(
          'VALIDATION_FAILED',
          status: 400,
          fields: const [FieldError(field: 'imageFileId', code: 'INVALID_VALUE', message: 'bad')],
        ),
      );
      await pump(tester, event: schoolEvent(canEdit: true));
      await save(tester);
      expect(find.byKey(const Key('eventForm.pictureError')), findsOneWidget);
      expect(find.byKey(const Key('eventForm.error')), findsNothing);
    });

    testWidgets('fits at the largest text size on a narrow phone', (tester) async {
      await pump(tester, textScale: 2, size: const Size(320, 640));
      await tester.scrollUntilVisible(find.text('Add photo'), 300, scrollable: find.byType(Scrollable).first);
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
    });
  });

  group('changing an event', () {
    final existing = schoolEvent(
      scope: EventScope.institution,
      institutionId: 'i1',
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

    testWidgets('keeps the start of an event that began before the calendar reaches, when its day is confirmed', (
      tester,
    ) async {
      final early = schoolEvent(startDate: DateTime(2025, 6), endDate: DateTime(2026, 11, 20));
      when(() => events.change(any(), any())).thenAnswer((_) async => early);
      await pump(tester, event: early);
      await tester.tap(find.byKey(const Key('eventForm.start')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await save(tester);
      verify(
        () => events.change(
          early,
          any(that: isA<EventInput>().having((input) => input.startDate, 'start', DateTime(2025, 6))),
        ),
      ).called(1);
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
