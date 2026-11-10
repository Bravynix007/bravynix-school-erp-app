import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution_admin.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_profile_page.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late MockStaffRepository staff;
  late MockSubjectsRepository subjects;
  late MockInstitutionsRepository institutions;
  late _MockSessionBloc session;

  setUp(() {
    staff = MockStaffRepository();
    subjects = MockSubjectsRepository();
    institutions = MockInstitutionsRepository();
    final masters = MockMastersRepository();
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
      ..registerSingleton<MastersRepository>(masters);
    session = _MockSessionBloc();
  });
  tearDown(getIt.reset);

  Future<void> pumpAs(WidgetTester tester, RoleCode role) async {
    final context = AuthContext(role: role, societyId: 's1', societyName: 'North Trust');
    when(() => session.state).thenReturn(
      SessionAuthenticated(AuthSession(person: testPerson, contexts: [context], activeContext: context)),
    );
    await tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: const StaffProfilePage(id: 'f1'),
      ),
      size: const Size(400, 1600),
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
    verify(subjects.subjects).called(1);
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
