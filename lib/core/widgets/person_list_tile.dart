import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// A row for a student, teacher or parent: avatar, name, one line of detail,
/// and an optional widget on the right (a status chip, an amount).
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
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.listTile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              AppAvatar(name: name, image: image),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: text.titleMedium),
                    if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
              if (onTap != null && trailing == null) const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
