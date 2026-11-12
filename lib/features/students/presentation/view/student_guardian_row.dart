import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/features/students/domain/student_draft.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_form_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The names the API gives the fields of a guardian row, so the form shows an error under the row and field it names:
/// `guardians[1].firstName`, `guardians[0].phone.number`.
const guardianFields = [
  'firstName',
  'lastName',
  'relation',
  'phone',
  'phone.countryCode',
  'phone.number',
  'alternatePhone',
  'email',
  'occupation',
  'isPrimary',
  'isEmergencyContact',
];

String relationName(AppLocalizations l10n, GuardianRelation relation) => switch (relation) {
  GuardianRelation.father => l10n.relationFather,
  GuardianRelation.mother => l10n.relationMother,
  GuardianRelation.guardian => l10n.relationGuardian,
  GuardianRelation.grandparent => l10n.relationGrandparent,
  GuardianRelation.sibling => l10n.relationSibling,
  GuardianRelation.other => l10n.relationOther,
};

/// One guardian. The row owns its text controllers and tells the [StudentFormBloc] what is typed, so the bloc holds the
/// whole form while the row is the only one that touches the text fields.
class GuardianRow extends StatefulWidget {
  const new({required this.entry, required this.index, required this.canRemove, required this.errorOf, super.key});

  final GuardianEntry entry;

  /// The row's place in the list, from 0: how the API names it.
  final int index;

  /// A student keeps at least one guardian.
  final bool canRemove;

  /// The error the API gave for a field of this row (`firstName`), if any.
  final String? Function(String field) errorOf;

  @override
  State<GuardianRow> createState() => _GuardianRowState();
}

class _GuardianRowState extends State<GuardianRow> {
  late final _firstName = TextEditingController(text: widget.entry.texts.firstName);
  late final _lastName = TextEditingController(text: widget.entry.texts.lastName);
  late final _code = TextEditingController(text: widget.entry.texts.countryCode);
  late final _number = TextEditingController(text: widget.entry.texts.number);
  late final _alternate = TextEditingController(text: widget.entry.texts.alternatePhone);
  late final _email = TextEditingController(text: widget.entry.texts.email);
  late final _occupation = TextEditingController(text: widget.entry.texts.occupation);

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _code, _number, _alternate, _email, _occupation]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changed() => context.read<StudentFormBloc>().add(
    StudentGuardianEdited(
      widget.entry.id,
      GuardianTexts(
        firstName: _firstName.text,
        lastName: _lastName.text,
        countryCode: _code.text,
        number: _number.text,
        alternatePhone: _alternate.text,
        email: _email.text,
        occupation: _occupation.text,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StudentFormBloc>();
    final number = widget.index + 1;
    final entry = widget.entry;
    final id = entry.id;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.studentGuardianRow(number), style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            key: Key('studentForm.guardian.$id.firstName'),
            label: l10n.personFirstName,
            controller: _firstName,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: widget.errorOf('firstName'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('studentForm.guardian.$id.lastName'),
            label: l10n.personLastName,
            controller: _lastName,
            error: widget.errorOf('lastName'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDropdownField<GuardianRelation?>(
            key: Key('studentForm.guardian.$id.relation'),
            label: l10n.studentGuardianRelation,
            value: entry.relation,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: widget.errorOf('relation'),
            items: [
              DropdownMenuItem<GuardianRelation?>(child: Text(l10n.choiceNone)),
              for (final relation in GuardianRelation.values)
                DropdownMenuItem<GuardianRelation?>(value: relation, child: Text(relationName(l10n, relation))),
            ],
            onChanged: (relation) => bloc.add(StudentGuardianRelationChosen(id, relation)),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('studentForm.guardian.$id.code'),
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
            key: Key('studentForm.guardian.$id.number'),
            label: l10n.personMobile,
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
            key: Key('studentForm.guardian.$id.alternate'),
            label: l10n.personAlternateNumber,
            controller: _alternate,
            mono: true,
            keyboardType: TextInputType.phone,
            error: widget.errorOf('alternatePhone'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('studentForm.guardian.$id.email'),
            label: l10n.studentGuardianEmail,
            controller: _email,
            helper: l10n.studentGuardianEmailHelper,
            keyboardType: TextInputType.emailAddress,
            error: widget.errorOf('email'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: Key('studentForm.guardian.$id.occupation'),
            label: l10n.studentGuardianOccupation,
            controller: _occupation,
            error: widget.errorOf('occupation'),
            onChanged: (_) => _changed(),
            textInputAction: TextInputAction.done,
          ),
          AppSwitchTile(
            key: Key('studentForm.guardian.$id.primary'),
            title: l10n.studentGuardianPrimary,
            value: entry.isPrimary,
            // Exactly one guardian is primary: another is chosen to take the mark, so it is never switched off.
            onChanged: entry.isPrimary ? null : (_) => bloc.add(StudentGuardianPrimaryChosen(id)),
          ),
          if (widget.errorOf('isPrimary') case final message?)
            Text(
              message,
              key: Key('studentForm.guardian.$id.primaryError'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          AppSwitchTile(
            key: Key('studentForm.guardian.$id.emergency'),
            title: l10n.studentGuardianEmergency,
            value: entry.isEmergencyContact,
            onChanged: (value) => bloc.add(StudentGuardianEmergencyChosen(id, isEmergencyContact: value)),
          ),
          if (widget.canRemove) ...[
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: Key('studentForm.guardian.$id.remove'),
              label: l10n.studentRemoveGuardian(number),
              icon: Icons.delete_outline,
              variant: AppButtonVariant.text,
              size: AppButtonSize.medium,
              onPressed: () => bloc.add(StudentGuardianRemoved(id)),
            ),
          ],
        ],
      ),
    );
  }
}
