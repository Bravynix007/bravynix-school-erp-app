import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Due, Paid or Cancelled; a Due past its date also says Overdue, so the colour is never the only signal.
class DueStatusChips extends StatelessWidget {
  const new({required this.due, required this.today, super.key});

  final PlatformDueLine due;

  /// The school day in IST.
  final String today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, tone) = switch (due.status) {
      DueStatus.due => (l10n.dueStatusDue, StatusTone.warning),
      DueStatus.paid => (l10n.dueStatusPaid, StatusTone.success),
      DueStatus.cancelled => (l10n.dueStatusCancelled, StatusTone.neutral),
    };
    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        StatusChip(label: label, tone: tone),
        if (due.isOverdue(today)) StatusChip(label: l10n.dueStatusOverdue, tone: StatusTone.error),
      ],
    );
  }
}
