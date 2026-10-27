import 'dart:async';

import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/cubit/login_cubit.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _submit() => context.read<LoginCubit>().submitCode(_code.text);

  static String _mmss(Duration value) => '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<LoginCubit>();

    return BlocConsumer<LoginCubit, LoginState>(
      listenWhen: (previous, current) => current.failure != null && previous.failure != current.failure,
      listener: (context, state) => _code.clear(),
      builder: (context, state) {
        final left = state.resendAvailableAt?.difference(widget.clock());
        final waiting = left != null && left > Duration.zero;
        final codeError = state.failure?.code == 'OTP_INVALID' ? loginErrorText(l10n, state.failure!) : null;

        // Locked out: no code field and no Resend, only a way back to the start.
        if (state.failure case final locked? when locked.isLockedOut) {
          return _LockedPanel(message: loginErrorText(l10n, locked), onStartAgain: cubit.changeEmail);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.codeTitle, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(l10n.codeSubtitle(state.email), style: textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (state.failure != null && codeError == null) ...[
              InlineMessage.error(loginErrorText(l10n, state.failure!)),
              const SizedBox(height: 16),
            ],
            TextField(
              key: const Key('login.code'),
              controller: _code,
              autofocus: true,
              enabled: !state.isSubmitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge?.copyWith(
                letterSpacing: 12, // token-ok: spreads the six OTP digits
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(labelText: l10n.codeLabel, errorText: codeError),
              onChanged: (value) {
                if (value.length == 6) _submit();
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login.verify'),
              onPressed: state.isSubmitting || cubit.isCodeDead() ? null : _submit,
              child: Text(l10n.verify),
            ),
            const SizedBox(height: 8),
            // Wraps rather than overflows: labels grow up to 40% in other languages.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (waiting)
                  // Not a live region: a ticking timer is noise for screen readers.
                  ExcludeSemantics(
                    child: Text(l10n.resendIn(_mmss(left)), style: textTheme.bodySmall),
                  )
                else
                  TextButton(
                    key: const Key('login.resend'),
                    onPressed: state.isSubmitting ? null : cubit.resend,
                    child: Text(l10n.resendCode),
                  ),
                TextButton(
                  key: const Key('login.changeEmail'),
                  onPressed: state.isSubmitting ? null : cubit.changeEmail,
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
        Text(l10n.codeTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        InlineMessage.error(message),
        const SizedBox(height: 24),
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
