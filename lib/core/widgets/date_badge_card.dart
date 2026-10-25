import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// An event or holiday on a list: a calendar badge (month over day number)
/// beside a title and a note ("Annual Day", "Auditorium, 10 am"). The badge is
/// decoration; the screen reader says the full date, then the text. At large
/// text, when a word would break beside the badge, the text goes under it.
class DateBadgeCard extends StatelessWidget {
  const new({required this.date, required this.title, this.subtitle, this.trailing, this.onTap, super.key});

  final DateTime date;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// What a trailing icon or chip is assumed to need beside the text.
  static const double _trailingRoom = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final month = DateFormat.MMM(locale).format(date).toUpperCase();
    final spoken = DateFormat.yMMMMEEEEd(locale).format(date);
    final badge = Semantics(
      label: spoken,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(month, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer)),
                Text(
                  '${date.day}',
                  style: theme.textTheme.headlineMedium?.copyWith(color: scheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
      ],
    );
    return AppCard(
      onTap: onTap,
      child: MergeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final badgeWidth = [
              56.0,
              measureText(context, month, theme.textTheme.labelSmall),
              measureText(context, '${date.day}', theme.textTheme.headlineMedium),
            ].reduce((a, b) => a > b ? a : b);
            final longest = [
              longestWordWidth(context, title, theme.textTheme.titleMedium),
              if (subtitle != null) longestWordWidth(context, subtitle!, theme.textTheme.bodySmall),
            ].reduce((a, b) => a > b ? a : b);
            final room =
                constraints.maxWidth -
                (badgeWidth + 2 * AppSpacing.xs) -
                AppSpacing.sm -
                (trailing == null ? 0 : _trailingRoom);
            if (longest <= room) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: words),
                  if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
                ],
              );
            }
            // A word would break beside the badge (large text): the text goes under it.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    badge,
                    const Spacer(),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                words,
              ],
            );
          },
        ),
      ),
    );
  }
}
