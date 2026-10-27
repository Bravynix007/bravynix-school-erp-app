import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/profile/presentation/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late _MockSessionBloc session;

  setUpAll(() => registerFallbackValue(const SessionStarted()));
  setUp(() => session = _MockSessionBloc());

  Future<void> pump(WidgetTester tester, AuthSession value, {double textScale = 1}) {
    when(() => session.state).thenReturn(SessionAuthenticated(value));
    return tester.pumpAppScaled(
      BlocProvider<SessionBloc>.value(value: session, child: const ProfilePage()),
      textScale: textScale,
    );
  }

  testWidgets('shows the person, the role in use and its Society', (tester) async {
    await pump(tester, testSession);
    expect(find.text('Asha Rao'), findsOneWidget);
    expect(find.text('asha.rao@example.com'), findsOneWidget);
    expect(find.text('Teacher / Staff'), findsOneWidget);
    expect(find.text('Sunrise Education Trust'), findsOneWidget);
  });

  testWidgets('a person with no name yet shows their email as the name', (tester) async {
    await pump(
      tester,
      const AuthSession(
        person: Person(id: 'p2', email: 'new.owner@two-worlds.test', preferredLanguage: 'en'),
        contexts: [ownerNorth],
        activeContext: ownerNorth,
      ),
    );
    expect(find.text('new.owner@two-worlds.test'), findsNWidgets(2));
  });

  testWidgets('has no Switch role with a single role', (tester) async {
    await pump(tester, testSession);
    expect(find.byKey(const Key('profile.switchRole')), findsNothing);
  });

  testWidgets('offers Switch role with more than one role', (tester) async {
    await pump(tester, twoRoleSession.withActiveContext(ownerNorth));
    expect(find.byKey(const Key('profile.switchRole')), findsOneWidget);
  });

  testWidgets('Log out ends the session', (tester) async {
    await pump(tester, testSession);
    await tester.tap(find.byKey(const Key('profile.logOut')));
    verify(() => session.add(const SessionLogoutRequested())).called(1);
  });

  testWidgets('is usable at a large text scale on a small phone', (tester) async {
    await pump(tester, twoRoleSession.withActiveContext(ownerNorth), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byKey(const Key('profile.logOut')), 100);
  });
}
