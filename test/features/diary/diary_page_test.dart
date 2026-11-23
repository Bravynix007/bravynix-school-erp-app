import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:bravynix_school_erp/features/diary/presentation/view/diary_page.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/diary.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sections.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

class _MockActiveChildBloc extends MockBloc<ActiveChildEvent, ActiveChildState> implements ActiveChildBloc;

/// Who may write and who may change an entry follows from the role, the Institution the person is at and who wrote the
/// entry (API design 10.14a), and the page works it out from the session: these tests give the page a session, as it
/// has it on a phone.
void main() {
  late MockDiaryRepository diary;
  late MockClassesRepository classes;
  late MockInstitutionsRepository institutions;

  setUp(() {
    diary = MockDiaryRepository();
    classes = MockClassesRepository();
    final years = MockAcademicYearsRepository();
    final sections = MockSectionsRepository();
    institutions = MockInstitutionsRepository();
    when(institutions.institutions).thenAnswer(
      (_) async => [summary(), summary(id: 'i2', code: 'LVS', name: 'Lake View School')],
    );
    // The sections a teacher leads or teaches are what CLS-01 and SEC-01 give: one class with one section.
    for (final id in ['i1', 'i2']) {
      when(() => years.years(id)).thenAnswer((_) async => [currentYear]);
      when(() => classes.classes(id)).thenAnswer((_) async => [class1]);
    }
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA]);
    when(() => diary.ofSection('e1', '2026-11-17')).thenAnswer((_) async => [mathsEntry, artEntry, noticeEntry]);
    when(() => diary.ofChild('s1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
    getIt
      ..registerSingleton<DiaryRepository>(diary)
      ..registerSingleton<AcademicYearsRepository>(years)
      ..registerSingleton<ClassesRepository>(classes)
      ..registerSingleton<SectionsRepository>(sections)
      ..registerSingleton<InstitutionsRepository>(institutions);
  });
  tearDown(getIt.reset);

  /// Opens the page as [context] at the Institution [at] (`i1` or `i2`).
  Future<void> pump(WidgetTester tester, AuthContext context, {String at = 'i1'}) async {
    getIt.registerSingleton<InstitutionChoiceStore>(InMemoryInstitutionChoiceStore(at));
    final session = _MockSessionBloc();
    when(() => session.state).thenReturn(
      SessionAuthenticated(AuthSession(person: testPerson, contexts: [context], activeContext: context)),
    );
    await tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: DiaryPage(clock: () => today),
      ),
      size: const Size(400, 1600),
    );
    await tester.pumpAndSettle();
  }

  const owner = AuthContext(role: RoleCode.societyOwner, societyId: 's1', societyName: 'North Trust');
  const admin = AuthContext(role: RoleCode.institutionAdmin, societyId: 's1', societyName: 'North Trust');
  const teacher = AuthContext(
    role: RoleCode.teacherStaff,
    societyId: 's1',
    societyName: 'North Trust',
    homeInstitutionId: 'i1',
    staffMemberId: 't1',
  );

  Finder button(String action, String id) => find.byKey(ValueKey('diary.$action.$id'));

  testWidgets('an Owner adds, and changes every entry, at any Institution', (tester) async {
    await pump(tester, owner, at: 'i2');
    expect(find.byKey(const Key('diary.add')), findsOneWidget);
    for (final id in ['d1', 'd2', 'd3']) {
      expect(button('edit', id), findsOneWidget, reason: id);
      expect(button('delete', id), findsOneWidget, reason: id);
    }
  });

  testWidgets('an Admin adds, and changes every entry, including one no teacher wrote', (tester) async {
    await pump(tester, admin);
    expect(find.byKey(const Key('diary.add')), findsOneWidget);
    expect(button('edit', 'd3'), findsOneWidget);
    expect(button('delete', 'd2'), findsOneWidget);
  });

  testWidgets('a teacher adds at their home Institution, and changes only the entries they wrote', (tester) async {
    await pump(tester, teacher);
    expect(find.byKey(const Key('diary.add')), findsOneWidget);
    expect(button('edit', 'd1'), findsOneWidget);
    expect(button('delete', 'd1'), findsOneWidget);
    for (final id in ['d2', 'd3']) {
      expect(button('edit', id), findsNothing, reason: id);
      expect(button('delete', id), findsNothing, reason: id);
    }
  });

  testWidgets('a teacher at another Institution of theirs reads the diary and cannot write or change it', (
    tester,
  ) async {
    await pump(tester, teacher, at: 'i2');
    expect(find.text('Bring crayons.'), findsOneWidget);
    expect(find.byKey(const Key('diary.add')), findsNothing);
    expect(button('edit', 'd1'), findsNothing);
    expect(button('delete', 'd1'), findsNothing);
  });

  testWidgets('a teacher with no staff record changes nothing', (tester) async {
    await pump(
      tester,
      const AuthContext(
        role: RoleCode.teacherStaff,
        societyId: 's1',
        societyName: 'North Trust',
        homeInstitutionId: 'i1',
      ),
    );
    expect(button('edit', 'd3'), findsNothing);
  });

  testWidgets('reads the sections of the Institution chosen', (tester) async {
    await pump(tester, owner, at: 'i2');
    verify(() => classes.classes('i2')).called(1);
    verifyNever(() => classes.classes('i1'));
  });

  group("a parent's", () {
    const parent = AuthContext(role: RoleCode.studentParent, societyId: 's1', societyName: 'North Trust');
    const diya = LinkedChild(
      studentId: 's1',
      firstName: 'Diya',
      institutionName: 'Green Valley School',
      isBlocked: false,
    );

    Future<void> pumpParent(WidgetTester tester, ActiveChildState state) async {
      final session = _MockSessionBloc();
      when(() => session.state).thenReturn(
        const SessionAuthenticated(AuthSession(person: testPerson, contexts: [parent], activeContext: parent)),
      );
      final children = _MockActiveChildBloc();
      when(() => children.state).thenReturn(state);
      await tester.pumpAppScaled(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: session),
            BlocProvider<ActiveChildBloc>.value(value: children),
          ],
          child: DiaryPage(clock: () => today),
        ),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('says there is no child to show when there is none', (tester) async {
      await pumpParent(tester, const ActiveChildNone());
      expect(find.byKey(const Key('diary.noChild')), findsOneWidget);
    });

    testWidgets('reads the diary of the child shown, with nothing to write or change', (tester) async {
      await pumpParent(tester, const ActiveChildReady(children: [diya], selected: diya));
      expect(find.text('Exercise 4.2, questions 1 to 5.'), findsOneWidget);
      expect(find.byKey(const Key('diary.add')), findsNothing);
      expect(button('edit', 'd1'), findsNothing);
      verify(() => diary.ofChild('s1', '2026-11-17')).called(1);
      verifyNever(() => classes.classes(any()));
    });
  });
}
