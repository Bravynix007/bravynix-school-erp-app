import 'dart:async';

import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_promote_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionBloc extends Mock implements SessionBloc;

class _MockRouterState extends Mock implements GoRouterState;

class _MockContext extends Mock implements BuildContext;

void main() {
  late GoRouter router;

  const person = Person(id: 'p1', email: 'asha.rao@example.com', firstName: 'Asha', preferredLanguage: 'en');
  const role = AuthContext(role: RoleCode.societyOwner, societyId: 's1');

  setUp(() {
    final session = _MockSessionBloc();
    when(() => session.state).thenReturn(
      const SessionAuthenticated(AuthSession(person: person, contexts: [role], activeContext: role)),
    );
    final changes = SessionChanges(const Stream<Object?>.empty());
    addTearDown(changes.dispose);
    router = createRouter(session, changes: changes);
    addTearDown(router.dispose);
  });

  /// The pattern of the route a location is matched to, and the path parameters it reads.
  ({String? pattern, Map<String, String> parameters}) match(String location) {
    final matched = router.configuration.findMatch(Uri.parse(location));
    final route = matched.matches.last.route;
    return (pattern: route is GoRoute ? route.path : null, parameters: matched.pathParameters);
  }

  group('a profile', () {
    test('is reached by the ID in the location, as the ID was written', () {
      for (final (location, pattern, id) in [
        (AppRoutes.staffMember('f1'), AppRoutes.staffMemberPattern, 'f1'),
        (AppRoutes.student('p1'), AppRoutes.studentPattern, 'p1'),
        (AppRoutes.student('a/b'), AppRoutes.studentPattern, 'a/b'),
      ]) {
        final matched = match(location);
        expect(matched.pattern, pattern, reason: location);
        expect(matched.parameters['id'], id, reason: location);
      }
    });

    test('does not take the place of the forms, which have their own locations', () {
      expect(match(AppRoutes.staffForm).pattern, AppRoutes.staffForm);
      expect(match(AppRoutes.studentForm).pattern, AppRoutes.studentForm);
      expect(match(AppRoutes.studentMove).pattern, AppRoutes.studentMove);
    });
  });

  group('the promote screen', () {
    /// Where the route sends a visit that carries [extra], as the router asks it: null when it stays.
    FutureOr<String?> redirectOf(Object? extra) {
      final route = router.configuration.findMatch(Uri.parse(AppRoutes.studentPromote)).matches.last.route as GoRoute;
      final state = _MockRouterState();
      when(() => state.extra).thenReturn(extra);
      return route.redirect!(_MockContext(), state);
    }

    test('is a route of its own', () {
      expect(match(AppRoutes.studentPromote).pattern, AppRoutes.studentPromote);
    });

    test('sends a visit with nothing from the list behind it back to the students', () async {
      expect(await redirectOf(null), AppRoutes.students);
      expect(await redirectOf('i1'), AppRoutes.students);
    });

    test('stays when the list passes what it promotes', () async {
      expect(await redirectOf(const StudentPromoteArgs.group('i1')), isNull);
    });
  });
}
