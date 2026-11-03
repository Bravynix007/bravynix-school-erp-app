import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institutions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late _MockSessionBloc session;

  setUp(() {
    final repository = MockInstitutionsRepository();
    when(repository.institutions).thenAnswer((_) async => [summary()]);
    getIt.registerSingleton<InstitutionsRepository>(repository);
    session = _MockSessionBloc();
  });
  tearDown(getIt.reset);

  Future<void> pumpAs(WidgetTester tester, RoleCode role) async {
    final context = AuthContext(role: role, societyId: 's1', societyName: 'North Trust');
    when(() => session.state).thenReturn(
      SessionAuthenticated(AuthSession(person: testPerson, contexts: [context], activeContext: context)),
    );
    await tester.pumpApp(BlocProvider<SessionBloc>.value(value: session, child: const InstitutionsPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('offers Add Institution to an Owner', (tester) async {
    await pumpAs(tester, RoleCode.societyOwner);
    expect(find.text('Sri Vidya High School'), findsOneWidget);
    expect(find.byKey(const Key('institutions.add')), findsOneWidget);
  });

  for (final role in [RoleCode.institutionAdmin, RoleCode.teacherStaff, RoleCode.superAdmin]) {
    testWidgets('does not offer Add Institution to a ${role.name}', (tester) async {
      await pumpAs(tester, role);
      expect(find.text('Sri Vidya High School'), findsOneWidget);
      expect(find.byKey(const Key('institutions.add')), findsNothing);
    });
  }
}
