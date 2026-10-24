import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// "Added by Asha Rao on 3 Mar" / "Updated by ..." at the foot of a detail
/// screen. The screen builds the lines (they carry names, dates and words
/// that depend on the language).
class AuditFooter extends StatelessWidget {
  const new({required this.lines, super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTertiary);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final line in lines) Text(line, style: style)],
      ),
    );
  }
}
