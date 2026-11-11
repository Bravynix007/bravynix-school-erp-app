import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/section_options.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_teaching_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_teaching_section.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/subjects.dart';
import '../../helpers/teaching_assignments.dart';

class _MockBloc extends MockBloc<StaffTeachingEvent, StaffTeachingState> implements StaffTeachingBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late _MockBloc bloc;

  setUpAll(() => registerFallbackValue(const StaffTeachingStarted()));
  setUp(() => bloc = _MockBloc());

  const sections = [
    SectionChoice(id: 'e1', name: 'Class 1 · Section A'),
    SectionChoice(id: 'e2', name: 'Class 1 · Blue'),
  ];

  StaffTeachingReady ready({
    List<SectionChoice> sectionChoices = sections,
    List<Subject> subjects = const [maths],
    List<TeachingAssignment> assignments = const [mathsInClass1A],
    String? sectionId,
    String? subjectId,
    bool reading = false,
    bool adding = false,
    String? ending,
    ApiFailure? failure,
  }) => StaffTeachingReady(
    years: const [currentYear, earlierYear],
    sections: sectionChoices,
    subjects: subjects,
    yearId: 'y1',
    assignments: assignments,
    sectionId: sectionId,
    subjectId: subjectId,
    reading: reading,
    adding: adding,
    ending: ending,
    failure: failure,
  );

  Future<void> pump(
    WidgetTester tester,
    StaffTeachingState state, {
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StaffTeachingBloc>.value(
        value: bloc,
        child: const Scaffold(body: SingleChildScrollView(child: StaffTeachingSection())),
      ),
      textScale: textScale,
      size: size,
    );
  }

  AppButton assign(WidgetTester tester) => tester.widget<AppButton>(find.byKey(const Key('staffTeaching.assign')));

  group('what they teach', () {
    testWidgets('lists the subject and the section of each assignment, for the year', (tester) async {
      await pump(tester, ready(assignments: const [mathsInClass1A, mathsInClass1Blue]));
      expect(find.text('Teaching'), findsOneWidget);
      expect(find.text('2026-2027'), findsOneWidget);
      expect(find.text('Mathematics'), findsNWidgets(2));
      expect(find.text('Class 1 · Section A'), findsOneWidget);
      expect(find.text('Class 1 · Blue'), findsOneWidget);
      expect(find.byKey(const Key('staffTeaching.none')), findsNothing);
    });

    testWidgets('says so when they teach in no section that year', (tester) async {
      await pump(tester, ready(assignments: const []));
      expect(find.text('They do not teach in any section this year.'), findsOneWidget);
    });

    testWidgets('shows a placeholder, and no list, while another year is read', (tester) async {
      await pump(tester, ready(reading: true));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('Mathematics'), findsNothing);
    });

    testWidgets('says there is no year to choose when the Institution has none', (tester) async {
      await pump(
        tester,
        const StaffTeachingReady(years: [], sections: sections, subjects: [maths], yearId: null, assignments: []),
      );
      expect(find.text('Add an academic year under School setup first.'), findsOneWidget);
      expect(find.byKey(const Key('staffTeaching.assign')), findsNothing);
    });

    testWidgets('tells the bloc the year chosen', (tester) async {
      await pump(tester, ready());
      await tester.tap(find.byKey(const Key('staffTeaching.year')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025-2026').last);
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffTeachingYearChosen('y0'))).called(1);
    });
  });

  group('ending an assignment', () {
    testWidgets('is asked in red, and sent only once the person confirms', (tester) async {
      await pump(tester, ready());
      await tester.tap(find.byKey(const Key('staffTeaching.end.g1')));
      await tester.pumpAndSettle();
      expect(find.text('End Mathematics in Class 1 · Section A?'), findsOneWidget);
      expect(find.text('They stop teaching it. The record stays as history.'), findsOneWidget);
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.danger);
      verifyNever(() => bloc.add(any()));
      await tester.tap(find.text('End assignment'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffTeachingEnded('g1'))).called(1);
    });

    testWidgets('is left as it is when the person cancels', (tester) async {
      await pump(tester, ready());
      await tester.tap(find.byKey(const Key('staffTeaching.end.g1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('shows progress on the one that is on its way, and offers no other while it is', (tester) async {
      await pump(tester, ready(assignments: const [mathsInClass1A, mathsInClass1Blue], ending: 'g1'));
      expect(tester.widget<AppButton>(find.byKey(const Key('staffTeaching.end.g1'))).loading, isTrue);
      expect(tester.widget<AppButton>(find.byKey(const Key('staffTeaching.end.g2'))).onPressed, isNull);
    });
  });

  group('assigning', () {
    testWidgets('offers the sections, and the subjects of their list', (tester) async {
      await pump(tester, ready());
      await tester.tap(find.byKey(const Key('staffTeaching.section')));
      await tester.pumpAndSettle();
      expect(find.text('Class 1 · Blue'), findsOneWidget);
      await tester.tap(find.text('Class 1 · Blue'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffTeachingSectionChosen('e2'))).called(1);
      await tester.tap(find.byKey(const Key('staffTeaching.subject')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mathematics').last);
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffTeachingSubjectChosen('u1'))).called(1);
    });

    testWidgets('is offered once a section and a subject are chosen, and sends them', (tester) async {
      await pump(tester, ready(sectionId: 'e2', subjectId: 'u1'));
      expect(assign(tester).onPressed, isNotNull);
      await tester.tap(find.text('Assign'));
      verify(() => bloc.add(const StaffTeachingAdded())).called(1);
    });

    testWidgets('is not offered while the choice is not complete', (tester) async {
      await pump(tester, ready(sectionId: 'e2'));
      expect(assign(tester).onPressed, isNull);
    });

    testWidgets('shows progress, and leaves the fields as they are, while it is on its way', (tester) async {
      await pump(tester, ready(assignments: const [], sectionId: 'e2', subjectId: 'u1', adding: true));
      expect(assign(tester).loading, isTrue);
      expect(assign(tester).onPressed, isNull);
      await tester.tap(find.byKey(const Key('staffTeaching.section')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Class 1 · Section A'), findsNothing);
    });

    testWidgets('says to add subjects first when their list is empty, and offers nothing to choose', (tester) async {
      await pump(tester, ready(subjects: const []));
      expect(find.text('Add subjects to their list above and save, then give them a section.'), findsOneWidget);
      expect(find.byKey(const Key('staffTeaching.assign')), findsNothing);
    });

    testWidgets('says to add a section first when the Institution has none', (tester) async {
      await pump(tester, ready(sectionChoices: const []));
      expect(find.text('Add a class with a section under School setup first.'), findsOneWidget);
      expect(find.byKey(const Key('staffTeaching.assign')), findsNothing);
    });
  });

  group('a refusal', () {
    for (final (failure, words) in [
      (_failure(409, 'DUPLICATE'), 'They already teach this subject in this section this year.'),
      (
        _failure(422, 'SUBJECT_NOT_TAUGHT'),
        'This subject is not on their list. Add it to their subjects and save first.',
      ),
      (_failure(422, 'STAFF_BLOCKED'), 'They are blocked. Unblock them under Settings first.'),
      (_failure(422, 'REFERENCE_INACTIVE'), 'Something you chose is no longer available. Choose again.'),
      (
        _failure(404, 'NOT_FOUND'),
        'The assignment, the section or the subject could not be found. It may have been ended or deactivated.',
      ),
      (const ApiFailure.network(), "Can't reach the server. Check your connection and try again."),
    ]) {
      testWidgets('says ${failure.code} in words', (tester) async {
        await pump(tester, ready(sectionId: 'e2', subjectId: 'u1', failure: failure));
        expect(find.byKey(const Key('staffTeaching.error')), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.text('server words'), findsNothing);
      });
    }

    testWidgets('is shown when there is nothing to choose, as an end can be refused too', (tester) async {
      await pump(tester, ready(subjects: const [], failure: _failure(404, 'NOT_FOUND')));
      expect(find.byKey(const Key('staffTeaching.error')), findsOneWidget);
    });
  });

  group('once an assignment is made or ended', () {
    testWidgets('says that it was made', (tester) async {
      whenListen(
        bloc,
        Stream.value(ready().copyWith(done: () => const StaffTeachingChange(mathsInClass1Blue, ended: false))),
        initialState: ready(adding: true),
      );
      await pump(tester, ready(adding: true));
      await tester.pump();
      expect(find.text('Mathematics in Class 1 · Blue assigned'), findsOneWidget);
    });

    testWidgets('says that it was ended', (tester) async {
      whenListen(
        bloc,
        Stream.value(ready().copyWith(done: () => const StaffTeachingChange(mathsInClass1A, ended: true))),
        initialState: ready(ending: 'g1'),
      );
      await pump(tester, ready(ending: 'g1'));
      await tester.pump();
      expect(find.text('Mathematics in Class 1 · Section A ended'), findsOneWidget);
    });

    testWidgets('says nothing of a refusal', (tester) async {
      whenListen(
        bloc,
        Stream.value(ready(failure: _failure(409, 'DUPLICATE'))),
        initialState: ready(adding: true),
      );
      await pump(tester, ready(adding: true));
      await tester.pump();
      expect(find.textContaining('assigned'), findsNothing);
    });
  });

  group('before it is ready', () {
    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const StaffTeachingLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('Teaching'), findsOneWidget);
    });

    testWidgets('says why it could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StaffTeachingFailed(ApiFailure.network()));
      expect(find.byKey(const Key('staffTeaching.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StaffTeachingStarted())).called(1);
    });
  });

  testWidgets('reads whole at a large text scale', (tester) async {
    await pump(
      tester,
      ready(
        assignments: const [mathsInClass1A, mathsInClass1Blue],
        failure: _failure(422, 'SUBJECT_NOT_TAUGHT'),
      ),
      textScale: 2,
      size: const Size(400, 4000),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 400 - 4 * 16), isEmpty);
  });
}
