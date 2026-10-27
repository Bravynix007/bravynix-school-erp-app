import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// The role's name as people see it (PRD 3.2). The Super Admin never signs in on the app.
String roleTitle(AppLocalizations l10n, RoleCode role) => switch (role) {
  RoleCode.superAdmin => l10n.roleSuperAdmin,
  RoleCode.societyOwner => l10n.roleSocietyOwner,
  RoleCode.institutionAdmin => l10n.roleInstitutionAdmin,
  RoleCode.teacherStaff => l10n.roleTeacherStaff,
  RoleCode.studentParent => l10n.roleStudentParent,
};
