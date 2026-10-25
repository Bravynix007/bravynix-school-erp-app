import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// A fact on a detail screen: "Admission no." and "STU-2291". The label sits on
/// the left in the secondary colour and the value on the right, in equal halves so
/// values line up down a card. When the longest word of either would not fit
/// its half (large text, long values) the value goes under the label, so nothing
/// is cut or broken. The pair is one stop for a screen reader: "label, value". `mono` is for IDs and
/// references.
class KeyValueRow extends StatelessWidget {
  const new({required this.label, required this.value, this.mono = false, super.key});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelStyle = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final valueStyle = (mono ? AppTextStyles.code : text.bodyMedium)?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
    // One stop for a screen reader: "label, value".
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The two columns are equal, so the values line up down a card; each longest word has to fit its half.
            final half = (constraints.maxWidth - AppSpacing.md) / 2;
            final sideBySide =
                longestWordWidth(context, label, labelStyle) <= half &&
                longestWordWidth(context, value, valueStyle) <= half;
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label, style: labelStyle)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(value, textAlign: TextAlign.end, style: valueStyle),
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: labelStyle,
                  textScaler: fitWordScaler(context, label, labelStyle, constraints.maxWidth),
                ),
                Text(
                  value,
                  style: valueStyle,
                  textScaler: fitWordScaler(context, value, valueStyle, constraints.maxWidth),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
