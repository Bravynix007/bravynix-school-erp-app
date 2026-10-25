import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// The welcome at the top of a home screen: "Good afternoon" over the person's
/// name, and a line about their day. An accent wash with accent text (4.5:1 or
/// better), not the solid accent, so the module header stays the one loud
/// thing on the screen. The words come from the caller.
class GreetingCard extends StatelessWidget {
  const new({required this.greeting, required this.name, this.message, this.trailing, super.key});

  final String greeting;
  final String name;
  final String? message;

  /// An avatar or a small illustration, at the end.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final nameStyle = theme.textTheme.headlineMedium?.copyWith(color: scheme.onPrimaryContainer);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
                      Semantics(
                        container: true,
                        header: true,
                        child: Text(
                          name,
                          style: nameStyle,
                          textScaler: fitWordScaler(context, name, nameStyle, constraints.maxWidth),
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          message!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                          textScaler: fitWordScaler(
                            context,
                            message!,
                            theme.textTheme.bodyMedium,
                            constraints.maxWidth,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
          ],
        ),
      ),
    );
  }
}
