import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_move_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_move_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockMoveBloc extends MockBloc<StudentMoveEvent, StudentMoveState> implements StudentMoveBloc;

const _asha = StudentSummary(
  id: 'p1',
  institutionId: 'i1',
  firstName: 'Asha',
  lastName: 'Rao',
  placement: StudentPlacement(
    academicYearId: 'y1',
    classId: 'k1',
    sectionId: 'e1',
    rollNumber: '14',
    startDate: '2026-06-01',
  ),
  isBlocked: false,
  version: 1,
);

const _entry = StudentListEntry(_asha, placeName: 'Class 1 · Section A');

const _ready = StudentMoveReady(
  sections: [
    SectionChoice(id: 'e1', name: 'Section A', classId: 'k1'),
    SectionChoice(id: 'e2', name: 'Blue', classId: 'k1'),
  ],
  sectionId: 'e1',
);

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockMoveBloc bloc;

  setUpAll(() {
    registerFallbackValue(const StudentMoveStarted());
  });
  setUp(() {
    bloc = _MockMoveBloc();
  });

  Future<void> pump(
    WidgetTester tester,
    StudentMoveState state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StudentMoveBloc>.value(
        value: bloc,
        child: const StudentMoveView(entry: _entry),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));
  Finder saveButton() => find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));

  Future<void> choose(WidgetTester tester, String fieldKey, String option) async {
    await tester.tap(find.byKey(Key(fieldKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('says where the student is now, and starts with the roll number and section they have', (tester) async {
    await pump(tester, _ready);
    expect(find.text('Move student'), findsOneWidget);
    expect(
      find.text(
        'The first day in the new section or with the new roll number. Today when left empty, or the first day of the '
        'placement when that comes later.',
      ),
      findsOneWidget,
    );
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Class 1 · Section A · Roll 14 · since 01-06-2026'), findsOneWidget);
    expect(tester.widget<TextField>(field('studentMove.rollNumber')).controller!.text, '14');
    expect(find.text('Section A'), findsWidgets);
  });

  group('the day', () {
    String day(DateTime date) =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    /// The limits of the calendar the From field opens for a placement that began [begunDaysAgo] days ago (a negative
    /// number: it begins that many days from today).
    Future<({DateTime first, DateTime last})> limits(WidgetTester tester, int begunDaysAgo) async {
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day - begunDaysAgo);
      final summary = StudentSummary(
        id: 'p1',
        institutionId: 'i1',
        firstName: 'Asha',
        placement: StudentPlacement(
          academicYearId: 'y1',
          classId: 'k1',
          sectionId: 'e1',
          rollNumber: '14',
          startDate: day(start),
        ),
        isBlocked: false,
        version: 1,
      );
      when(() => bloc.state).thenReturn(_ready);
      await tester.pumpAppScaled(
        BlocProvider<StudentMoveBloc>.value(
          value: bloc,
          child: StudentMoveView(entry: StudentListEntry(summary)),
        ),
        size: const Size(400, 1200),
      );
      await tester.tap(find.byKey(const Key('studentMove.effectiveDate')));
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarDatePicker>(find.byType(CalendarDatePicker));
      return (first: calendar.firstDate, last: calendar.lastDate);
    }

    testWidgets('can be any day from the one the placement began to today', (tester) async {
      final today = DateTime.now();
      final (:first, :last) = await limits(tester, 10);
      expect(first, DateTime(today.year, today.month, today.day - 10));
      expect(last, DateTime(today.year, today.month, today.day));
    });

    testWidgets('can only be the first day of a placement that begins later', (tester) async {
      final today = DateTime.now();
      final (:first, :last) = await limits(tester, -60);
      expect(tester.takeException(), isNull);
      expect(first, DateTime(today.year, today.month, today.day + 60));
      expect(last, first);
    });
  });

  group('Save', () {
    testWidgets('waits until something is changed', (tester) async {
      await pump(tester, _ready);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
    });

    testWidgets('is offered once the roll number is changed, and sends it as typed', (tester) async {
      await pump(tester, _ready);
      await tester.enterText(field('studentMove.rollNumber'), '15');
      await tester.pump();
      await tester.tap(find.text('Save'));
      verify(() => bloc.add(const StudentMoveSubmitted('15'))).called(1);
    });

    testWidgets('is offered once another section is chosen', (tester) async {
      await pump(tester, _ready.copyWith(sectionId: 'e2'));
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    testWidgets('waits when the roll number is emptied', (tester) async {
      await pump(tester, _ready.copyWith(sectionId: 'e2'));
      await tester.enterText(field('studentMove.rollNumber'), '  ');
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
    });

    testWidgets('waits when the roll number is typed back as it was, with spaces', (tester) async {
      await pump(tester, _ready);
      await tester.enterText(field('studentMove.rollNumber'), ' 14 ');
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);
    });

    testWidgets('does not send twice while saving', (tester) async {
      await pump(tester, _ready.copyWith(sectionId: 'e2', saving: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(saveButton());
      verifyNever(() => bloc.add(any(that: isA<StudentMoveSubmitted>())));
    });
  });

  group('choosing', () {
    testWidgets('tells the bloc the section chosen', (tester) async {
      await pump(tester, _ready);
      await choose(tester, 'studentMove.section', 'Blue');
      verify(() => bloc.add(const StudentMoveSectionChosen('e2'))).called(1);
    });

    testWidgets('tells the bloc the day chosen', (tester) async {
      await pump(tester, _ready);
      await tester.tap(find.byKey(const Key('studentMove.effectiveDate')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(any(that: isA<StudentMoveDateChosen>()))).called(1);
    });

    testWidgets('offers to clear a day once there is one', (tester) async {
      await pump(tester, _ready.copyWith(effectiveDate: () => '2026-07-01'));
      await tester.tap(find.byTooltip('Clear From'));
      verify(() => bloc.add(const StudentMoveDateChosen(null))).called(1);
    });
  });

  group('refused', () {
    testWidgets('shows an error under the field the API names, and no banner', (tester) async {
      await pump(
        tester,
        _ready.copyWith(
          failure: () => _failure(
            400,
            'INVALID_VALUE',
            fields: const [FieldError(field: 'effectiveDate', code: 'INVALID_VALUE', message: 'Not that day')],
          ),
        ),
      );
      expect(find.text('Not that day'), findsOneWidget);
      expect(find.byKey(const Key('studentMove.error')), findsNothing);
    });

    testWidgets('shows an error under the section and under the roll number when the API names them', (tester) async {
      await pump(
        tester,
        _ready.copyWith(
          failure: () => _failure(
            422,
            'SECTION_NOT_IN_CLASS',
            fields: const [
              FieldError(field: 'sectionId', code: 'SECTION_NOT_IN_CLASS', message: 'Not of this class'),
              FieldError(field: 'rollNumber', code: 'INVALID_VALUE', message: 'Not a roll number'),
            ],
          ),
        ),
      );
      expect(
        find.descendant(of: find.byKey(const Key('studentMove.section')), matching: find.text('Not of this class')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(const Key('studentMove.rollNumber')), matching: find.text('Not a roll number')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('studentMove.error')), findsNothing);
    });

    testWidgets("says the student could not be found, not the form's Institution, class or photo", (tester) async {
      await pump(tester, _ready.copyWith(failure: () => _failure(404, 'NOT_FOUND')));
      expect(
        find.descendant(
          of: find.byKey(const Key('studentMove.error')),
          matching: find.text('This student could not be found. They may have been deactivated.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says a taken roll number above the form', (tester) async {
      await pump(tester, _ready.copyWith(failure: () => _failure(409, 'ROLL_NUMBER_TAKEN')));
      expect(
        find.descendant(
          of: find.byKey(const Key('studentMove.error')),
          matching: find.text('Another student in this section has this roll number.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says a deactivated section above the form', (tester) async {
      await pump(tester, _ready.copyWith(failure: () => _failure(422, 'INACTIVE_SECTION')));
      expect(find.text('This section is deactivated.'), findsOneWidget);
    });
  });

  group('before the form is ready', () {
    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const StudentMoveLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('Move student'), findsOneWidget);
    });

    testWidgets('says why it could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StudentMoveFailed(ApiFailure.network()));
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StudentMoveStarted())).called(1);
      expect(find.text('Move student'), findsOneWidget);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, StudentMoveFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('studentMove.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Move student'), findsOneWidget);
    });
  });

  group('once saved', () {
    Future<bool?> saveWith(WidgetTester tester, List<String> warnings) async {
      whenListen(bloc, Stream.value(StudentMoveSaved(warnings)), initialState: _ready);
      bool? result;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await context.push<bool>('/move'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/move',
            builder: (_, _) => BlocProvider<StudentMoveBloc>.value(
              value: bloc,
              child: const StudentMoveView(entry: _entry),
            ),
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
      return result;
    }

    testWidgets('closes with a message and tells the list behind it', (tester) async {
      final result = await saveWith(tester, []);
      expect(result, isTrue);
      expect(find.text("Asha Rao's placement was changed."), findsOneWidget);
    });

    testWidgets('adds a line for a section over its capacity', (tester) async {
      await saveWith(tester, ['SECTION_OVER_CAPACITY']);
      expect(find.text("Asha Rao's placement was changed. The section is now over its capacity."), findsOneWidget);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, _ready.copyWith(sectionId: 'e2'), textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    // "Choose" (the hint of an empty date field) is wider than the field at this size, so it cannot fit any box here.
    expect(clippedParagraphs(tester, unbreakable: 184), isEmpty);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
