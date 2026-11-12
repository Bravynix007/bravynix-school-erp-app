import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_form_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The names the API gives the fields of the education and emergency contact rows, so the form shows an error under
/// the row and field it names: `educations[1].degree`, `emergencyContacts[0].phone.number`.
const educationFields = ['degree', 'qualification', 'specialization', 'institutionName', 'yearOfPassing'];
const contactFields = [
  'contactName',
  'relation',
  'phone',
  'phone.countryCode',
  'phone.number',
  'alternateNumber',
  'isPrimary',
];

/// One education line. The row owns its text controllers and tells the [StaffFormBloc] what is typed, so the bloc holds
/// the whole form while the row is the only one that touches the text field.
class EducationRow extends StatefulWidget {
  const new({required this.entry, required this.index, required this.errorOf, super.key});

  final EducationEntry entry;

  /// The row's place in the list, from 0: how the API names it.
  final int index;

  /// The error the API gave for a field of this row (`degree`), if any.
  final String? Function(String field) errorOf;

  @override
  State<EducationRow> createState() => _EducationRowState();
}

class _EducationRowState extends State<EducationRow> {
  late final _degree = TextEditingController(text: widget.entry.texts.degree);
  late final _qualification = TextEditingController(text: widget.entry.texts.qualification);
  late final _specialization = TextEditingController(text: widget.entry.texts.specialization);
  late final _school = TextEditingController(text: widget.entry.texts.institutionName);
  late final _year = TextEditingController(text: widget.entry.texts.yearOfPassing);

  @override
  void dispose() {
    for (final controller in [_degree, _qualification, _specialization, _school, _year]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed() => context.read<StaffFormBloc>().add(
    StaffEducationEdited(
      widget.entry.id,
      EducationTexts(
        degree: _degree.text,
        qualification: _qualification.text,
        specialization: _specialization.text,
        institutionName: _school.text,
        yearOfPassing: _year.text,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final number = widget.index + 1;
    final id = widget.entry.id;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.staffEducationRow(number), style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            key: Key('staffForm.education.$id.degree'),
            label: l10n.staffEducationDegree,
            controller: _degree,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: widget.errorOf('degree'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.education.$id.qualification'),
            label: l10n.staffEducationQualification,
            controller: _qualification,
            error: widget.errorOf('qualification'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.education.$id.specialization'),
            label: l10n.staffEducationSpecialization,
            controller: _specialization,
            error: widget.errorOf('specialization'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.education.$id.institutionName'),
            label: l10n.staffEducationSchool,
            controller: _school,
            error: widget.errorOf('institutionName'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.education.$id.yearOfPassing'),
            label: l10n.staffEducationYear,
            controller: _year,
            mono: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            error: widget.errorOf('yearOfPassing'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: Key('staffForm.education.$id.remove'),
            label: l10n.staffRemoveEducation(number),
            icon: Icons.delete_outline,
            variant: AppButtonVariant.text,
            size: AppButtonSize.medium,
            onPressed: () => context.read<StaffFormBloc>().add(StaffEducationRemoved(id)),
          ),
        ],
      ),
    );
  }
}

/// One emergency contact; see [EducationRow].
class ContactRow extends StatefulWidget {
  const new({required this.entry, required this.index, required this.errorOf, super.key});

  final ContactEntry entry;
  final int index;
  final String? Function(String field) errorOf;

  @override
  State<ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<ContactRow> {
  late final _name = TextEditingController(text: widget.entry.texts.contactName);
  late final _relation = TextEditingController(text: widget.entry.texts.relation);
  late final _code = TextEditingController(text: widget.entry.texts.countryCode);
  late final _number = TextEditingController(text: widget.entry.texts.number);
  late final _alternate = TextEditingController(text: widget.entry.texts.alternateNumber);

  @override
  void dispose() {
    for (final controller in [_name, _relation, _code, _number, _alternate]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed() => context.read<StaffFormBloc>().add(
    StaffContactEdited(
      widget.entry.id,
      ContactTexts(
        contactName: _name.text,
        relation: _relation.text,
        countryCode: _code.text,
        number: _number.text,
        alternateNumber: _alternate.text,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final number = widget.index + 1;
    final id = widget.entry.id;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.staffContactRow(number), style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            key: Key('staffForm.contact.$id.name'),
            label: l10n.staffContactName,
            controller: _name,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: widget.errorOf('contactName'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.contact.$id.relation'),
            label: l10n.staffContactRelationLabel,
            controller: _relation,
            error: widget.errorOf('relation'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.contact.$id.code'),
            label: l10n.phoneCountryCode,
            controller: _code,
            mono: true,
            keyboardType: TextInputType.number,
            error: widget.errorOf('phone.countryCode'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.contact.$id.number'),
            label: l10n.phoneNumber,
            controller: _number,
            mono: true,
            required: true,
            requiredLabel: l10n.fieldRequired,
            keyboardType: TextInputType.phone,
            error: widget.errorOf('phone.number') ?? widget.errorOf('phone'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('staffForm.contact.$id.alternate'),
            label: l10n.personAlternateNumber,
            controller: _alternate,
            mono: true,
            keyboardType: TextInputType.phone,
            error: widget.errorOf('alternateNumber'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.done,
          ),
          AppSwitchTile(
            key: Key('staffForm.contact.$id.primary'),
            title: l10n.staffPrimaryContact,
            value: widget.entry.isPrimary,
            onChanged: (value) =>
                context.read<StaffFormBloc>().add(StaffContactPrimaryChosen(widget.entry.id, isPrimary: value)),
          ),
          if (widget.errorOf('isPrimary') case final message?)
            Text(
              message,
              key: Key('staffForm.contact.$id.primaryError'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: Key('staffForm.contact.$id.remove'),
            label: l10n.staffRemoveContact(number),
            icon: Icons.delete_outline,
            variant: AppButtonVariant.text,
            size: AppButtonSize.medium,
            onPressed: () => context.read<StaffFormBloc>().add(StaffContactRemoved(id)),
          ),
        ],
      ),
    );
  }
}
