import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The API answered 426 APP_UPDATE_REQUIRED (API design 5.2). Nothing else
/// works until the app is updated, so there is no way back.
class UpdateRequiredPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.system_update_outlined, size: 48),
                const SizedBox(height: 16),
                Text(l10n.updateRequiredTitle, style: textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(l10n.updateRequiredBody, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
