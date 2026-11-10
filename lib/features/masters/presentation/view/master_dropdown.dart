import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// A picker over entries of a master. A [value] that is not in [entries] (the entry was hidden since it was chosen)
/// stays chosen and is shown as no longer offered, instead of looking empty (DDD 10.5); choosing another entry replaces
/// it. With [noneLabel] the field may be left empty.
class MasterDropdown extends StatelessWidget {
  const new({
    required this.label,
    required this.entries,
    required this.value,
    required this.onChanged,
    this.noneLabel,
    this.error,
    this.required = false,
    this.requiredLabel,
    super.key,
  });

  final String label;
  final List<MasterEntry> entries;
  final String? value;
  final String? noneLabel;
  final String? error;
  final bool required;
  final String? requiredLabel;

  /// Null shows the field as not changeable.
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final held = value != null && !entries.any((entry) => entry.id == value);
    return AppDropdownField<String?>(
      label: label,
      value: value,
      required: required,
      requiredLabel: requiredLabel,
      error: error,
      items: [
        if (noneLabel != null) DropdownMenuItem<String?>(child: Text(noneLabel!)),
        if (held) DropdownMenuItem<String?>(value: value, child: Text(AppLocalizations.of(context).masterEntryKept)),
        for (final entry in entries) DropdownMenuItem<String?>(value: entry.id, child: Text(entry.name)),
      ],
      onChanged: onChanged,
    );
  }
}
