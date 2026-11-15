import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

String employmentName(AppLocalizations l10n, EmploymentType type) => switch (type) {
  EmploymentType.fullTime => l10n.employmentFullTime,
  EmploymentType.partTime => l10n.employmentPartTime,
  EmploymentType.visiting => l10n.employmentVisiting,
  EmploymentType.contract => l10n.employmentContract,
};
