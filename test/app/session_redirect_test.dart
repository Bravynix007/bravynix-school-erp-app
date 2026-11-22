import 'package:bravynix_school_erp/app/router/app_router.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_form_page.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_page.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_bulk_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_form_page.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_form_page.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/sections_page.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_page.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_form_page.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_move_page.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_promote_page.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_form_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/classes.dart';
import '../helpers/students.dart';
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

  test("a student's attendance opens only with the student the profile passes, else home", () {
    expect(studentAttendanceRedirect(const StudentAttendanceArgs(studentId: 's1', name: 'Asha Rao')), isNull);
    expect(studentAttendanceRedirect(null), AppRoutes.home);
    expect(studentAttendanceRedirect('s1'), AppRoutes.home);
  });

  test('the class forms open only with what the list passes, else back to the list', () {
    expect(classFormRedirect(const ClassFormArgs(institutionId: 'i1')), isNull);
    expect(classFormRedirect(null), AppRoutes.classes);
    expect(classBulkRedirect(const ClassBulkArgs(institutionId: 'i1', added: {})), isNull);
    expect(classBulkRedirect(const ClassFormArgs(institutionId: 'i1')), AppRoutes.classes);
    expect(classBulkRedirect(null), AppRoutes.classes);
  });

  test('the sections open only with the class the list passes, else back to the class list', () {
    expect(classSectionsRedirect(const SectionsArgs(schoolClass: class1)), isNull);
    expect(classSectionsRedirect(null), AppRoutes.classes);
    expect(sectionFormRedirect(const SectionFormArgs(classId: 'k1')), isNull);
    expect(sectionFormRedirect(const SectionsArgs(schoolClass: class1)), AppRoutes.classes);
    expect(sectionFormRedirect(null), AppRoutes.classes);
  });

  test('the subject form opens only with what the list passes, so an Edit that lost its subject is not an Add', () {
    expect(subjectFormRedirect(const SubjectFormArgs()), isNull);
    expect(subjectFormRedirect(const SubjectFormArgs(subject: maths)), isNull);
    expect(subjectFormRedirect(null), AppRoutes.subjects);
    expect(subjectFormRedirect(maths), AppRoutes.subjects);
  });

  test('the staff form opens only with the Institution or staff member the screen passes, else back to the list', () {
    expect(staffFormRedirect(const StaffFormArgs.add('i1')), isNull);
    expect(staffFormRedirect(const StaffFormArgs.edit('f1')), isNull);
    expect(staffFormRedirect(null), AppRoutes.staff);
    expect(staffFormRedirect('i1'), AppRoutes.staff);
  });

  test('the student form opens only with the Institution the list passes, else back to the list', () {
    expect(studentFormRedirect(const StudentFormArgs.add('i1')), isNull);
    expect(studentFormRedirect(null), AppRoutes.students);
    expect(studentFormRedirect('i1'), AppRoutes.students);
  });

  test('the move form opens only with the student the list passes, else back to the list', () {
    expect(studentMoveRedirect(const StudentMoveArgs(ashaEntry)), isNull);
    expect(studentMoveRedirect(null), AppRoutes.students);
    expect(studentMoveRedirect('p1'), AppRoutes.students);
    expect(studentPromoteRedirect(const StudentPromoteArgs.group('i1')), isNull);
    expect(studentPromoteRedirect(null), AppRoutes.students);
    expect(studentPromoteRedirect('i1'), AppRoutes.students);
  });

  test('the import opens only with the Institution the list passes, else back to the list', () {
    expect(studentImportRedirect('i1'), isNull);
    expect(studentImportRedirect(null), AppRoutes.students);
    expect(studentImportRedirect(const StudentPromoteArgs.group('i1')), AppRoutes.students);
  });

  group('a teacher’s own staff record', () {
    const teacher = AuthContext(role: RoleCode.teacherStaff, societyId: 's1', staffMemberId: 'f1');
    const teacherSession = AuthSession(person: person, contexts: [teacher], activeContext: teacher);

    test('opens for a teacher with a staff member, else back to Profile', () {
      expect(ownStaffRecordRedirect(const SessionAuthenticated(teacherSession)), isNull);
      expect(ownStaffRecordRedirect(const SessionAuthenticated(session)), AppRoutes.profile);
      expect(ownStaffRecordRedirect(const SessionUnauthenticated()), AppRoutes.profile);
    });

    test('is a teacher’s alone, even when another role carries a staff member', () {
      const admin = AuthContext(role: RoleCode.institutionAdmin, societyId: 's1', staffMemberId: 'f1');
      const adminSession = AuthSession(person: person, contexts: [admin], activeContext: admin);
      expect(const SessionAuthenticated(teacherSession).teacherStaffMemberId, 'f1');
      expect(const SessionAuthenticated(adminSession).teacherStaffMemberId, isNull);
    });
  });
}
