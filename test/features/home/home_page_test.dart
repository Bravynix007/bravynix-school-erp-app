import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:bravynix_school_erp/features/home/presentation/home_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockSessionBloc extends MockBloc<SessionEvent, SessionState> implements SessionBloc;

void main() {
  Future<void> pumpHome(WidgetTester tester, Person person) {
    final session = _MockSessionBloc();
    when(() => session.state).thenReturn(SessionAuthenticated(AuthSession(person: person, contexts: const [])));
    return tester.pumpApp(BlocProvider<SessionBloc>.value(value: session, child: const HomePage()));
  }

  testWidgets('greets the person by first name', (tester) async {
    await pumpHome(tester, testPerson);
    expect(find.text('Welcome, Asha'), findsOneWidget);
  });

  testWidgets('greets a person with no name yet by their email', (tester) async {
    await pumpHome(tester, const Person(id: 'p2', email: 'new.owner@two-worlds.test', preferredLanguage: 'en'));
    expect(find.text('Welcome, new.owner@two-worlds.test'), findsOneWidget);
  });

  group('blocked access', () {
    late MockBlocksRepository blocks;
    setUp(() {
      blocks = MockBlocksRepository();
      getIt.registerSingleton<BlocksRepository>(blocks);
    });
    tearDown(getIt.reset);

    Future<void> pumpAs(WidgetTester tester, AuthContext active) {
      final session = _MockSessionBloc();
      when(() => session.state).thenReturn(
        SessionAuthenticated(AuthSession(person: testPerson, contexts: [active], activeContext: active)),
      );
      return tester.pumpApp(BlocProvider<SessionBloc>.value(value: session, child: const HomePage()));
    }

    SectionBlock block(BlockSection section, {String reason = 'Annual fee unpaid'}) => SectionBlock(
      id: 'b1',
      section: section,
      institutionId: section == BlockSection.owners ? null : 'i1',
      institutionName: section == BlockSection.owners ? null : 'Sri Vidya High School',
      reason: reason,
      blockedAt: DateTime.utc(2026, 10, 27, 5),
    );

    testWidgets('an Owner sees what is blocked in the Society and why, even while their own access is open', (
      tester,
    ) async {
      when(() => blocks.societyBlocks()).thenAnswer((_) async => [block(BlockSection.staff)]);
      await pumpAs(tester, ownerNorth);
      await tester.pumpAndSettle();
      expect(find.text('Blocked in North Trust'), findsOneWidget);
      expect(find.text('Staff of Sri Vidya High School'), findsOneWidget);
      expect(find.text('Reason: Annual fee unpaid'), findsOneWidget);
      expect(find.textContaining('Contact BravyNix support'), findsNothing);
    });

    testWidgets('a blocked Owner is told to contact BravyNix support, and still reads the reason', (tester) async {
      when(() => blocks.societyBlocks()).thenAnswer(
        (_) async => [block(BlockSection.owners, reason: 'Terms not accepted')],
      );
      await pumpAs(
        tester,
        const AuthContext(role: RoleCode.societyOwner, societyId: 's1', societyName: 'North Trust', isBlocked: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Access to North Trust is blocked. Contact BravyNix support.'), findsOneWidget);
      expect(find.text('Reason: Terms not accepted'), findsOneWidget);
    });

    testWidgets('blocked staff are told to contact their Society, and the app asks for no reason', (tester) async {
      await pumpAs(
        tester,
        const AuthContext(
          role: RoleCode.institutionAdmin,
          societyId: 's1',
          societyName: 'North Trust',
          isBlocked: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your access to North Trust is blocked. Contact your Society.'), findsOneWidget);
      verifyNever(() => blocks.societyBlocks());
    });

    testWidgets('an Owner with two Societies sees the blocks of the one they chose, not the first', (tester) async {
      when(() => blocks.societyBlocks()).thenAnswer((_) async => [block(BlockSection.staff, reason: 'South reason')]);
      final session = _MockSessionBloc();
      when(() => session.state).thenReturn(
        const SessionAuthenticated(
          AuthSession(person: testPerson, contexts: [ownerNorth, ownerSouth], activeContext: ownerSouth),
        ),
      );
      await tester.pumpApp(BlocProvider<SessionBloc>.value(value: session, child: const HomePage()));
      await tester.pumpAndSettle();
      expect(find.text('Blocked in South Trust'), findsOneWidget);
      expect(find.text('Blocked in North Trust'), findsNothing);
    });

    testWidgets("switching Society reads the new Society's blocks and drops the old reason", (tester) async {
      var calls = 0;
      when(() => blocks.societyBlocks()).thenAnswer(
        (_) async => [block(BlockSection.staff, reason: calls++ == 0 ? 'North reason' : 'South reason')],
      );
      AuthSession as(AuthContext active) =>
          AuthSession(person: testPerson, contexts: const [ownerNorth, ownerSouth], activeContext: active);
      final session = _MockSessionBloc();
      whenListen(
        session,
        Stream<SessionState>.fromFuture(
          Future<SessionState>.delayed(const Duration(milliseconds: 10), () => SessionAuthenticated(as(ownerSouth))),
        ),
        initialState: SessionAuthenticated(as(ownerNorth)),
      );
      await tester.pumpApp(BlocProvider<SessionBloc>.value(value: session, child: const HomePage()));
      await tester.pumpAndSettle();
      expect(find.text('Reason: North reason'), findsNothing);
      expect(find.text('Blocked in South Trust'), findsOneWidget);
      expect(find.text('Reason: South reason'), findsOneWidget);
      verify(() => blocks.societyBlocks()).called(2);
    });

    testWidgets('an Owner of a Society with nothing blocked sees no new section', (tester) async {
      when(() => blocks.societyBlocks()).thenAnswer((_) async => []);
      await pumpAs(tester, ownerNorth);
      await tester.pumpAndSettle();
      expect(find.textContaining('Blocked in'), findsNothing);
      expect(find.text('Welcome, Asha'), findsOneWidget);
    });
  });
}
