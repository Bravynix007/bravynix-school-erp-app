import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// The accent's name as people hear it from a screen reader (PRD 6.3).
String accentName(AppLocalizations l10n, AppAccent accent) => switch (accent) {
  AppAccent.teal => l10n.accentTeal,
  AppAccent.forestGreen => l10n.accentForestGreen,
  AppAccent.royalPurple => l10n.accentRoyalPurple,
  AppAccent.steelBlue => l10n.accentSteelBlue,
  AppAccent.rosePink => l10n.accentRosePink,
  AppAccent.sunsetOrange => l10n.accentSunsetOrange,
  AppAccent.darkCyan => l10n.accentDarkCyan,
};
