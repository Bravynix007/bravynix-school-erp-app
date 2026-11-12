/// Every route path in one place. Feature routes are added here as modules land.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const updateRequired = '/update-required';
  static const chooseRole = '/choose-role';
  static const profile = '/profile';

  /// BIL-01: what BravyNix has charged the Owner's Society. View only.
  static const platformDues = '/platform-dues';

  /// The `:id` pattern, for the router; [platformDue] builds the location of one due.
  static const platformDuePattern = '/platform-dues/:id';
  static String platformDue(String id) => '$platformDues/${Uri.encodeComponent(id)}';

  /// School setup (decision 3): the hub Owners and Institution Admins reach from Profile.
  static const schoolSetup = '/school-setup';

  /// INS-01: the Institutions the person works in.
  static const institutions = '/school-setup/institutions';

  /// INS-02: the form that adds an Institution. Registered before [institutionPattern] so `new` is not read as an id.
  static const institutionNew = '/school-setup/institutions/new';

  /// The `:id` pattern, for the router; [institution] builds the location of one Institution.
  static const institutionPattern = '/school-setup/institutions/:id';
  static String institution(String id) => '$institutions/${Uri.encodeComponent(id)}';

  /// INS-04: the form that edits one Institution.
  static const institutionEditPattern = '/school-setup/institutions/:id/edit';
  static String institutionEdit(String id) => '${institution(id)}/edit';

  /// Academic years of the chosen Institution (AY-01), and the form that adds or edits one (AY-02, AY-03), which takes
  /// the Institution and the year as the route's `extra`: no endpoint reads one year, so the list hands it over.
  static const academicYears = '/school-setup/academic-years';
  static const academicYearForm = '/school-setup/academic-years/form';

  /// Subjects of the Society (SUB-01), and the form that adds or edits one (SUB-02, SUB-03), which takes the subject to
  /// edit as the route's `extra` (null to add): no endpoint reads one subject, so the list hands it over.
  static const subjects = '/school-setup/subjects';
  static const subjectForm = '/school-setup/subjects/form';

  /// Classes of the chosen Institution (CLS-01), the form that adds or edits one (CLS-02, CLS-04) and the bulk add
  /// (CLS-03). The forms take the Institution, and the class to edit, as the route's `extra`: no endpoint reads one
  /// class, so the list hands it over.
  static const classes = '/school-setup/classes';
  static const classForm = '/school-setup/classes/form';
  static const classBulk = '/school-setup/classes/bulk';

  /// The sections of one class (SEC-01) and the form that adds or edits one (SEC-02, SEC-03). Both take what they need
  /// as the route's `extra`: no endpoint reads one class or one section, so the list hands it over.
  static const classSections = '/school-setup/classes/sections';
  static const sectionForm = '/school-setup/classes/sections/form';

  /// Teachers / Staff of the chosen Institution (STF-01), one staff member's profile (STF-03) and the form that adds or
  /// edits one (STF-02, STF-04), which takes the Institution or the staff member as the route's `extra`. The `:id`
  /// pattern is for the router and comes after the form's own location; [staffMember] builds the location of one staff
  /// member.
  static const staff = '/school-setup/staff';
  static const staffForm = '/school-setup/staff/form';
  static const staffMemberPattern = '/school-setup/staff/:id';
  static String staffMember(String id) => '$staff/${Uri.encodeComponent(id)}';

  /// Students of the chosen Institution (STU-01) and the form that adds one (STU-02), which takes the Institution as the
  /// route's `extra`.
  static const students = '/school-setup/students';
  static const studentForm = '/school-setup/students/form';

  /// Moves a student to another section or roll number (STU-08); takes the student as the route's `extra`.
  static const studentMove = '/school-setup/students/move';

  /// The component gallery, registered in debug and profile builds only.
  static const gallery = '/gallery';

  /// Reachable without a session.
  static const Set<String> public = {splash, login, updateRequired};
}
