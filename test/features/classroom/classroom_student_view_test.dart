import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievements_repository.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/bloc/classroom_student_bloc.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/view/classroom_error_text.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/view/classroom_student_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/achievements.dart';
import '../../helpers/classroom.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockClassroomStudentBloc extends MockBloc<ClassroomStudentEvent, ClassroomStudentState>
    implements ClassroomStudentBloc;

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'x');

/// The teacher `t1`, who gave the silver star and not the gold one.
const _teacher = AuthSession(
  person: Person(id: 't1', email: 'asha.rao@example.com', preferredLanguage: 'en'),
  contexts: [AuthContext(role: RoleCode.teacherStaff, societyId: 's1')],
  activeContext: AuthContext(role: RoleCode.teacherStaff, societyId: 's1'),
);

void main() {
  late _MockClassroomStudentBloc bloc;
  late _MockSessionBloc session;
  late MockAchievementsRepository achievements;

  setUpAll(() => registerFallbackValue(const ClassroomStudentRequested()));
  setUp(() {
    bloc = _MockClassroomStudentBloc();
    session = _MockSessionBloc();
    achievements = MockAchievementsRepository();
    when(() => session.state).thenReturn(const SessionAuthenticated(_teacher));
    when(() => achievements.stars('p1')).thenAnswer((_) async => twoStars);
    getIt.registerSingleton<AchievementsRepository>(achievements);
  });
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, ClassroomStudentState state, {double textScale = 1}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionBloc>.value(value: session),
          BlocProvider<ClassroomStudentBloc>.value(value: bloc),
        ],
        child: const ClassroomStudentView(),
      ),
      textScale: textScale,
      size: const Size(320, 1600),
    );
  }

  testWidgets('shows a placeholder while the student loads', (tester) async {
    await pump(tester, const ClassroomStudentLoading());
    expect(find.byKey(const Key('classroomStudent.failed')), findsNothing);
  });

  testWidgets('shows who the student is and where they sit, and nothing a teacher is not given', (tester) async {
    await pump(tester, const ClassroomStudentLoaded(ashaEntry));
    await tester.pumpAndSettle();
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('Class 1 · Section A · Roll 14'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('O+'), findsOneWidget);
    expect(find.text('Admission ID'), findsNothing);
    expect(find.text('Guardians'), findsNothing);
    // Their attendance is read from here.
    expect(find.byKey(const Key('student.attendance')), findsOneWidget);
  });

  testWidgets('shows the stars, and offers to take back only the ones this teacher gave', (tester) async {
    await pump(tester, const ClassroomStudentLoaded(ashaEntry));
    await tester.pumpAndSettle();
    expect(find.text('Won the quiz'), findsOneWidget);
    expect(find.byKey(const ValueKey('stars.remove.a1')), findsOneWidget);
    expect(find.byKey(const ValueKey('stars.remove.a2')), findsNothing);
  });

  testWidgets('never offers to take back a star no person gave', (tester) async {
    when(() => achievements.stars('p1')).thenAnswer(
      (_) async => Stars(total: 1, silver: 1, gold: 0, platinum: 0, achievements: [systemStar]),
    );
    await pump(tester, const ClassroomStudentLoaded(ashaEntry));
    await tester.pumpAndSettle();
    expect(find.text('Seeded'), findsOneWidget);
    expect(find.byKey(const ValueKey('stars.remove.a3')), findsNothing);
  });

  testWidgets('says the student is not in the teacher’s sections, with no retry', (tester) async {
    await pump(tester, ClassroomStudentFailed(_failure(403, 'NOT_ASSIGNED')));
    expect(find.byKey(const Key('classroomStudent.forbidden')), findsOneWidget);
    expect(find.text('This student is not in one of your sections.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says the student could not be found', (tester) async {
    await pump(tester, ClassroomStudentFailed(_failure(404, 'NOT_FOUND')));
    expect(find.byKey(const Key('classroomStudent.notFound')), findsOneWidget);
  });

  testWidgets('says why it could not be read, and reads again on Try again', (tester) async {
    await pump(tester, ClassroomStudentFailed(_failure(503, 'UNAVAILABLE')));
    expect(find.byKey(const Key('classroomStudent.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ClassroomStudentRequested())).called(1);
  });

  testWidgets('fits a narrow phone at a large text size', (tester) async {
    await pump(tester, const ClassroomStudentLoaded(ashaEntry), textScale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 196), isEmpty);
  });

  testWidgets('classroomErrorText has its own words for a student outside the sections', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(classroomErrorText(l10n, _failure(403, 'NOT_ASSIGNED')), l10n.errorNotAssigned);
    expect(classroomErrorText(l10n, _failure(404, 'NOT_FOUND')), l10n.errorStudentProfileNotFound);
    expect(classroomErrorText(l10n, _failure(403, 'FORBIDDEN')), l10n.errorForbidden);
  });
}
