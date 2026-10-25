import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// A fact on a detail screen: "Admission no." and "STU-2291". The label sits on
/// the left in the secondary colour and the value on the right. When a word of
/// either would not fit beside the other (large text, long values) the value
/// goes under the label, so nothing is cut or broken. `mono` is for IDs and
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide =
              longestWordWidth(context, label, labelStyle) +
                  AppSpacing.md +
                  longestWordWidth(context, value, valueStyle) <=
              constraints.maxWidth;
          // The value is selectable text only on the web and desktop; here it is read as "label, value".
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
              Text(label, style: labelStyle),
              Text(value, style: valueStyle),
            ],
          );
        },
      ),
    );
  }
}
