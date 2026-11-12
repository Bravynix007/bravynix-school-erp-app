import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/optional_date_field.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/place_fields.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The fields a staff member and a student have alike, as the add and edit forms of both show them. Each takes the
/// [keyPrefix] of its form, which names its fields (`staffForm.firstName`), and the [errorOf] the API gave for a field,
/// named as the API names it (`address.line1`). The text is held in the controllers the form owns.

/// The name, gender, date of birth, blood group and nationality.
class PersonalFields extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.firstName,
    required this.lastName,
    required this.nationality,
    required this.gender,
    required this.bloodGroup,
    required this.dateOfBirth,
    required this.errorOf,
    required this.onGenderChosen,
    required this.onBloodGroupChosen,
    required this.onBirthDateChosen,
    required this.usualAge,
    super.key,
  });

  final String keyPrefix;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController nationality;
  final Gender? gender;
  final String? bloodGroup;

  /// A day, `YYYY-MM-DD`.
  final String? dateOfBirth;
  final String? Function(String field) errorOf;
  final ValueChanged<Gender?> onGenderChosen;
  final ValueChanged<String?> onBloodGroupChosen;
  final ValueChanged<String?> onBirthDateChosen;

  /// The age in years the date picker opens near: a child's or a grown-up's.
  final int usualAge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: Key('$keyPrefix.firstName'),
          label: l10n.personFirstName,
          controller: firstName,
          required: true,
          requiredLabel: l10n.fieldRequired,
          error: errorOf('firstName'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: Key('$keyPrefix.lastName'),
          label: l10n.personLastName,
          controller: lastName,
          error: errorOf('lastName'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDropdownField<Gender?>(
          key: Key('$keyPrefix.gender'),
          label: l10n.personGender,
          value: gender,
          error: errorOf('gender'),
          items: [
            DropdownMenuItem<Gender?>(child: Text(l10n.choiceNone)),
            for (final option in Gender.values)
              DropdownMenuItem<Gender?>(value: option, child: Text(genderName(l10n, option))),
          ],
          onChanged: onGenderChosen,
        ),
        const SizedBox(height: AppSpacing.sm),
        OptionalDateField(
          key: Key('$keyPrefix.dateOfBirth'),
          label: l10n.personDateOfBirth,
          day: dateOfBirth,
          hint: l10n.chooseDate,
          clearLabel: l10n.clearDate(l10n.personDateOfBirth),
          firstDay: DateTime(1900),
          lastDay: today.subtract(const Duration(days: 1)),
          initialDay: DateTime(today.year - usualAge),
          error: errorOf('dateOfBirth'),
          onChanged: onBirthDateChosen,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDropdownField<String?>(
          key: Key('$keyPrefix.bloodGroup'),
          label: l10n.personBloodGroup,
          value: bloodGroup,
          error: errorOf('bloodGroup'),
          items: [
            DropdownMenuItem<String?>(child: Text(l10n.choiceNone)),
            for (final group in bloodGroups) DropdownMenuItem<String?>(value: group, child: Text(group)),
          ],
          onChanged: onBloodGroupChosen,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: Key('$keyPrefix.nationality'),
          label: l10n.personNationality,
          controller: nationality,
          error: errorOf('nationality'),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

/// The country code, the mobile number and the alternate number.
class PhoneFields extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.countryCode,
    required this.number,
    required this.alternate,
    required this.errorOf,
    super.key,
  });

  final String keyPrefix;
  final TextEditingController countryCode;
  final TextEditingController number;
  final TextEditingController alternate;
  final String? Function(String field) errorOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: Key('$keyPrefix.mobileCode'),
          label: l10n.phoneCountryCode,
          controller: countryCode,
          mono: true,
          keyboardType: TextInputType.number,
          error: errorOf('mobile.countryCode'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: Key('$keyPrefix.mobileNumber'),
          label: l10n.personMobile,
          controller: number,
          mono: true,
          required: true,
          requiredLabel: l10n.fieldRequired,
          keyboardType: TextInputType.phone,
          error: errorOf('mobile.number') ?? errorOf('mobile'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: Key('$keyPrefix.alternate'),
          label: l10n.personAlternateNumber,
          controller: alternate,
          mono: true,
          keyboardType: TextInputType.phone,
          error: errorOf('alternateNumber'),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

/// The address lines, the country, state and city (through the `PlaceBloc` above), and the pincode.
class AddressFields extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.line1,
    required this.line2,
    required this.pincode,
    required this.errorOf,
    super.key,
  });

  final String keyPrefix;
  final TextEditingController line1;
  final TextEditingController line2;
  final TextEditingController pincode;
  final String? Function(String field) errorOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: Key('$keyPrefix.line1'),
          label: l10n.addressLine1,
          controller: line1,
          error: errorOf('address.line1'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: Key('$keyPrefix.line2'),
          label: l10n.addressLine2,
          controller: line2,
          error: errorOf('address.line2'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        PlaceFields(
          keyPrefix: keyPrefix,
          countryError: errorOf('address.countryId'),
          stateError: errorOf('address.stateId'),
          cityError: errorOf('address.cityId'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: Key('$keyPrefix.pincode'),
          label: l10n.addressPincode,
          controller: pincode,
          mono: true,
          keyboardType: TextInputType.number,
          error: errorOf('address.pincode'),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}
