import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/choice_chip_group.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_text.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The Institution chosen if [institutions] offers it, else the only one it offers, else null: one that is no longer
/// offered must be chosen again.
String? offeredInstitution(List<InstitutionSummary> institutions, String? chosen) {
  final ids = [for (final institution in institutions) institution.id];
  if (ids.contains(chosen)) return chosen;
  return ids.length == 1 ? ids.single : null;
}

/// Who an event belongs to: the whole Society or one Institution, which is then chosen from [institutions]. Without
/// [onScope] the scope is fixed (an Admin's events are for an Institution) and only the Institution is chosen. The
/// keys are `<keyPrefix>.scope` and `<keyPrefix>.institution`.
class EventScopeFields extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.scope,
    required this.institutions,
    required this.institutionId,
    required this.onInstitution,
    this.onScope,
    this.error,
    super.key,
  });

  final String keyPrefix;
  final EventScope scope;
  final ValueChanged<EventScope>? onScope;
  final List<InstitutionSummary> institutions;

  /// The Institution shown as chosen, as [offeredInstitution] gives it.
  final String? institutionId;
  final ValueChanged<String?> onInstitution;

  /// What to say under the Institution, when a refusal names it.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onScope case final onScope?) ...[
          ChoiceChipGroup<EventScope>(
            key: Key('$keyPrefix.scope'),
            options: EventScope.values,
            labelOf: (scope) => EventText.scope(l10n, scope),
            selected: scope,
            onSelected: onScope,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (scope == EventScope.institution)
          AppDropdownField<String>(
            key: Key('$keyPrefix.institution'),
            label: l10n.eventFieldInstitution,
            value: institutionId,
            required: true,
            requiredLabel: l10n.fieldRequired,
            error: error,
            items: [
              for (final institution in institutions)
                DropdownMenuItem(value: institution.id, child: Text(institution.name)),
            ],
            onChanged: onInstitution,
          ),
      ],
    );
  }
}
