import 'dart:async';

import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/cubit/login_cubit.dart';
import 'package:bravynix_school_erp/features/auth/presentation/login/view/login_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmailForm extends StatefulWidget {
  const new({super.key});

  /// Good enough to catch typos; the server is the judge (API design 10.1).
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: context.read<LoginCubit>().state.email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      unawaited(context.read<LoginCubit>().submitEmail(_email.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = context.watch<LoginCubit>().state;
    final fieldError = state.failure?.fieldError('email')?.message;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loginTitle, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(l10n.loginSubtitle, style: textTheme.bodyMedium?.copyWith(color: textTheme.bodySmall?.color)),
          const SizedBox(height: 24),
          if (state.failure != null && fieldError == null) ...[
            InlineMessage.error(loginErrorText(l10n, state.failure!)),
            const SizedBox(height: 16),
          ],
          TextFormField(
            key: const Key('login.email'),
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 254,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(labelText: l10n.emailLabel, errorText: fieldError),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return l10n.emailRequired;
              if (!EmailForm._emailPattern.hasMatch(email)) return l10n.emailInvalid;
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login.sendCode'),
            onPressed: state.isSubmitting ? null : _submit,
            child: state.isSubmitting ? const _ButtonSpinner() : Text(l10n.sendCode),
          ),
        ],
      ),
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) =>
      const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2));
}
