import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionBloc extends Mock implements SessionBloc;

void main() {
  late GoRouter router;

  setUp(() {
    final session = _MockSessionBloc();
    when(() => session.state).thenReturn(const SessionUnauthenticated());
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
}
