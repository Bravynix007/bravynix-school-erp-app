import 'package:equatable/equatable.dart';

/// The five roles (PRD 3.2). Role 1 (Super Admin) only signs in on the console.
enum RoleCode {
  superAdmin(1),
  societyOwner(2),
  institutionAdmin(3),
  teacherStaff(4),
  studentParent(5);

  new(this.code);

  final int code;

  static RoleCode? fromCode(int? code) {
    for (final role in values) {
      if (role.code == code) return role;
    }
    return null;
  }
}

class Person extends Equatable {
  const new({
    required this.id,
    required this.email,
    required this.preferredLanguage,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String email;

  /// A person added by email alone has no name yet (API design 6.3).
  final String? firstName;
  final String? lastName;

  /// en, hi, kn, ml, mr, ta or te (PRD 11.3).
  final String preferredLanguage;

  /// First and last name, or the email while neither is set.
  String get displayName {
    final name = [firstName, lastName].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return name.isEmpty ? email : name;
  }

  /// What a greeting calls the person.
  String get greetingName => firstName == null || firstName!.isEmpty ? email : firstName!;

  @override
  List<Object?> get props => [id, email, firstName, lastName, preferredLanguage];
}

/// A child a Student / Parent context covers (API design 6.3).
class LinkedChild extends Equatable {
  const new({
    required this.studentId,
    required this.firstName,
    required this.institutionName,
    required this.isBlocked,
    this.lastName,
    this.className,
    this.sectionName,
  });

  final String studentId;
  final String firstName;
  final String? lastName;
  final String institutionName;

  /// The current placement; both are null while the child has none.
  final String? className;
  final String? sectionName;

  /// The child's profile is blocked, or its Institution has its students blocked: the child's data answers 403.
  final bool isBlocked;

  /// First and last name, as the child is called in a list.
  String get fullName => [firstName, lastName].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  /// "7th - A", "7th" while the section is not known, or empty while the child has no placement.
  String get classSection => [className, sectionName].whereType<String>().where((part) => part.isNotEmpty).join(' - ');

  @override
  List<Object?> get props => [studentId, firstName, lastName, institutionName, className, sectionName, isBlocked];
}

/// One role the person can act in, with its scope (API design 6.3).
class AuthContext extends Equatable {
  const new({
    required this.role,
    this.societyId,
    this.societyName,
    this.staffMemberId,
    this.homeInstitutionId,
    this.children = const [],
    this.isBlocked = false,
  });

  final RoleCode role;

  /// Set for roles 2 to 4; absent for role 5, which spans Societies.
  final String? societyId;
  final String? societyName;
  final String? staffMemberId;
  final String? homeInstitutionId;

  /// Role 5 only.
  final List<LinkedChild> children;
  final bool isBlocked;

  @override
  List<Object?> get props => [role, societyId, societyName, staffMemberId, homeInstitutionId, children, isBlocked];
}

/// The answer to AUTH-01: a code was sent if the email is registered.
class OtpRequested extends Equatable {
  const new({required this.resendAfter, required this.expiresIn});

  final Duration resendAfter;
  final Duration expiresIn;

  @override
  List<Object?> get props => [resendAfter, expiresIn];
}

/// A signed-in session as the app knows it (AUTH-02).
class AuthSession extends Equatable {
  const new({required this.person, required this.contexts, this.activeContext});

  final Person person;
  final List<AuthContext> contexts;

  /// Set by the server when there is exactly one context; until the person
  /// chooses one (AUTH-06) it is null and the app shows the role chooser
  /// (API design 6.3, build plan phase 1).
  final AuthContext? activeContext;

  AuthSession withActiveContext(AuthContext context) =>
      AuthSession(person: person, contexts: contexts, activeContext: context);

  @override
  List<Object?> get props => [person, contexts, activeContext];
}
