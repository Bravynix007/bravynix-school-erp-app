import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A row in a menu or settings list: icon, title, optional detail, chevron.
/// `destructive` turns it red for Log out and Delete.
class MenuListTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colour = destructive ? AppColors.error : AppColors.ink;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.listTile),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(icon, color: destructive ? AppColors.error : AppColors.inkSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium?.copyWith(color: colour)),
                      if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                    ],
                  ),
                ),
                ?trailing,
                if (trailing == null && !destructive && onTap != null)
                  const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
