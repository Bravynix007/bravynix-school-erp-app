import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late MockInstitutionsRepository repository;
  late _MockSessionBloc session;

  setUp(() {
    repository = MockInstitutionsRepository();
    when(() => repository.institution('i1')).thenAnswer((_) async => institution);
    getIt.registerSingleton<InstitutionsRepository>(repository);
    session = _MockSessionBloc();
  });
  tearDown(getIt.reset);

  Future<void> pumpAs(WidgetTester tester, RoleCode? role) async {
    final context = role == null ? null : AuthContext(role: role, societyId: 's1', societyName: 'North Trust');
    when(() => session.state).thenReturn(
      SessionAuthenticated(
        AuthSession(person: testPerson, contexts: [?context], activeContext: context),
      ),
    );
    await tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: const InstitutionPage(id: 'i1'),
      ),
      size: const Size(400, 1600),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers Edit and Deactivate to an Owner', (tester) async {
    await pumpAs(tester, RoleCode.societyOwner);
    expect(find.byKey(const Key('institution.deactivate')), findsOneWidget);
    expect(find.byKey(const Key('institution.edit')), findsOneWidget);
  });

  for (final role in [RoleCode.institutionAdmin, RoleCode.teacherStaff, RoleCode.superAdmin]) {
    testWidgets('does not offer Edit or Deactivate to a ${role.name}', (tester) async {
      await pumpAs(tester, role);
      expect(find.text('Sri Vidya High School'), findsOneWidget);
      expect(find.byKey(const Key('institution.deactivate')), findsNothing);
      expect(find.byKey(const Key('institution.edit')), findsNothing);
    });
  }

  testWidgets('does not offer Edit or Deactivate before a role is chosen', (tester) async {
    await pumpAs(tester, null);
    expect(find.text('Sri Vidya High School'), findsOneWidget);
    expect(find.byKey(const Key('institution.deactivate')), findsNothing);
    expect(find.byKey(const Key('institution.edit')), findsNothing);
  });
}
