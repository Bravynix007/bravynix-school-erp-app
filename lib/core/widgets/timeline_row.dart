import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// One event in a vertical history (a fee payment, an admission step, a leave
/// request): a dot or icon on a line, then the title, a note and the time.
/// Stack rows in a column; the first and last draw only half the line.
class TimelineRow extends StatelessWidget {
  const new({
    required this.title,
    this.subtitle,
    this.time,
    this.icon,
    this.done = true,
    this.isFirst = false,
    this.isLast = false,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// "3 Mar, 10:15 am" -- built by the screen, in the person's language.
  final String? time;

  /// In the marker. A plain dot when null.
  final IconData? icon;

  /// A finished step is the accent; a step still to come is an outline.
  final bool done;
  final bool isFirst;
  final bool isLast;

  static const _marker = 28.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    return MergeSemantics(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _marker,
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Expanded(child: _Line(visible: !isFirst)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? scheme.primary : AppColors.surface,
                        border: Border.all(color: done ? scheme.primary : AppColors.fieldBorder, width: 2),
                      ),
                      child: SizedBox.square(
                        dimension: icon == null ? 14 : _marker - 4,
                        child: icon == null
                            ? null
                            : Icon(icon, size: 16, color: done ? scheme.onPrimary : AppColors.inkSecondary),
                      ),
                    ),
                    Expanded(flex: 4, child: _Line(visible: !isLast)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs, bottom: isLast ? 0 : AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    if (subtitle != null) Text(subtitle!, style: text.bodyMedium),
                    if (time != null) Text(time!, style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const new({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(width: 2, child: visible ? const ColoredBox(color: AppColors.border) : null),
  );
}
