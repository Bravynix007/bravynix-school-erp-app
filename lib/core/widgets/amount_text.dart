import 'package:bravynix_school_erp/core/format/money.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// An amount of money from the API's decimal string ("124500.00") as
/// `₹1,24,500.00`, in tabular figures so a column lines up. It never wraps
/// (₹1,24,500 split over two lines can be misread); if the room is too small it
/// is drawn smaller. A malformed amount throws, so a wrong figure is never shown.
///
/// Screens with translated spoken forms can pass [semanticsLabel].
///
/// When the first money screen is built, parse amounts as the API response is
/// decoded (a small `Money` value type), so that a bad value becomes that
/// screen's error state and this widget takes the parsed value.
class AmountText extends StatelessWidget {
  const new(
    this.amount, {
    this.style,
    this.color,
    this.alignment = AlignmentDirectional.centerStart,
    this.semanticsLabel,
    super.key,
  });

  final String amount;

  /// Defaults to the 16 px tabular number style.
  final TextStyle? style;
  final Color? color;
  final AlignmentGeometry alignment;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final base = style ?? AppTextStyles.number;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        formatRupees(amount),
        maxLines: 1,
        softWrap: false,
        semanticsLabel: semanticsLabel,
        style: base.copyWith(color: color ?? Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

/// A line of a fee breakdown: what, and how much ("Tuition  ₹40,000.00"). The
/// name wraps; the amount does not. When the amount leaves too little room for
/// the longest word of the name, the amount goes under the name.
class AmountSplitRow extends StatelessWidget {
  const new({required this.label, required this.amount, this.emphasis = false, this.note, this.amountColor, super.key});

  final String label;
  final String amount;

  /// A total: both parts in the heavier weight.
  final bool emphasis;
  final String? note;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelStyle = (emphasis ? text.titleMedium : text.bodyLarge)!;
    final amountStyle = emphasis ? AppTextStyles.number.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.number;
    final amountWidget = AmountText(
      amount,
      style: amountStyle,
      color: amountColor,
      alignment: AlignmentDirectional.centerEnd,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.listTile - AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final amountWidth = measureText(context, formatRupees(amount), amountStyle);
            final sideBySide =
                longestWordWidth(context, label, labelStyle) + AppSpacing.md + amountWidth <= constraints.maxWidth;
            final words = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (note != null) Text(note!, style: text.bodySmall),
              ],
            );
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: words),
                  const SizedBox(width: AppSpacing.md),
                  amountWidget,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                words,
                const SizedBox(height: AppSpacing.xxs),
                amountWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}
