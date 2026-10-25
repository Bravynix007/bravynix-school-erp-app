import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A small label in the accent colour: a class name, a role, "Step 2 of 5".
/// It names something; it does not report a status (use `StatusChip`).
class AppTag extends StatelessWidget {
  const new(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer)),
      ),
    );
  }
}
