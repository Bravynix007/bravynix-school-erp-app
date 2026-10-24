import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:flutter/material.dart';

/// A row for a student, teacher or parent: avatar, name, one line of detail,
/// and an optional widget on the right (a status chip, an amount). At large
/// text the right-hand widget moves under the name, so the name keeps its
/// width. The row reads as one item: name, detail, then the trailing widget.
class PersonListTile extends StatelessWidget {
  const new({required this.name, this.subtitle, this.image, this.trailing, this.onTap, super.key});

  final String name;
  final String? subtitle;
  final ImageProvider? image;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stacked = MediaQuery.textScalerOf(context).scale(14) / 14 >= 1.3;
    return Semantics(
      button: onTap != null,
      child: RingInkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.listTile),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: MergeSemantics(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: AppAvatar(name: name, image: image),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: text.titleMedium),
                        if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                        if (stacked && trailing != null) ...[const SizedBox(height: AppSpacing.xxs), trailing!],
                      ],
                    ),
                  ),
                  if (!stacked && trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: trailing!),
                  ],
                  if (onTap != null && trailing == null) const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
