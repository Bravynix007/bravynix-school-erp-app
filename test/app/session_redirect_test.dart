import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_form_page.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_form_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/subjects.dart';

void main() {
  const person = Person(id: 'p1', email: 'asha.rao@example.com', firstName: 'Asha', preferredLanguage: 'kn');
  const role = AuthContext(role: RoleCode.societyOwner, societyId: 's1');
  const session = AuthSession(person: person, contexts: [role], activeContext: role);
  const choosing = AuthSession(
    person: person,
    contexts: [
      role,
      AuthContext(role: RoleCode.societyOwner, societyId: 's2'),
    ],
  );
  const noRole = AuthSession(person: person, contexts: []);

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

  test('without an active role, everything goes to the chooser, which stays put', () {
    for (final stuck in [choosing, noRole]) {
      final state = SessionAuthenticated(stuck);
      for (final location in [AppRoutes.login, AppRoutes.splash, AppRoutes.home, AppRoutes.profile]) {
        expect(sessionRedirect(state, location), AppRoutes.chooseRole);
      }
      expect(sessionRedirect(state, AppRoutes.chooseRole), isNull);
    }
  });

  test('with an active role, the chooser and profile stay reachable for switching', () {
    expect(sessionRedirect(const SessionAuthenticated(session), AppRoutes.chooseRole), isNull);
    expect(sessionRedirect(const SessionAuthenticated(session), AppRoutes.profile), isNull);
  });

  test('update required is never redirected away', () {
    for (final state in [const SessionUnknown(), const SessionUnauthenticated(), const SessionAuthenticated(session)]) {
      expect(sessionRedirect(state, AppRoutes.updateRequired), isNull);
    }
  });

  test('the component gallery is open to everyone, signed in or not', () {
    for (final state in [const SessionUnknown(), const SessionUnauthenticated(), const SessionAuthenticated(session)]) {
      expect(sessionRedirect(state, AppRoutes.gallery), isNull);
    }
  });

  test('the academic year form opens only with the Institution the list passes, else back to the list', () {
    expect(academicYearFormRedirect(const AcademicYearFormArgs(institutionId: 'i1')), isNull);
    expect(academicYearFormRedirect(null), AppRoutes.academicYears);
    expect(academicYearFormRedirect('i1'), AppRoutes.academicYears);
  });

  test('the subject form opens only with what the list passes, so an Edit that lost its subject is not an Add', () {
    expect(subjectFormRedirect(const SubjectFormArgs()), isNull);
    expect(subjectFormRedirect(const SubjectFormArgs(subject: maths)), isNull);
    expect(subjectFormRedirect(null), AppRoutes.subjects);
    expect(subjectFormRedirect(maths), AppRoutes.subjects);
  });
}
