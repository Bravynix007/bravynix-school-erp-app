import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The screen around a body that is not a student form: a placeholder, an empty or a failed state, under [title].
class StudentFrame extends StatelessWidget {
  const new({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: title, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(child: child),
        ],
      ),
    );
  }
}
