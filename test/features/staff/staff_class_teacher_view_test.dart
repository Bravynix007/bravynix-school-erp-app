import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_class_teacher_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_class_teacher_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockBloc extends MockBloc<StaffClassTeacherEvent, StaffClassTeacherState> implements StaffClassTeacherBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late _MockBloc bloc;

  setUpAll(() => registerFallbackValue(const StaffClassTeacherStarted()));
  setUp(() => bloc = _MockBloc());

  const sections = [
    SectionChoice(id: 'e1', name: 'Class 1 · Section A', classId: 'k1'),
    SectionChoice(id: 'e2', name: 'Class 1 · Blue', classId: 'k1'),
  ];

  StaffClassTeacherReady ready({
    String? yearId = 'y1',
    String? sectionId = 'e1',
    Map<String, String> assigned = const {'y1': 'e1'},
    bool saving = false,
    ApiFailure? failure,
  }) => StaffClassTeacherReady(
    years: const [currentYear, earlierYear],
    sections: sections,
    assigned: assigned,
    yearId: yearId,
    sectionId: sectionId,
    saving: saving,
    failure: failure,
  );

  Future<void> pump(
    WidgetTester tester,
    StaffClassTeacherState state, {
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StaffClassTeacherBloc>.value(
        value: bloc,
        child: const Scaffold(body: SingleChildScrollView(child: StaffClassTeacherSection())),
      ),
      textScale: textScale,
      size: size,
    );
  }

  AppButton save(WidgetTester tester) => tester.widget<AppButton>(find.byKey(const Key('staffClassTeacher.save')));

  group('the fields', () {
    testWidgets('show the year and the section the person leads in it', (tester) async {
      await pump(tester, ready());
      expect(find.text('Class teacher'), findsOneWidget);
      expect(find.text('2026-2027'), findsOneWidget);
      expect(find.text('Class 1 · Section A'), findsOneWidget);
      expect(find.text('No section'), findsNothing);
    });

    testWidgets('show no section for a year they lead none in', (tester) async {
      await pump(tester, ready(sectionId: null, assigned: const {}));
      expect(find.text('Class 1 · Section A'), findsNothing);
    });

    testWidgets('mark a section that is no longer offered, and keep it chosen', (tester) async {
      await pump(tester, ready(sectionId: 'gone', assigned: const {'y1': 'gone'}));
      expect(find.text('No longer offered (kept)'), findsOneWidget);
    });

    testWidgets('say there is no year to choose when the Institution has none', (tester) async {
      await pump(
        tester,
        const StaffClassTeacherReady(years: [], sections: sections, assigned: {}, yearId: null, sectionId: null),
      );
      expect(find.byKey(const Key('staffClassTeacher.empty')), findsOneWidget);
      expect(find.text('Add an academic year under School setup first.'), findsOneWidget);
      expect(find.byKey(const Key('staffClassTeacher.save')), findsNothing);
    });

    testWidgets('tell the bloc the section chosen, and the year', (tester) async {
      await pump(tester, ready());
      await tester.tap(find.byKey(const Key('staffClassTeacher.section')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class 1 · Blue').last);
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffClassTeacherSectionChosen('e2'))).called(1);
      await tester.tap(find.byKey(const Key('staffClassTeacher.section')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No section').last);
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffClassTeacherSectionChosen(null))).called(1);
      await tester.tap(find.byKey(const Key('staffClassTeacher.year')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025-2026').last);
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffClassTeacherYearChosen('y0'))).called(1);
    });
  });

  group('saving', () {
    testWidgets('is offered once the section differs from the one they lead, and sends it', (tester) async {
      await pump(tester, ready(sectionId: 'e2'));
      expect(save(tester).onPressed, isNotNull);
      await tester.tap(find.text('Save class teacher'));
      verify(() => bloc.add(const StaffClassTeacherSaved())).called(1);
    });

    testWidgets('is not offered while nothing is changed', (tester) async {
      await pump(tester, ready());
      expect(save(tester).onPressed, isNull);
    });

    testWidgets('shows progress, and leaves the fields as they are, while it is on its way', (tester) async {
      await pump(tester, ready(sectionId: 'e2', saving: true));
      expect(save(tester).loading, isTrue);
      expect(save(tester).onPressed, isNull);
      await tester.tap(find.byKey(const Key('staffClassTeacher.section')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Class 1 · Section A'), findsNothing);
    });

    for (final (failure, words) in [
      (
        _failure(409, 'CLASS_TEACHER_TAKEN'),
        'Another teacher is already the class teacher of this section for this year.',
      ),
      (_failure(422, 'STAFF_BLOCKED'), 'They are blocked. Unblock them under Settings first.'),
      (_failure(422, 'REFERENCE_INACTIVE'), 'Something you chose is no longer available. Choose again.'),
      (
        _failure(404, 'NOT_FOUND'),
        'The staff member, the year or the section could not be found. It may have been deactivated.',
      ),
      (const ApiFailure.network(), "Can't reach the server. Check your connection and try again."),
    ]) {
      testWidgets('says ${failure.code} beside the button', (tester) async {
        await pump(tester, ready(sectionId: 'e2', failure: failure));
        expect(find.byKey(const Key('staffClassTeacher.error')), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.text('server words'), findsNothing);
      });
    }
  });

  group('once it is saved', () {
    testWidgets('says so', (tester) async {
      final saving = ready(sectionId: 'e2', saving: true);
      whenListen(
        bloc,
        Stream.value(ready(sectionId: 'e2', assigned: const {'y1': 'e2'})),
        initialState: saving,
      );
      await pump(tester, saving);
      await tester.pump();
      expect(find.text('Class teacher saved'), findsOneWidget);
    });

    testWidgets('says nothing of a refusal', (tester) async {
      final saving = ready(sectionId: 'e2', saving: true);
      whenListen(
        bloc,
        Stream.value(ready(sectionId: 'e2', failure: _failure(409, 'CLASS_TEACHER_TAKEN'))),
        initialState: saving,
      );
      await pump(tester, saving);
      await tester.pump();
      expect(find.text('Class teacher saved'), findsNothing);
    });
  });

  group('before the fields are ready', () {
    testWidgets('shows a placeholder while they load', (tester) async {
      await pump(tester, const StaffClassTeacherLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('Class teacher'), findsOneWidget);
    });

    testWidgets('says why they could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StaffClassTeacherFailed(ApiFailure.network()));
      expect(find.byKey(const Key('staffClassTeacher.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StaffClassTeacherStarted())).called(1);
    });
  });

  testWidgets('reads whole at a large text scale', (tester) async {
    await pump(
      tester,
      ready(sectionId: null, assigned: const {}, failure: _failure(409, 'CLASS_TEACHER_TAKEN')),
      textScale: 2,
      size: const Size(320, 3000),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
