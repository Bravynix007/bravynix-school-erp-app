import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// The name of a gender in the app's language.
String genderName(AppLocalizations l10n, Gender gender) => switch (gender) {
  Gender.male => l10n.genderMale,
  Gender.female => l10n.genderFemale,
  Gender.other => l10n.genderOther,
};
