import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const session = AuthSession(
    person: Person(id: 'p1', email: 'asha.rao@example.com', firstName: 'Asha', preferredLanguage: 'kn'),
    contexts: [],
  );

  test('while restoring, everything waits on the splash', () {
    expect(sessionRedirect(const SessionUnknown(), AppRoutes.home), AppRoutes.splash);
    expect(sessionRedirect(const SessionUnknown(), AppRoutes.splash), isNull);
  });

  test('signed out goes to login', () {
    expect(sessionRedirect(const SessionUnauthenticated(), AppRoutes.home), AppRoutes.login);
    expect(sessionRedirect(const SessionUnauthenticated(), AppRoutes.splash), AppRoutes.login);
    expect(sessionRedirect(const SessionUnauthenticated(), AppRoutes.login), isNull);
  });

  test('signed in leaves the public screens for home', () {
    expect(sessionRedirect(const SessionAuthenticated(session), AppRoutes.login), AppRoutes.home);
    expect(sessionRedirect(const SessionAuthenticated(session), AppRoutes.splash), AppRoutes.home);
    expect(sessionRedirect(const SessionAuthenticated(session), AppRoutes.home), isNull);
  });

  test('update required is never redirected away', () {
    for (final state in [const SessionUnknown(), const SessionUnauthenticated(), const SessionAuthenticated(session)]) {
      expect(sessionRedirect(state, AppRoutes.updateRequired), isNull);
    }
  });
}
