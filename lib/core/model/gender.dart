import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';

/// The blood groups a record can hold (DDD 9.5).
const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// PRD 11.2: 1 Male, 2 Female, 3 Other.
enum Gender {
  male(1),
  female(2),
  other(3);

  new(this.code);

  final int code;

  static Gender? fromCode(Object? code) {
    for (final gender in values) {
      if (gender.code == code) return gender;
    }
    return null;
  }
}

String genderName(AppLocalizations l10n, Gender gender) => switch (gender) {
  Gender.male => l10n.genderMale,
  Gender.female => l10n.genderFemale,
  Gender.other => l10n.genderOther,
};
