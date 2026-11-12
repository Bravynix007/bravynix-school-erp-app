import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks why [name] is deactivated (STU-05) and answers the reason, or null when the sheet is closed without confirming.
Future<LeavingReason?> showStudentLeavingSheet(BuildContext context, {required String name}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<LeavingReason>(
    context: context,
    title: l10n.studentsDeactivateTitle(name),
    builder: (_) => const _LeavingReasons(),
  );
}

class _LeavingReasons extends StatefulWidget {
  const new();

  @override
  State<_LeavingReasons> createState() => _LeavingReasonsState();
}

class _LeavingReasonsState extends State<_LeavingReasons> {
  LeavingReason? _reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String label(LeavingReason reason) => switch (reason) {
      LeavingReason.left => l10n.studentsReasonLeft,
      LeavingReason.mistake => l10n.studentsReasonMistake,
      LeavingReason.other => l10n.studentsReasonOther,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.studentsDeactivateMessage, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        for (final reason in LeavingReason.values)
          AppRadioTile<LeavingReason>(
            key: ValueKey('studentLeaving.${reason.name}'),
            title: label(reason),
            value: reason,
            groupValue: _reason,
            onChanged: (chosen) => setState(() => _reason = chosen),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('studentLeaving.confirm'),
          label: l10n.studentsDeactivate,
          variant: AppButtonVariant.danger,
          onPressed: _reason == null ? null : () => Navigator.of(context).pop(_reason),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: const Key('studentLeaving.cancel'),
          label: l10n.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
