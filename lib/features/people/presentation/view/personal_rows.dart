import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/person_names.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The personal facts of a person that a profile shows when they are set: gender, date of birth, blood group and
/// nationality.
class PersonalRows extends StatelessWidget {
  const new({this.gender, this.dateOfBirth, this.bloodGroup, this.nationality, super.key});

  final Gender? gender;

  /// `YYYY-MM-DD`.
  final String? dateOfBirth;
  final String? bloodGroup;
  final String? nationality;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gender case final gender?) KeyValueRow(label: l10n.personGender, value: genderName(l10n, gender)),
        if (dateOfBirth case final day?) KeyValueRow(label: l10n.personDateOfBirth, value: Formatters.schoolDate(day)),
        if (bloodGroup case final group?) KeyValueRow(label: l10n.personBloodGroup, value: group),
        if (nationality case final nationality?) KeyValueRow(label: l10n.personNationality, value: nationality),
      ],
    );
  }
}
