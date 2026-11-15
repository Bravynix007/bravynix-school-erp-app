import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/features/people/domain/place_names.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// The name of a gender in the app's language.
String genderName(AppLocalizations l10n, Gender gender) => switch (gender) {
  Gender.male => l10n.genderMale,
  Gender.female => l10n.genderFemale,
  Gender.other => l10n.genderOther,
};

/// The address as a profile shows it, a line each for the two address lines, the places ("Bengaluru, Karnataka,
/// India") and the pincode; empty when the address holds nothing.
String addressText(Address address, PlaceNames places) => [
  ?address.line1,
  ?address.line2,
  [?places.city, ?places.state, ?places.country].join(', '),
  ?address.pincode,
].where((line) => line.isNotEmpty).join('\n');
