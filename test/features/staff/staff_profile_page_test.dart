import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution_admin.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_profile_page.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignments_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sections.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';
import '../../helpers/teaching_assignments.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late MockStaffRepository staff;
  late MockSubjectsRepository subjects;
  late MockInstitutionsRepository institutions;
  late MockSectionsRepository sections;
  late MockTeachingAssignmentsRepository teaching;
  late _MockSessionBloc session;

  setUp(() {
    staff = MockStaffRepository();
    subjects = MockSubjectsRepository();
    institutions = MockInstitutionsRepository();
    final masters = MockMastersRepository();
    final years = MockAcademicYearsRepository();
    final classes = MockClassesRepository();
    sections = MockSectionsRepository();
    teaching = MockTeachingAssignmentsRepository();
    when(
      () => teaching.assignments(
        'i1',
        academicYearId: 'y1',
        staffMemberId: 'f1',
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => const ItemsPage([mathsInClass1A], page: 1, totalPages: 1));
    when(() => years.years('i1')).thenAnswer((_) async => [currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
    when(() => staff.member('f1')).thenAnswer((_) async => kavyaMember);
    when(subjects.subjects).thenAnswer((_) async => const [art, maths]);
    when(() => institutions.admins(any(), page: any(named: 'page')))
        .thenAnswer((_) async => const ItemsPage(<InstitutionAdmin>[], page: 1, totalPages: 1));
    when(institutions.institutions).thenAnswer((_) async => [summary(), summary(id: 'i2', name: 'Lake View School')]);
    when(() => masters.entries(MasterType.designations)).thenAnswer((_) async => [designationEntry]);
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [lowerPrimary]);
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [countryEntry]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [stateEntry]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [cityEntry]);
    getIt
      ..registerSingleton<StaffRepository>(staff)
      ..registerSingleton<SubjectsRepository>(subjects)
      ..registerSingleton<InstitutionsRepository>(institutions)
      ..registerSingleton<MastersRepository>(masters)
      ..registerSingleton<AcademicYearsRepository>(years)
      ..registerSingleton<ClassesRepository>(classes)
      ..registerSingleton<SectionsRepository>(sections)
      ..registerSingleton<TeachingAssignmentsRepository>(teaching);
    session = _MockSessionBloc();
  });
  tearDown(getIt.reset);

  Future<void> pumpAs(WidgetTester tester, RoleCode role, {Size size = const Size(400, 2800)}) async {
    final context = AuthContext(role: role, societyId: 's1', societyName: 'North Trust');
    when(() => session.state).thenReturn(
      SessionAuthenticated(AuthSession(person: testPerson, contexts: [context], activeContext: context)),
    );
    await tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: const StaffProfilePage(id: 'f1'),
      ),
      size: size,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('the Other Institutions list', () {
    testWidgets("is the Society Owner's, who reads the Institutions for it", (tester) async {
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      expect(find.byKey(const Key('staffAccess.saveInstitutions')), findsOneWidget);
      expect(find.text('Lake View School'), findsWidgets);
      expect(find.text('Admin access'), findsOneWidget);
      verify(institutions.institutions).called(greaterThan(0));
    });

    for (final role in [RoleCode.institutionAdmin, RoleCode.teacherStaff]) {
      testWidgets('is not shown to a ${role.name}, and the Institutions are not read', (tester) async {
        await pumpAs(tester, role);
        await openTab(tester, 'Access');
        expect(find.byKey(const Key('staffAccess.saveSubjects')), findsOneWidget);
        expect(find.byKey(const Key('staffAccess.saveInstitutions')), findsNothing);
        expect(find.text('Admin access'), findsNothing);
        verifyNever(institutions.institutions);
      });
    }
  });

  group('the teaching section', () {
    for (final role in [RoleCode.societyOwner, RoleCode.institutionAdmin]) {
      testWidgets('is shown to a ${role.name}, with what the staff member teaches this year', (tester) async {
        await pumpAs(tester, role);
        await openTab(tester, 'Access');
        expect(find.text('Teaching'), findsOneWidget);
        expect(find.byKey(const Key('staffTeaching.end.g1')), findsOneWidget);
        verify(
          () => teaching.assignments(
            'i1',
            academicYearId: 'y1',
            staffMemberId: 'f1',
            page: any(named: 'page'),
          ),
        ).called(1);
      });
    }

    testWidgets('reads what they teach once, however often the tab is left and opened again or scrolled', (
      tester,
    ) async {
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await openTab(tester, 'Personal');
      await openTab(tester, 'Access');
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, 3000));
      await tester.pumpAndSettle();
      verify(
        () => teaching.assignments(
          'i1',
          academicYearId: 'y1',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).called(1);
    });

    testWidgets(
      'keeps an assignment on its way when the person goes to another tab and back, and says when it is made',
      (
        tester,
      ) async {
        final held = Completer<TeachingAssignment>();
        when(
          () => teaching.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
        ).thenAnswer((_) => held.future);
        await pumpAs(tester, RoleCode.societyOwner);
        await openTab(tester, 'Access');
        await tester.ensureVisible(find.byKey(const Key('staffTeaching.section')));
        await tester.tap(find.byKey(const Key('staffTeaching.section')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Class 1 · Blue').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('staffTeaching.subject')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mathematics').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('staffTeaching.assign')));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.text('Personal'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Access'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.ensureVisible(find.byKey(const Key('staffTeaching.assign')));
        expect(tester.widget<AppButton>(find.byKey(const Key('staffTeaching.assign'))).loading, isTrue);
        held.complete(mathsInClass1Blue);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('staffTeaching.end.g2')), findsOneWidget);
        expect(find.text('Mathematics in Class 1 · Blue assigned'), findsOneWidget);
      },
    );

    testWidgets('gives them a subject in a section, through the API', (tester) async {
      when(
        () => teaching.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
      ).thenAnswer((_) async => mathsInClass1Blue);
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await tester.ensureVisible(find.byKey(const Key('staffTeaching.section')));
      await tester.tap(find.byKey(const Key('staffTeaching.section')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class 1 · Blue').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('staffTeaching.subject')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mathematics').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('staffTeaching.assign')));
      await tester.pumpAndSettle();
      verify(
        () => teaching.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
      ).called(1);
      expect(find.text('Mathematics in Class 1 · Blue assigned'), findsOneWidget);
    });
  });

  group('once their subjects are saved', () {
    Future<void> saveSubjects(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('staffAccess.subject.u2')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('staffAccess.saveSubjects')));
      await tester.tap(find.byKey(const Key('staffAccess.saveSubjects')));
    }

    setUp(
      () =>
          when(() => staff.setSubjects('f1', ['u1', 'u2']))
              .thenAnswer((_) async => kavyaWith(subjectIds: const ['u1', 'u2'])),
    );

    testWidgets('the teaching part offers them, and does not read what they teach again', (tester) async {
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await saveSubjects(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('staffTeaching.subject')));
      await tester.tap(find.byKey(const Key('staffTeaching.subject')));
      await tester.pumpAndSettle();
      // Once as the subject ticked on the list above, and once as an option of the assignment.
      expect(find.text('Art'), findsNWidgets(2));
      verify(
        () => teaching.assignments(
          'i1',
          academicYearId: 'y1',
          staffMemberId: 'f1',
          page: any(named: 'page'),
        ),
      ).called(1);
    });

    testWidgets('an assignment on its way is kept', (tester) async {
      final held = Completer<TeachingAssignment>();
      when(
        () => teaching.assign(staffMemberId: 'f1', academicYearId: 'y1', sectionId: 'e2', subjectId: 'u1'),
      ).thenAnswer((_) => held.future);
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await tester.ensureVisible(find.byKey(const Key('staffTeaching.section')));
      await tester.tap(find.byKey(const Key('staffTeaching.section')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class 1 · Blue').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('staffTeaching.subject')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mathematics').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('staffTeaching.assign')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.ensureVisible(find.byKey(const ValueKey('staffAccess.subject.u2')));
      await saveSubjects(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.byKey(const Key('staffTeaching.assign')));
      expect(tester.widget<AppButton>(find.byKey(const Key('staffTeaching.assign'))).loading, isTrue);
      held.complete(mathsInClass1Blue);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffTeaching.end.g2')), findsOneWidget);
    });
  });

  group('the class teacher section', () {
    for (final role in [RoleCode.societyOwner, RoleCode.institutionAdmin]) {
      testWidgets('is shown to a ${role.name}, with the sections of the home Institution', (tester) async {
        await pumpAs(tester, role);
        await openTab(tester, 'Access');
        expect(find.byKey(const Key('staffClassTeacher.section')), findsOneWidget);
        verify(() => sections.sections('k1')).called(1);
      });
    }
  });

  group('the Admin access part', () {
    Future<void> grantAtHome(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('staffAdmin.toggle.i1')));
      await tester.tap(find.byKey(const Key('staffAdmin.toggle.i1')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Make Admin')));
      await tester.pump();
    }

    testWidgets('reads who is an Admin once, however often the tab is left and opened again', (tester) async {
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await openTab(tester, 'Personal');
      await openTab(tester, 'Access');
      await openTab(tester, 'Settings');
      await openTab(tester, 'Access');
      verify(() => institutions.admins('i1', page: any(named: 'page'))).called(1);
    });

    testWidgets('reads who is an Admin once when the tab is scrolled away and back', (tester) async {
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.drag(list, const Offset(0, 3000));
      await tester.pumpAndSettle();
      verify(() => institutions.admins('i1', page: any(named: 'page'))).called(1);
    });

    testWidgets('keeps a grant on its way when the person goes to another tab and back, and says when it is done', (
      tester,
    ) async {
      final held = Completer<InstitutionAdmin>();
      when(() => institutions.grantAdmin('i1', 'f1')).thenAnswer((_) => held.future);
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await grantAtHome(tester);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Personal'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Access'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.byKey(const Key('staffAdmin.toggle.i1')));
      expect(tester.widget<AppButton>(find.byKey(const Key('staffAdmin.toggle.i1'))).loading, isTrue);
      held.complete(adminOf());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('staffAdmin.isAdmin.i1')), findsOneWidget);
      expect(find.text('Kavya Nair is now an Admin of Sri Vidya High School'), findsOneWidget);
    });

    testWidgets('keeps the tab where it was scrolled when the extra Institutions are saved', (tester) async {
      when(() => staff.setInstitutions('f1', ['i2'])).thenAnswer((_) async => kavyaWith(institutionIds: const ['i2']));
      await pumpAs(tester, RoleCode.societyOwner, size: const Size(400, 700));
      await openTab(tester, 'Access');
      await tester.ensureVisible(find.byKey(const ValueKey('staffAccess.institution.i2')));
      await tester.tap(find.byKey(const ValueKey('staffAccess.institution.i2')));
      await tester.pump();
      final list = tester.state<ScrollableState>(find.byType(Scrollable).last);
      list.position.jumpTo(list.position.maxScrollExtent / 2);
      await tester.pump();
      final before = list.position.pixels;
      await tester.ensureVisible(find.byKey(const Key('staffAccess.saveInstitutions')));
      final scrolled = list.position.pixels;
      await tester.tap(find.byKey(const Key('staffAccess.saveInstitutions')));
      await tester.pumpAndSettle();
      expect(before, greaterThan(0));
      expect(tester.state<ScrollableState>(find.byType(Scrollable).last).position.pixels, scrolled);
    });

    testWidgets('reads again once their extra Institutions are saved, and not once their subjects are', (tester) async {
      when(() => staff.setInstitutions('f1', ['i2'])).thenAnswer((_) async => kavyaWith(institutionIds: const ['i2']));
      when(() => staff.setSubjects('f1', ['u1', 'u2']))
          .thenAnswer((_) async => kavyaWith(subjectIds: const ['u1', 'u2']));
      await pumpAs(tester, RoleCode.societyOwner);
      await openTab(tester, 'Access');
      await tester.tap(find.byKey(const ValueKey('staffAccess.subject.u2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('staffAccess.saveSubjects')));
      await tester.pumpAndSettle();
      verify(() => institutions.admins('i1', page: any(named: 'page'))).called(1);
      await tester.ensureVisible(find.byKey(const ValueKey('staffAccess.institution.i2')));
      await tester.tap(find.byKey(const ValueKey('staffAccess.institution.i2')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('staffAccess.saveInstitutions')));
      await tester.tap(find.byKey(const Key('staffAccess.saveInstitutions')));
      await tester.pumpAndSettle();
      verify(() => institutions.admins('i1', page: any(named: 'page'))).called(1);
      verify(() => institutions.admins('i2', page: any(named: 'page'))).called(1);
    });
  });

  testWidgets('keeps what is ticked and not yet saved when the person goes to another tab and back', (tester) async {
    await pumpAs(tester, RoleCode.societyOwner);
    await openTab(tester, 'Access');
    await tester.tap(find.byKey(const ValueKey('staffAccess.subject.u2')));
    await tester.pump();
    await openTab(tester, 'Personal');
    await openTab(tester, 'Settings');
    await openTab(tester, 'Access');
    final tile = find.byKey(const ValueKey('staffAccess.subject.u2'));
    expect(
      tester.widget<Semantics>(find.descendant(of: tile, matching: find.byType(Semantics)).first).properties.checked,
      isTrue,
    );
    expect(tester.widget<AppButton>(find.byKey(const Key('staffAccess.saveSubjects'))).onPressed, isNotNull);
    // Once for the lists of the tab and once for the teaching part, and not again on the way back.
    verify(subjects.subjects).called(2);
  });

  testWidgets('keeps a block on its way when the person goes to another tab and back, and says when it is done', (
    tester,
  ) async {
    final held = Completer<StaffMember>();
    when(() => staff.block('f1')).thenAnswer((_) => held.future);
    await pumpAs(tester, RoleCode.societyOwner);
    await openTab(tester, 'Settings');
    await tester.tap(find.byKey(const Key('staffSettings.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block access')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Personal'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<AppButton>(find.byKey(const Key('staffSettings.toggle'))).loading, isTrue);
    held.complete(kavyaWith(isBlocked: true, version: 5));
    await tester.pumpAndSettle();
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Kavya Nair blocked'), findsOneWidget);
  });

  testWidgets('keeps the names on the Personal tab after a block, a lift or a save', (tester) async {
    when(() => staff.block('f1')).thenAnswer((_) async => kavyaWith(isBlocked: true, version: 5));
    await pumpAs(tester, RoleCode.societyOwner);
    expect(find.text('Mathematics Teacher'), findsOneWidget);
    await openTab(tester, 'Settings');
    await tester.tap(find.byKey(const Key('staffSettings.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block access')));
    await tester.pumpAndSettle();
    await openTab(tester, 'Personal');
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Mathematics Teacher'), findsOneWidget);
    expect(find.text('Lower Primary'), findsOneWidget);
    expect(find.text('12 Lake Road\nNear the park\nBengaluru, Karnataka, India\n560066'), findsOneWidget);
  });
}
