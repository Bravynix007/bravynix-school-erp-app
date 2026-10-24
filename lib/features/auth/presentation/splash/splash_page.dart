import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shown while the stored session is checked, and when that check could not
/// reach the server (the app is online only, system design 7).
class SplashPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionBloc>().state;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.appName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                if (state is SessionRestoreFailed) ...[
                  InlineMessage.error(loginErrorText(l10n, state.failure)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('splash.retry'),
                    onPressed: () => context.read<SessionBloc>().add(const SessionStarted()),
                    child: Text(MaterialLocalizations.of(context).refreshIndicatorSemanticLabel),
                  ),
                ] else
                  Semantics(label: l10n.loading, child: const CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
