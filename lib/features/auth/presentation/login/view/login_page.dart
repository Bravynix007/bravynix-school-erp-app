import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/cubit/login_cubit.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/code_form.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/email_form.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(getIt<AuthRepository>()),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<SessionBloc>().state;
    final endReason = session is SessionUnauthenticated ? session.endReason : null;

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => current.status == LoginStatus.success && current.session != null,
      listener: (context, state) => context.read<SessionBloc>().add(SessionSignedIn(state.session!)),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 32),
                    if (endReason != null) ...[
                      InlineMessage.info(_endReasonText(l10n, endReason)),
                      const SizedBox(height: 16),
                    ],
                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (previous, current) => previous.step != current.step,
                      builder: (context, state) => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: state.step == LoginStep.email ? const EmailForm() : const CodeForm(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _endReasonText(AppLocalizations l10n, SessionEndReason reason) => switch (reason) {
    SessionEndReason.expired => l10n.sessionEndedExpired,
    SessionEndReason.blocked => l10n.sessionEndedBlocked,
    SessionEndReason.signedOutElsewhere => l10n.sessionEndedElsewhere,
    SessionEndReason.adminRevoked => l10n.sessionEndedAdminRevoked,
    SessionEndReason.emailChanged => l10n.sessionEndedEmailChanged,
    SessionEndReason.other => l10n.sessionEndedGeneric,
  };
}
