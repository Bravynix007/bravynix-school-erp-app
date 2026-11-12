import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// What the server's second looks say (`meta.warnings` of a student write), a sentence for each one it asked for; a
/// warning this version does not know is left out.
List<String> studentWarningLines(AppLocalizations l10n, List<String> warnings) => [
  for (final warning in warnings)
    ?switch (warning) {
      'SECTION_OVER_CAPACITY' => l10n.studentWarnOverCapacity,
      'AADHAAR_EXISTS_IN_SOCIETY' => l10n.studentWarnAadhaarElsewhere,
      _ => null,
    },
];
