import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_page.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

/// Who may mark and who may void follows from the role and the Institution the person is at (API design 10.11), and the
/// page works it out from the session: these tests give the page a session, as it has it on a phone.
void main() {
  late MockAttendanceRepository repository;
  late MockInstitutionsRepository institutions;

  setUp(() {
    repository = MockAttendanceRepository();
    institutions = MockInstitutionsRepository();
    when(institutions.institutions).thenAnswer(
      (_) async => [summary(), summary(id: 'i2', code: 'LVS', name: 'Lake View School')],
    );
    for (final id in ['i1', 'i2']) {
      when(() => repository.sections(id)).thenAnswer((_) async => oneSection);
    }
    when(() => repository.roster('sec1', '2026-11-17')).thenAnswer((_) async => takenRoll);
    getIt
      ..registerSingleton<AttendanceRepository>(repository)
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
        child: AttendancePage(clock: () => DateTime.utc(2026, 11, 17, 4)),
      ),
      size: const Size(400, 1400),
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
  );

  testWidgets('an Owner corrects and voids at any Institution', (tester) async {
    await pump(tester, owner, at: 'i2');
    expect(find.text('Save corrections'), findsOneWidget);
    expect(find.text('Void this register'), findsOneWidget);
  });

  testWidgets('an Admin marks and voids at an Institution that is not their first', (tester) async {
    await pump(tester, admin, at: 'i2');
    expect(find.text('Save corrections'), findsOneWidget);
    expect(find.text('Void this register'), findsOneWidget);
  });

  testWidgets('a teacher corrects at their home Institution, and cannot void', (tester) async {
    await pump(tester, teacher);
    expect(find.text('Save corrections'), findsOneWidget);
    expect(find.text('Void this register'), findsNothing);
  });

  testWidgets('a teacher at another Institution of theirs reads the register and cannot change it', (tester) async {
    await pump(tester, teacher, at: 'i2');
    expect(find.byKey(const Key('attendance.viewOnly')), findsOneWidget);
    expect(find.text('Save corrections'), findsNothing);
    expect(find.text('Void this register'), findsNothing);
  });

  testWidgets('a teacher at another Institution of theirs is told so on a day with no register too', (tester) async {
    when(() => repository.roster('sec1', '2026-11-17')).thenAnswer(
      (_) async => const AttendanceRoster(
        sectionId: 'sec1',
        day: '2026-11-17',
        isHoliday: false,
        canMark: false,
        students: [asha],
      ),
    );
    await pump(tester, teacher, at: 'i2');
    expect(find.text('You mark attendance only at your own Institution.'), findsOneWidget);
    expect(find.text('Confirm & Submit Attendance'), findsNothing);
  });

  testWidgets('reads the sections of the Institution chosen', (tester) async {
    await pump(tester, owner, at: 'i2');
    verify(() => repository.sections('i2')).called(1);
    verifyNever(() => repository.sections('i1'));
  });
}
