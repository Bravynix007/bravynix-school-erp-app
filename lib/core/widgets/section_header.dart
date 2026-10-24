import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// A section title with an optional "See all" style action on the right.
class SectionHeader extends StatelessWidget {
  const new({required this.title, this.actionLabel, this.onAction, super.key})
    : assert((actionLabel == null) == (onAction == null), 'Give both actionLabel and onAction, or neither');

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: AppSpacing.xs),
          AppButton(
            label: actionLabel!,
            onPressed: onAction,
            variant: AppButtonVariant.text,
            size: AppButtonSize.small,
          ),
        ],
      ],
    );
  }
}
