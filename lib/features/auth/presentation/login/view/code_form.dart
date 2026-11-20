import 'dart:async';

import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/bloc/login_bloc.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/code_entry.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Check your email": one 6-digit field with one-time-code autofill, Verify,
/// a resend timer and "Use a different email".
class CodeForm extends StatefulWidget {
  const new({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  State<CodeForm> createState() => _CodeFormState();
}

class _CodeFormState extends State<CodeForm> {
  final _code = TextEditingController();
  Timer? _ticker;
  bool _showIncompleteCode = false;

  @override
  void initState() {
    super.initState();
    // Repaints the resend countdown once a second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    final bloc = context.read<LoginBloc>();
    if (bloc.state.isSubmitting || bloc.state.isCodeDead) return;
    if (_code.text.length != CodeEntry.length) {
      setState(() => _showIncompleteCode = true);
      return;
    }
    bloc.add(LoginCodeSubmitted(_code.text));
  }

  void _resend() {
    _code.clear();
    setState(() => _showIncompleteCode = false);
    context.read<LoginBloc>().add(const LoginResendRequested());
  }

  void _onCodeChanged(String code) {
    if (_showIncompleteCode) setState(() => _showIncompleteCode = false);
    if (code.length == CodeEntry.length) _submit();
  }

  void _startAgain() => context.read<LoginBloc>().add(const LoginEmailReset());

  static String _mmss(Duration value) => '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocConsumer<LoginBloc, LoginState>(
      listenWhen: (previous, current) => current.failure != null && previous.failure != current.failure,
      listener: (context, state) => _code.clear(),
      builder: (context, state) {
        final left = state.resendAvailableAt?.difference(widget.clock());
        final waiting = left != null && left > Duration.zero;
        final codeError = state.failure?.code == 'OTP_INVALID'
            ? loginErrorText(l10n, state.failure!)
            : _showIncompleteCode
            ? l10n.codeRequired
            : null;

        // Locked out: no code field and no Resend, only a way back to the start.
        if (state.failure case final locked? when locked.isLockedOut) {
          return _LockedPanel(message: loginErrorText(l10n, locked), onStartAgain: _startAgain);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: AuthGlyph(Icons.mail_outline)),
            const SizedBox(height: AppSpacing.lg),
            AuthHeading(title: l10n.codeTitle, subtitle: l10n.codeSubtitle),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.email,
              style: theme.textTheme.labelLarge?.copyWith(color: AuthColors.brand, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (state.failure != null && state.failure!.code != 'OTP_INVALID') ...[
              InlineMessage.error(loginErrorText(l10n, state.failure!)),
              const SizedBox(height: AppSpacing.md),
            ],
            CodeEntry(
              controller: _code,
              label: l10n.codeLabel,
              enabled: !state.isSubmitting && !state.isCodeDead,
              invalid: codeError != null,
              onChanged: _onCodeChanged,
              onSubmitted: _submit,
            ),
            if (codeError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(codeError),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('login.verify'),
              label: l10n.verify,
              icon: Icons.arrow_forward,
              iconAlignment: IconAlignment.end,
              loading: state.isSubmitting,
              onPressed: state.isCodeDead ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Wraps rather than overflows: labels grow up to 40% in other languages.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                if (waiting)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      l10n.resendIn(_mmss(left)),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkSecondary),
                    ),
                  )
                else
                  TextButton(
                    key: const Key('login.resend'),
                    onPressed: state.isSubmitting ? null : _resend,
                    child: Text(l10n.resendCode),
                  ),
                TextButton(
                  key: const Key('login.changeEmail'),
                  onPressed: state.isSubmitting ? null : _startAgain,
                  child: Text(l10n.useDifferentEmail),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// The email is locked, so the code step has nothing left to offer but "Start
/// again", which takes focus so a keyboard or screen reader user lands on it.
class _LockedPanel extends StatelessWidget {
  const new({required this.message, required this.onStartAgain});

  final String message;
  final VoidCallback onStartAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(title: l10n.codeTitle),
        const SizedBox(height: AppSpacing.lg),
        InlineMessage.error(message),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const Key('login.startAgain'),
          autofocus: true,
          onPressed: onStartAgain,
          child: Text(l10n.startAgain),
        ),
      ],
    );
  }
}
