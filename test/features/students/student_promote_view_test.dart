import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/promotion_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_promote_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockPromotionBloc extends MockBloc<PromotionEvent, PromotionState> implements PromotionBloc;

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

const _nextYear = AcademicYear(
  id: 'y2',
  institutionId: 'i1',
  name: '2027-2028',
  startDate: '2027-06-01',
  endDate: '2028-03-31',
  isCurrent: false,
  version: 1,
);

const _classes = [
  ClassChoice(id: 'k1', name: 'Class 1'),
  ClassChoice(id: 'k2', name: 'Class 2'),
];
const _sections = [
  SectionChoice(id: 'e1', name: 'Class 1 · Section A', classId: 'k1'),
  SectionChoice(id: 'e2', name: 'Class 1 · Blue', classId: 'k1'),
  SectionChoice(id: 'e3', name: 'Class 2 · Section A', classId: 'k2'),
];

/// One student, aimed at Class 2 of the next year, no section chosen yet.
const _one = PromotionReady(
  years: [earlierYear, currentYear, _nextYear],
  classes: _classes,
  sections: _sections,
  sourceYearId: 'y1',
  sourceClassId: 'k1',
  sourceSectionId: 'e1',
  targetYearId: 'y2',
  targetClassId: 'k2',
);

/// A class, aimed the same way, every section of it.
const _group = PromotionReady(
  years: [earlierYear, currentYear, _nextYear],
  classes: _classes,
  sections: _sections,
  sourceYearId: 'y1',
  sourceClassId: 'k1',
  targetYearId: 'y2',
  targetClassId: 'k2',
);

ApiFailure _failure(int status, String code, {List<FieldError> fields = const []}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words', fieldErrors: fields);

void main() {
  late _MockPromotionBloc bloc;

  setUpAll(() => registerFallbackValue(const PromotionStarted()));
  setUp(() => bloc = _MockPromotionBloc());

  Future<void> pump(
    WidgetTester tester,
    PromotionState state, {
    StudentListEntry? entry,
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<PromotionBloc>.value(
        value: bloc,
        child: StudentPromoteView(entry: entry),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder promoteButton() => find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));
  Finder field(String key) => find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

  Future<void> choose(WidgetTester tester, String fieldKey, String option) async {
    await tester.tap(find.byKey(Key(fieldKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  group('before the choices are ready', () {
    testWidgets('shows a placeholder while they load', (tester) async {
      await pump(tester, const PromotionLoading());
      expect(find.byKey(const Key('promotion.failed')), findsNothing);
      expect(find.text('Promote a class'), findsOneWidget);
    });

    testWidgets('says why they could not be read, and starts again on Try again', (tester) async {
      await pump(tester, PromotionFailed(_failure(503, 'UNAVAILABLE')));
      expect(find.byKey(const Key('promotion.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const PromotionStarted())).called(1);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, PromotionFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('promotion.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('one student', () {
    testWidgets('says where they are now, and has no place to choose where they come from', (tester) async {
      await pump(tester, _one, entry: _entry);
      expect(find.text('Promote student'), findsOneWidget);
      expect(find.text('Asha Rao'), findsOneWidget);
      expect(find.text('Class 1 · Section A · Roll 14'), findsOneWidget);
      expect(find.byKey(const Key('promotion.sourceClass')), findsNothing);
      expect(find.byKey(const Key('promotion.keepRollNumbers')), findsNothing);
      expect(tester.widget<TextField>(field('promotion.rollNumber')).controller!.text, '14');
    });

    testWidgets('cannot be promoted until a section is chosen', (tester) async {
      await pump(tester, _one, entry: _entry);
      expect(tester.widget<FilledButton>(promoteButton()).onPressed, isNull);
    });

    testWidgets('can be promoted once a section is chosen', (tester) async {
      await pump(tester, _one.copyWith(targetSectionId: () => 'e3'), entry: _entry);
      expect(tester.widget<FilledButton>(promoteButton()).onPressed, isNotNull);
    });

    testWidgets('offers the years after theirs and the sections of the class chosen', (tester) async {
      await pump(tester, _one, entry: _entry);
      await tester.tap(find.byKey(const Key('promotion.targetYear')));
      await tester.pumpAndSettle();
      expect(find.text('2027-2028'), findsWidgets);
      expect(find.text('2025-2026'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('promotion.targetSection')));
      await tester.pumpAndSettle();
      expect(find.text('Class 2 · Section A'), findsWidgets);
      expect(find.text('Class 1 · Blue'), findsNothing);
    });

    testWidgets('tells the bloc of each choice', (tester) async {
      await pump(tester, _one, entry: _entry);
      await choose(tester, 'promotion.targetSection', 'Class 2 · Section A');
      verify(() => bloc.add(const PromotionTargetSectionChosen('e3'))).called(1);
      await choose(tester, 'promotion.targetClass', 'Class 1');
      verify(() => bloc.add(const PromotionTargetClassChosen('k1'))).called(1);
    });

    testWidgets('is promoted at once, with the roll number as it stands, without a question', (tester) async {
      await pump(tester, _one.copyWith(targetSectionId: () => 'e3'), entry: _entry);
      await tester.enterText(field('promotion.rollNumber'), '20');
      await tester.tap(promoteButton());
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      verify(() => bloc.add(const PromotionSubmitted(rollNumber: '20'))).called(1);
    });

    testWidgets('is asked about in red before completing the final class, and sent only once confirmed', (
      tester,
    ) async {
      await pump(tester, _one.copyWith(completes: true), entry: _entry);
      expect(find.byKey(const Key('promotion.targetClass')), findsNothing);
      expect(find.byKey(const Key('promotion.rollNumber')), findsNothing);
      await tester.tap(promoteButton());
      await tester.pumpAndSettle();
      expect(find.text('Complete the final class?'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<PromotionSubmitted>())));
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.danger);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Promote')));
      await tester.pumpAndSettle();
      // The roll number is the form's own, which the bloc leaves out for a student who completes.
      verify(() => bloc.add(const PromotionSubmitted(rollNumber: '14'))).called(1);
    });

    testWidgets('is left as it is when the question is cancelled', (tester) async {
      await pump(tester, _one.copyWith(completes: true), entry: _entry);
      await tester.tap(promoteButton());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<PromotionSubmitted>())));
    });
  });

  group('a class', () {
    testWidgets('chooses where the students are now, every section of the class to begin with', (tester) async {
      await pump(tester, _group);
      expect(find.text('Promote from'), findsOneWidget);
      expect(find.byKey(const Key('promotion.sourceYear')), findsOneWidget);
      expect(find.byKey(const Key('promotion.sourceClass')), findsOneWidget);
      expect(find.text('Every section'), findsOneWidget);
      expect(find.byKey(const Key('promotion.rollNumber')), findsNothing);
      expect(tester.widget<AppSwitchTile>(find.byKey(const Key('promotion.keepRollNumbers'))).value, isTrue);
    });

    testWidgets('tells the bloc of each choice of source, of none for every section', (tester) async {
      await pump(tester, _group.copyWith(sourceSectionId: () => 'e1'));
      await choose(tester, 'promotion.sourceSection', 'Every section');
      verify(() => bloc.add(const PromotionSourceSectionChosen(null))).called(1);
      await choose(tester, 'promotion.sourceClass', 'Class 2');
      verify(() => bloc.add(const PromotionSourceClassChosen('k2'))).called(1);
      await choose(tester, 'promotion.sourceYear', '2025-2026');
      verify(() => bloc.add(const PromotionSourceYearChosen('y0'))).called(1);
    });

    testWidgets('tells the bloc to number the students again', (tester) async {
      await pump(tester, _group);
      await tester.tap(find.byKey(const Key('promotion.keepRollNumbers')));
      verify(() => bloc.add(const PromotionKeepRollNumbersToggled(value: false))).called(1);
    });

    testWidgets('is asked about first, with the target named, and sent only once confirmed', (tester) async {
      await pump(tester, _group.copyWith(targetSectionId: () => 'e3'));
      await tester.tap(promoteButton());
      await tester.pumpAndSettle();
      expect(find.text('Promote to Class 2 · Section A?'), findsOneWidget);
      expect(find.textContaining('all or none'), findsOneWidget);
      verifyNever(() => bloc.add(any(that: isA<PromotionSubmitted>())));
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.primary);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Promote')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const PromotionSubmitted())).called(1);
    });

    testWidgets('completes the final class, with a warning that it deactivates them', (tester) async {
      await pump(tester, _group.copyWith(completes: true));
      expect(find.byKey(const Key('promotion.targetClass')), findsNothing);
      expect(find.byKey(const Key('promotion.keepRollNumbers')), findsNothing);
      expect(find.textContaining('deactivated as completed'), findsOneWidget);
      await tester.tap(find.byKey(const Key('promotion.completes')));
      verify(() => bloc.add(const PromotionCompletesToggled(value: false))).called(1);
    });
  });

  group('a refusal', () {
    testWidgets('is said above the form, in words of the code', (tester) async {
      await pump(
        tester,
        _group.copyWith(failure: () => _failure(422, 'TARGET_CLASS_BELOW_SOURCE')),
      );
      expect(find.byKey(const Key('promotion.error')), findsOneWidget);
      expect(
        find.text('Students cannot go to a class below the one they are in. Choose the same class to repeat it.'),
        findsOneWidget,
      );
      expect(find.text('server words'), findsNothing);
    });

    testWidgets('that names only the fields of the form is said under them', (tester) async {
      await pump(
        tester,
        _one.copyWith(
          failure: () => _failure(
            422,
            'VALIDATION_FAILED',
            fields: const [FieldError(field: 'rollNumber', code: 'TOO_LONG', message: 'Too long')],
          ),
        ),
        entry: _entry,
      );
      expect(find.byKey(const Key('promotion.error')), findsNothing);
      expect(find.text('Too long'), findsOneWidget);
    });

    testWidgets('a taken roll number is said above the form', (tester) async {
      await pump(tester, _one.copyWith(failure: () => _failure(409, 'ROLL_NUMBER_TAKEN')), entry: _entry);
      expect(find.text('Another student in this section has this roll number.'), findsOneWidget);
    });
  });

  testWidgets('shows progress while it works, and offers nothing else meanwhile', (tester) async {
    await pump(tester, _group.copyWith(targetSectionId: () => 'e3', saving: true));
    expect(tester.widget<FilledButton>(promoteButton()).onPressed, isNull);
    expect(tester.widget<AppSwitchTile>(find.byKey(const Key('promotion.completes'))).onChanged, isNull);
    expect(tester.widget<AppSwitchTile>(find.byKey(const Key('promotion.keepRollNumbers'))).onChanged, isNull);
  });

  group('once it went through', () {
    testWidgets('says where one student went, and any section over its capacity', (tester) async {
      await pump(
        tester,
        const PromotionDone(
          PromotionResult(promotedCount: 1, warnings: ['SECTION_OVER_CAPACITY']),
          targetName: 'Class 2 · Section A',
        ),
        entry: _entry,
      );
      expect(find.text('Asha Rao promoted to Class 2 · Section A'), findsOneWidget);
      expect(find.text('The section is now over its capacity.'), findsOneWidget);
    });

    testWidgets('says one student completed the final class', (tester) async {
      await pump(tester, const PromotionDone(PromotionResult(promotedCount: 1)), entry: _entry);
      expect(find.text('Asha Rao completed the final class'), findsOneWidget);
    });

    testWidgets('counts a class, and says how many were left and why', (tester) async {
      await pump(
        tester,
        const PromotionDone(
          PromotionResult(
            promotedCount: 12,
            skipped: [SkipReason.alreadyEnrolled, SkipReason.alreadyEnrolled, SkipReason.notInSource],
          ),
          targetName: 'Class 2 · Section A',
        ),
      );
      expect(find.text('12 students promoted to Class 2 · Section A'), findsOneWidget);
      expect(
        find.text('2 students already have a place in the new year, and were left where they are.'),
        findsOneWidget,
      );
      expect(find.text('1 student is not an active student of this class or section, and was left.'), findsOneWidget);
    });

    testWidgets('counts a class that completed', (tester) async {
      await pump(tester, const PromotionDone(PromotionResult(promotedCount: 30)));
      expect(find.text('30 students completed the final class'), findsOneWidget);
    });

    testWidgets('says when there was nobody to promote', (tester) async {
      await pump(tester, const PromotionDone(PromotionResult(promotedCount: 0), targetName: 'Class 2 · Section A'));
      expect(find.text('No student was promoted'), findsOneWidget);
    });

    testWidgets('closes with true, so the list behind it reads again', (tester) async {
      when(() => bloc.state).thenReturn(const PromotionDone(PromotionResult(promotedCount: 3), targetName: 'Class 2'));
      bool? result;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await context.push<bool>('/promote'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/promote',
            builder: (_, _) =>
                BlocProvider<PromotionBloc>.value(value: bloc, child: const StudentPromoteView(entry: null)),
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
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, _group.copyWith(targetSectionId: () => 'e3'), textScale: 2, size: const Size(320, 3000));
    expect(tester.takeException(), isNull);
    // A year such as "2026-2027" is wider than the field at this size, so it cannot fit any box here.
    expect(clippedParagraphs(tester, unbreakable: 196), isEmpty);
  });
}
