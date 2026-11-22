import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/entry_form_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/entry_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/leaving_a_form.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';
import '../../helpers/time_slots.dart';
import '../../helpers/timetable.dart';

class _MockFormBloc extends MockBloc<EntryFormEvent, EntryFormState> implements EntryFormBloc;

ApiFailure _failure(int status, String code, {List<FieldError> fields = const [], Map<String, dynamic>? details}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields, details: details ?? {});

void main() {
  late _MockFormBloc bloc;
  const options = EntryOptions(slots: [firstPeriod, lunch], subjects: [maths, art], teachers: [kavya]);
  const editing = EntryFormEditing(options);

  setUpAll(() => registerFallbackValue(const EntryFormSubmitted(EntryFields())));
  setUp(() => bloc = _MockFormBloc());

  Future<void> pump(
    WidgetTester tester,
    EntryFormState state, {
    TimetableEntry? entry,
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<EntryFormBloc>.value(
        value: bloc,
        child: EntryFormView(entry: entry),
      ),
      textScale: textScale,
      size: size,
    );
  }

  /// Opens the dropdown of [field] and picks [text].
  Future<void> choose(WidgetTester tester, String field, String text) async {
    await tester.tap(find.byKey(Key(field)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  EntryFormSubmitted submitted() => verify(() => bloc.add(captureAny())).captured.single as EntryFormSubmitted;

  testWidgets('an empty form to add: nothing chosen, a lesson with its subject and teacher to pick', (tester) async {
    await pump(tester, editing);
    expect(find.text('Add entry'), findsOneWidget);
    expect(find.byKey(const Key('entryForm.subject')), findsOneWidget);
    expect(find.byKey(const Key('entryForm.teacher')), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('an edit starts from the entry', (tester) async {
    await pump(tester, editing, entry: mathsMonday);
    expect(find.text('Edit entry'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Period 1 · 09:00 to 09:45'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    // The teacher the entry names is the staff member f1 the form offers.
    expect(find.text('Kavya Nair'), findsOneWidget);
  });

  testWidgets('Save sends the day, the period, the subject and the teacher chosen', (tester) async {
    await pump(tester, editing);
    await choose(tester, 'entryForm.day', 'Tuesday');
    await choose(tester, 'entryForm.period', 'Period 1 · 09:00 to 09:45');
    await choose(tester, 'entryForm.subject', 'Art');
    await choose(tester, 'entryForm.teacher', 'Kavya Nair');
    await tester.tap(find.text('Save'));
    expect(
      submitted().fields,
      const EntryFields(dayOfWeek: 2, timeSlotId: 't1', subjectId: 'u2', staffMemberId: 'f1'),
    );
  });

  testWidgets('a break period makes the entry a break, which has no subject or teacher and cannot be turned off', (
    tester,
  ) async {
    await pump(tester, editing);
    await choose(tester, 'entryForm.day', 'Monday');
    await choose(tester, 'entryForm.period', 'Lunch · 12:00 to 12:30');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byKey(const Key('entryForm.subject')), findsNothing);
    expect(find.byKey(const Key('entryForm.teacher')), findsNothing);
    await tester.tap(find.byKey(const Key('entryForm.break')));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.text('Save'));
    expect(
      submitted().fields,
      const EntryFields(dayOfWeek: 1, timeSlotId: 't2', isBreak: true),
    );
  });

  testWidgets('a lesson period may still hold a break, and the subject and teacher come back when it is turned off', (
    tester,
  ) async {
    await pump(tester, editing, entry: mathsMonday);
    await tester.tap(find.byKey(const Key('entryForm.break')));
    await tester.pump();
    expect(find.byKey(const Key('entryForm.subject')), findsNothing);
    await tester.tap(find.byKey(const Key('entryForm.break')));
    await tester.pump();
    expect(find.byKey(const Key('entryForm.subject')), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
  });

  testWidgets('a subject or teacher that is no longer offered is chosen again, not shown', (tester) async {
    await pump(
      tester,
      const EntryFormEditing(EntryOptions(slots: [firstPeriod], subjects: [art], teachers: [])),
      entry: mathsMonday,
    );
    expect(find.text('Mathematics'), findsNothing);
    await tester.tap(find.text('Save'));
    expect(submitted().fields, const EntryFields(dayOfWeek: 1, timeSlotId: 't1'));
  });

  testWidgets('an edited break opens as a break, with no subject or teacher, in a lesson period too', (tester) async {
    await pump(tester, editing, entry: lunchMonday);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byKey(const Key('entryForm.subject')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    const breakInALessonPeriod = TimetableEntry(
      id: 'x9',
      sectionId: 'sec1',
      dayOfWeek: 1,
      slot: EntrySlot(id: 't1', periodNo: 1, startTime: '09:00', endTime: '09:45'),
      isBreak: true,
      version: 1,
    );
    await pump(tester, editing, entry: breakInALessonPeriod);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.byKey(const Key('entryForm.subject')), findsNothing);
    await tester.tap(find.text('Save'));
    expect(submitted().fields, const EntryFields(dayOfWeek: 1, timeSlotId: 't1', isBreak: true));
  });

  testWidgets('a period that is no longer offered is chosen again, not sent', (tester) async {
    await pump(
      tester,
      const EntryFormEditing(EntryOptions(slots: [lunch], subjects: [maths], teachers: [kavya])),
      entry: mathsMonday,
    );
    await tester.tap(find.text('Save'));
    expect(submitted().fields.timeSlotId, isNull);
  });

  testWidgets('says a refused period under the period', (tester) async {
    await pump(
      tester,
      EntryFormEditing(
        options,
        failure: _failure(
          400,
          'INVALID_SLOT',
          fields: const [FieldError(field: 'timeSlotId', code: 'INVALID_SLOT', message: 'Not a period of this year.')],
        ),
      ),
    );
    expect(
      find.descendant(of: find.byKey(const Key('entryForm.period')), matching: find.text('Not a period of this year.')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('entryForm.error')), findsNothing);
  });

  testWidgets('while saving, Save does nothing', (tester) async {
    await pump(tester, const EntryFormEditing(options, saving: true));
    final save = find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
  });

  testWidgets('shows a choice left empty as required, under that field', (tester) async {
    await pump(
      tester,
      const EntryFormEditing(
        options,
        failure: ApiFailure.invalid([FieldError.required('dayOfWeek'), FieldError.required('staffMemberId')]),
      ),
    );
    expect(find.text('This field is required.'), findsNWidgets(2));
    expect(find.byKey(const Key('entryForm.error')), findsNothing);
  });

  testWidgets('says a teacher deactivated meanwhile under the teacher, in the app words', (tester) async {
    await pump(
      tester,
      EntryFormEditing(
        options,
        failure: _failure(
          422,
          'REFERENCE_INACTIVE',
          fields: const [FieldError(field: 'staffMemberId', code: 'REFERENCE_INACTIVE', message: 'x')],
        ),
      ),
    );
    expect(find.text('Something you chose is no longer available. Choose again.'), findsOneWidget);
    expect(find.byKey(const Key('entryForm.error')), findsNothing);
  });

  testWidgets('says a clash above the form, naming where the teacher is when the server says', (tester) async {
    await pump(
      tester,
      EntryFormEditing(
        options,
        failure: _failure(
          409,
          'TEACHER_DOUBLE_BOOKED',
          details: {
            'conflict': {'sectionName': 'B', 'className': '8th'},
          },
        ),
      ),
    );
    expect(find.byKey(const Key('entryForm.error')), findsOneWidget);
    expect(find.textContaining('already teaching 8th - B'), findsOneWidget);
    expect(find.byKey(const Key('entryForm.backToList')), findsNothing);
  });

  testWidgets('offers Back to the list after a version conflict', (tester) async {
    await pump(tester, EntryFormEditing(options, failure: _failure(409, 'VERSION_CONFLICT')), entry: mathsMonday);
    expect(find.byKey(const Key('entryForm.backToList')), findsOneWidget);
  });

  leavingAFormTests(
    backToList: const Key('entryForm.backToList'),
    staying: const [(409, 'SECTION_SLOT_TAKEN'), (422, 'SUBJECT_NOT_TAUGHT')],
    setFailure: (failure) => when(() => bloc.state).thenReturn(EntryFormEditing(options, failure: failure)),
    form: () => BlocProvider<EntryFormBloc>.value(
      value: bloc,
      child: const EntryFormView(entry: mathsMonday),
    ),
  );

  group('before the form is ready', () {
    testWidgets('shows a placeholder while it reads, with no Save', (tester) async {
      await pump(tester, const EntryFormLoading());
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('says why it could not read, and reads again on Try again', (tester) async {
      await pump(tester, EntryFormLoadFailed(_failure(422, 'CURRENT_YEAR_REQUIRED')));
      expect(find.byKey(const Key('entryForm.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const EntryFormStarted())).called(1);
    });

    testWidgets('says plainly when the person may not build the timetable', (tester) async {
      await pump(tester, EntryFormLoadFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('entryForm.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('sends the person to Period timings when the Institution has no periods', (tester) async {
      await pump(tester, const EntryFormEditing(EntryOptions(slots: [], subjects: [maths], teachers: [kavya])));
      expect(find.text('No periods yet'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });
  });

  testWidgets('closes with true and says so once saved', (tester) async {
    whenListen(
      bloc,
      Stream.value(const EntryFormSaved(mathsMonday)),
      initialState: const EntryFormEditing(options, saving: true),
    );
    bool? closedWith;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => closedWith = await context.push<bool>('/form'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/form',
          builder: (_, _) => BlocProvider<EntryFormBloc>.value(value: bloc, child: const EntryFormView()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(closedWith, isTrue);
    expect(find.text('Entry saved'), findsOneWidget);
  });

  for (final entry in [null, mathsMonday]) {
    testWidgets('reads whole at a large text scale on a small phone, ${entry == null ? 'to add' : 'to edit'}', (
      tester,
    ) async {
      await pump(
        tester,
        EntryFormEditing(options, failure: _failure(409, 'SECTION_SLOT_TAKEN')),
        entry: entry,
        textScale: 2,
        size: const Size(320, 2400),
      );
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    });
  }
}
