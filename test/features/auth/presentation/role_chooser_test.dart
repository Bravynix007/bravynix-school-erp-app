import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/cubit/role_cubit.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_chooser_page.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late MockAuthRepository auth;
  late _MockSessionBloc session;

  setUpAll(() {
    registerFallbackValue(const SessionStarted());
    registerFallbackValue(ownerNorth);
  });
  setUp(() {
    auth = MockAuthRepository();
    session = _MockSessionBloc();
  });

  Future<void> pump(WidgetTester tester, AuthSession value, {double textScale = 1}) {
    when(() => session.state).thenReturn(SessionAuthenticated(value));
    return tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(
        value: session,
        child: BlocProvider(create: (_) => RoleCubit(auth), child: const RoleChooserView()),
      ),
      textScale: textScale,
    );
  }

  testWidgets('lists each role with its Society, and marks a blocked one', (tester) async {
    await pump(
      tester,
      const AuthSession(
        person: testPerson,
        contexts: [
          ownerNorth,
          AuthContext(role: RoleCode.societyOwner, societyId: 's2', societyName: 'South Trust', isBlocked: true),
        ],
      ),
    );
    expect(find.text('Society Owner'), findsNWidgets(2));
    expect(find.text('North Trust'), findsOneWidget);
    expect(find.text('South Trust'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('a role without a name from the server shows its title alone', (tester) async {
    await pump(
      tester,
      const AuthSession(
        person: testPerson,
        contexts: [
          AuthContext(role: RoleCode.societyOwner, societyId: 's1'),
          AuthContext(role: RoleCode.studentParent),
        ],
      ),
    );
    expect(find.text('Society Owner'), findsOneWidget);
    expect(find.text('Parent / Student'), findsOneWidget);
  });

  testWidgets('a first choice has no back button and offers Log out', (tester) async {
    await pump(tester, twoRoleSession);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byKey(const Key('role.logOut')), findsOneWidget);
  });

  testWidgets('switching from Profile has Back and no Log out', (tester) async {
    await pump(tester, twoRoleSession.withActiveContext(ownerNorth));
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byKey(const Key('role.logOut')), findsNothing);
  });

  testWidgets('tapping a role asks the server and shows a refusal', (tester) async {
    when(() => auth.switchContext(any())).thenThrow(
      const ApiFailure(statusCode: 403, code: 'ACCESS_BLOCKED', message: ''),
    );
    await pump(tester, twoRoleSession);
    await tester.tap(find.text('South Trust'));
    await tester.pumpAndSettle();
    verify(() => auth.switchContext(ownerSouth)).called(1);
    expect(find.text('Access is blocked for that role. Choose another one or contact your Society.'), findsOneWidget);
  });

  testWidgets('with no role at all, says so and offers Log out', (tester) async {
    await pump(tester, const AuthSession(person: testPerson, contexts: []));
    expect(find.text('No role available'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    verify(() => session.add(const SessionLogoutRequested())).called(1);
  });

  testWidgets('is usable at a large text scale on a small phone', (tester) async {
    await pump(tester, twoRoleSession, textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('South Trust'), 100);
    expect(find.text('South Trust'), findsOneWidget);
    expect(AppLocalizations.of(tester.element(find.byType(RoleChooserView))).chooseRoleTitle, isNotEmpty);
  });
}
