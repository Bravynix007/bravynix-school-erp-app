import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A white card with a hairline border and 16 px corners. With `onTap` the
/// whole card is one button.
class AppCard extends StatelessWidget {
  const new({required this.child, this.onTap, this.padding = const EdgeInsets.all(AppSpacing.md), super.key});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
