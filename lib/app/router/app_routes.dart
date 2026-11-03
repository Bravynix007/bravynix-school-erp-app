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

  /// The component gallery, registered in debug and profile builds only.
  static const gallery = '/gallery';

  /// Reachable without a session.
  static const Set<String> public = {splash, login, updateRequired};
}
