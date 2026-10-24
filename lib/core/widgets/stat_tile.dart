import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

/// A KPI tile: a label, one big figure and an optional note under it
/// ("+3 this week"). Figures are tabular, so a column of tiles lines up.
class StatTile extends StatelessWidget {
  const new({required this.label, required this.value, this.note, this.icon, this.onTap, super.key});

  final String label;
  final String value;
  final String? note;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: Text(label, style: text.bodySmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: text.headlineMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (note != null) Text(note!, style: text.bodySmall?.copyWith(color: AppColors.inkTertiary)),
        ],
      ),
    );
  }
}
