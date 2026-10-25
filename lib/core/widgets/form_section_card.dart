import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_tag.dart';
import 'package:flutter/material.dart';

/// One numbered part of a long form ("1  Student details", with a "Step 1/5"
/// tag): a card with a heading and the fields under it. The number sits in an
/// accent circle that grows a little with the text, never past 1.5 times, so
/// the heading keeps its room on a small phone.
class FormSectionCard extends StatelessWidget {
  const new({
    required this.number,
    required this.title,
    required this.child,
    this.stepLabel,
    this.subtitle,
    super.key,
  });

  final int number;
  final String title;
  final String? subtitle;

  /// "Step 1/5", shown as a tag under the title.
  final String? stepLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxs),
                          child: Text('$number', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, container: true, child: Text(title, style: theme.textTheme.titleLarge)),
                    if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
                    if (stepLabel != null) ...[const SizedBox(height: AppSpacing.xxs), AppTag(stepLabel!)],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
