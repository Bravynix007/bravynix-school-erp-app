import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/storage/accent_choice_store.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/profile/presentation/profile_page.dart';
import 'package:bravynix_school_erp/features/theme/presentation/bloc/accent_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  late _MockSessionBloc session;

  setUpAll(() => registerFallbackValue(const SessionStarted()));
  setUp(() => session = _MockSessionBloc());

  Future<void> pump(WidgetTester tester, AuthSession value, {double textScale = 1, Size size = const Size(320, 1000)}) {
    when(() => session.state).thenReturn(SessionAuthenticated(value));
    return tester.pumpAppScaled(
      MultiBlocProvider(
        providers: [
          BlocProvider<SessionBloc>.value(value: session),
          BlocProvider(create: (_) => AccentBloc(InMemoryAccentChoiceStore())),
        ],
        child: const ProfilePage(),
      ),
      textScale: textScale,
      size: size,
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

  testWidgets('offers the theme colours to every role', (tester) async {
    await pump(tester, testSession);
    expect(find.text('Theme colour'), findsOneWidget);
    expect(find.byKey(const Key('accent.teal')), findsOneWidget);
  });

  testWidgets('has no Switch role with a single role', (tester) async {
    await pump(tester, testSession);
    expect(find.byKey(const Key('profile.switchRole')), findsNothing);
  });

  testWidgets('offers Switch role with more than one role', (tester) async {
    await pump(tester, twoRoleSession.withActiveContext(ownerNorth));
    expect(find.byKey(const Key('profile.switchRole')), findsOneWidget);
  });

  testWidgets('offers Platform dues to an Owner', (tester) async {
    await pump(tester, twoRoleSession.withActiveContext(ownerNorth));
    expect(find.byKey(const Key('profile.platformDues')), findsOneWidget);
    expect(find.text('Platform dues'), findsOneWidget);
  });

  testWidgets('still offers Platform dues to an Owner whose access is blocked, because the dues stay open', (
    tester,
  ) async {
    const blocked = AuthContext(
      role: RoleCode.societyOwner,
      societyId: 's1',
      societyName: 'North Trust',
      isBlocked: true,
    );
    await pump(tester, const AuthSession(person: testPerson, contexts: [blocked], activeContext: blocked));
    expect(find.byKey(const Key('profile.platformDues')), findsOneWidget);
  });

  for (final role in [RoleCode.institutionAdmin, RoleCode.teacherStaff, RoleCode.studentParent]) {
    testWidgets('offers no Platform dues to a ${role.name}', (tester) async {
      final context = AuthContext(role: role, societyId: 's1', societyName: 'Sunrise Education Trust');
      await pump(tester, AuthSession(person: testPerson, contexts: [context], activeContext: context));
      expect(find.byKey(const Key('profile.platformDues')), findsNothing);
    });
  }

  for (final role in [RoleCode.societyOwner, RoleCode.institutionAdmin]) {
    testWidgets('offers School setup to a ${role.name}', (tester) async {
      final context = AuthContext(role: role, societyId: 's1', societyName: 'Sunrise Education Trust');
      await pump(tester, AuthSession(person: testPerson, contexts: [context], activeContext: context));
      expect(find.byKey(const Key('profile.schoolSetup')), findsOneWidget);
      expect(find.text('School setup'), findsOneWidget);
    });
  }

  for (final role in [RoleCode.teacherStaff, RoleCode.studentParent]) {
    testWidgets('offers no School setup to a ${role.name}', (tester) async {
      final context = AuthContext(role: role, societyId: 's1', societyName: 'Sunrise Education Trust');
      await pump(tester, AuthSession(person: testPerson, contexts: [context], activeContext: context));
      expect(find.byKey(const Key('profile.schoolSetup')), findsNothing);
    });
  }

  testWidgets('offers My students to a teacher', (tester) async {
    await pump(tester, testSession);
    expect(find.byKey(const Key('profile.classroom')), findsOneWidget);
    expect(find.text('My students'), findsOneWidget);
  });

  for (final role in [RoleCode.societyOwner, RoleCode.institutionAdmin, RoleCode.studentParent]) {
    testWidgets('offers no My students to a ${role.name}', (tester) async {
      final context = AuthContext(role: role, societyId: 's1', societyName: 'Sunrise Education Trust');
      await pump(tester, AuthSession(person: testPerson, contexts: [context], activeContext: context));
      expect(find.byKey(const Key('profile.classroom')), findsNothing);
    });
  }

  testWidgets('offers My details to a teacher who has a staff record', (tester) async {
    const teacher = AuthContext(role: RoleCode.teacherStaff, societyId: 's1', staffMemberId: 'f1');
    await pump(tester, const AuthSession(person: testPerson, contexts: [teacher], activeContext: teacher));
    expect(find.byKey(const Key('profile.staffRecord')), findsOneWidget);
    expect(find.text('My details'), findsOneWidget);
  });

  group('opens', () {
    /// The profile at `/`, with a page that says where a tile went at each place it may go.
    Future<void> pumpRouted(WidgetTester tester, AuthSession value) {
      when(() => session.state).thenReturn(SessionAuthenticated(value));
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => MultiBlocProvider(
              providers: [
                BlocProvider<SessionBloc>.value(value: session),
                BlocProvider(create: (_) => AccentBloc(InMemoryAccentChoiceStore())),
              ],
              child: const ProfilePage(),
            ),
          ),
          for (final path in [AppRoutes.classroom, AppRoutes.ownStaffRecord])
            GoRoute(path: path, builder: (_, _) => Text('went to $path')),
        ],
      );
      addTearDown(router.dispose);
      return tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
    }

    testWidgets('the classroom from My students', (tester) async {
      await pumpRouted(tester, testSession);
      await tester.tap(find.byKey(const Key('profile.classroom')));
      await tester.pumpAndSettle();
      expect(find.text('went to ${AppRoutes.classroom}'), findsOneWidget);
    });

    testWidgets('the own staff record from My details', (tester) async {
      const teacher = AuthContext(role: RoleCode.teacherStaff, societyId: 's1', staffMemberId: 'f1');
      await pumpRouted(tester, const AuthSession(person: testPerson, contexts: [teacher], activeContext: teacher));
      await tester.tap(find.byKey(const Key('profile.staffRecord')));
      await tester.pumpAndSettle();
      expect(find.text('went to ${AppRoutes.ownStaffRecord}'), findsOneWidget);
    });
  });

  testWidgets('offers no My details to a role that is not a teacher, or a teacher with no staff record', (
    tester,
  ) async {
    await pump(tester, testSession);
    expect(find.byKey(const Key('profile.staffRecord')), findsNothing);
    const admin = AuthContext(role: RoleCode.institutionAdmin, societyId: 's1', staffMemberId: 'f1');
    await tester.pumpWidget(const SizedBox());
    await pump(tester, const AuthSession(person: testPerson, contexts: [admin], activeContext: admin));
    expect(find.byKey(const Key('profile.staffRecord')), findsNothing);
  });

  testWidgets('Log out ends the session', (tester) async {
    await pump(tester, testSession);
    await tester.tap(find.byKey(const Key('profile.logOut')));
    verify(() => session.add(const SessionLogoutRequested())).called(1);
  });

  testWidgets('is usable at a large text scale on a small phone', (tester) async {
    await pump(tester, twoRoleSession.withActiveContext(ownerNorth), textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.byKey(const Key('profile.logOut')), 100);
  });
}
