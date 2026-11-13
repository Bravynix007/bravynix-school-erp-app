import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// The name of a guardian's relation to the student in the app's language.
String relationName(AppLocalizations l10n, GuardianRelation relation) => switch (relation) {
  GuardianRelation.father => l10n.relationFather,
  GuardianRelation.mother => l10n.relationMother,
  GuardianRelation.guardian => l10n.relationGuardian,
  GuardianRelation.grandparent => l10n.relationGrandparent,
  GuardianRelation.sibling => l10n.relationSibling,
  GuardianRelation.other => l10n.relationOther,
};
