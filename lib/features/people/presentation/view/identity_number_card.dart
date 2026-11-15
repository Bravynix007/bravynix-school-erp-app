import 'dart:async';

import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/model/aadhaar.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/identity_number_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The words for a refusal of one of the calls.
typedef FailureText = String Function(AppLocalizations l10n, ApiFailure failure);

/// The words of a card for one kind of number.
class IdentityNumberCopy {
  const new({
    required this.label,
    required this.notSet,
    required this.set,
    required this.change,
    required this.clear,
    required this.clearTitle,
    required this.clearMessage,
    required this.saved,
    required this.cleared,
    required this.invalid,
    this.savedElsewhere,
    this.helper,
  });

  final String label;
  final String notSet;

  /// The buttons that set a first number, change the one held, and clear it.
  final String set;
  final String change;
  final String clear;

  /// The question before a clear, which names whose number it is, and what it says.
  final String clearTitle;
  final String clearMessage;
  final String saved;

  /// What a save says when another Institution of the Society holds the number too; [saved] when null.
  final String? savedElsewhere;
  final String cleared;

  /// What the field says when what was typed is not a number.
  final String invalid;

  /// A line under the field.
  final String? helper;
}

/// What a number looks like when it is typed.
class IdentityNumberRule {
  const new({required this.normalise, this.formatters = const [], this.keyboardType, this.prefill = false});

  /// The number to send for what was typed; null when it is not one.
  final String? Function(String typed) normalise;
  final List<TextInputFormatter> formatters;
  final TextInputType? keyboardType;

  /// Whether the field starts with the number held, as one that is shown whole can; a masked one cannot.
  final bool prefill;
}

/// A card for one identity number of a profile (staff STF-11 and STF-12, student STU-10 and STU-11): the number as the
/// bloc holds it, with a way to set it and clear it, and, when [protection] is given, to show the whole number for a
/// reason. It reads the [IdentityNumberBloc] above it, which then has a reveal.
class IdentityNumberCard extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.copy,
    required this.rule,
    required this.errorText,
    this.protection,
    this.changeable = true,
    super.key,
  });

  /// The start of the keys of the card's parts, for tests and the screen that reads them.
  final String keyPrefix;
  final IdentityNumberCopy copy;
  final IdentityNumberRule rule;

  /// What a refusal of one of the calls says; the codes are the profile's own.
  final FailureText errorText;

  /// Keeps the screen out of screenshots while the whole number is shown; null for a number that has no reveal.
  final ScreenProtection? protection;

  /// False for a record that is deactivated: the number can still be shown, but no longer set or cleared.
  final bool changeable;

  Future<void> _clear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<IdentityNumberBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: copy.clearTitle,
      message: copy.clearMessage,
      confirmLabel: copy.clear,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(const IdentityNumberCleared());
  }

  /// A sheet over the profile with the bloc of the card, which closes it by sending [IdentityNumberHidden].
  Future<void> _open(BuildContext context, {required String title, required WidgetBuilder builder}) {
    final bloc = context.read<IdentityNumberBloc>();
    return showAppBottomSheet<void>(
      context: context,
      title: title,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: Builder(builder: builder),
      ),
    ).whenComplete(() => bloc.add(const IdentityNumberHidden()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final protection = this.protection;
    return BlocConsumer<IdentityNumberBloc, IdentityNumberState>(
      // A save or a clear that went through; a reveal ends in the sheet that shows it, or in nothing when it was
      // closed.
      listenWhen: (previous, current) =>
          previous is IdentityNumberWorking &&
          previous.action != IdentityNumberAction.reveal &&
          current is IdentityNumberIdle,
      listener: (context, state) => AppSnackbar.show(
        context,
        message: switch (state) {
          IdentityNumberIdle(elsewhere: true) => copy.savedElsewhere ?? copy.saved,
          IdentityNumberState(number: null) => copy.cleared,
          _ => copy.saved,
        },
        kind: AppSnackbarKind.success,
      ),
      builder: (context, state) {
        final working = state is IdentityNumberWorking;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: copy.label, value: state.number ?? copy.notSet, mono: true),
              // A refusal to clear is shown here, and so is one whose sheet was closed; the sheets that are open say
              // theirs themselves.
              if (state case IdentityNumberRefused(:final failure, inSheet: false)) ...[
                const SizedBox(height: AppSpacing.xs),
                InlineMessage.error(errorText(l10n, failure), key: Key('$keyPrefix.error')),
              ],
              if (protection != null && state.number != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  key: Key('$keyPrefix.reveal'),
                  label: l10n.aadhaarShow,
                  variant: AppButtonVariant.secondary,
                  onPressed: working
                      ? null
                      : () => _open(
                          context,
                          title: l10n.aadhaarRevealTitle,
                          builder: (_) => _RevealSheet(
                            keyPrefix: keyPrefix,
                            label: copy.label,
                            protection: protection,
                            errorText: errorText,
                          ),
                        ),
                ),
              ],
              if (changeable) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  key: Key('$keyPrefix.set'),
                  label: state.number == null ? copy.set : copy.change,
                  variant: AppButtonVariant.secondary,
                  onPressed: working
                      ? null
                      : () => _open(
                          context,
                          title: copy.label,
                          builder: (_) => _SetSheet(
                            keyPrefix: keyPrefix,
                            copy: copy,
                            rule: rule,
                            errorText: errorText,
                          ),
                        ),
                ),
              ],
              if (changeable && state.number != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  key: Key('$keyPrefix.clear'),
                  label: copy.clear,
                  variant: AppButtonVariant.text,
                  loading: state is IdentityNumberWorking && state.action == IdentityNumberAction.clear,
                  onPressed: working ? null : () => _clear(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The field for a new number. It is checked here by the [IdentityNumberRule], and the server checks the rest.
class _SetSheet extends StatefulWidget {
  const new({required this.keyPrefix, required this.copy, required this.rule, required this.errorText});

  final String keyPrefix;
  final IdentityNumberCopy copy;
  final IdentityNumberRule rule;
  final FailureText errorText;

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  late final _controller = TextEditingController(
    text: widget.rule.prefill ? context.read<IdentityNumberBloc>().state.number : null,
  );
  bool _tried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final number = widget.rule.normalise(_controller.text);
    setState(() => _tried = true);
    if (number != null) context.read<IdentityNumberBloc>().add(IdentityNumberSaved(number));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final helper = widget.copy.helper;
    return BlocConsumer<IdentityNumberBloc, IdentityNumberState>(
      // It is saved: the sheet is done.
      listenWhen: (previous, current) => previous is IdentityNumberWorking && current is IdentityNumberIdle,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final working = state is IdentityNumberWorking && state.action == IdentityNumberAction.save;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: Key('${widget.keyPrefix}.field'),
              label: widget.copy.label,
              controller: _controller,
              mono: true,
              error: _tried && widget.rule.normalise(_controller.text) == null ? widget.copy.invalid : null,
              keyboardType: widget.rule.keyboardType,
              inputFormatters: widget.rule.formatters,
              enabled: !working,
              onChanged: (_) {
                if (_tried) setState(() => _tried = false);
              },
            ),
            if (helper != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(helper, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (state case IdentityNumberRefused(
              :final failure,
              action: IdentityNumberAction.save,
              inSheet: true,
            )) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(widget.errorText(l10n, failure), key: Key('${widget.keyPrefix}.saveError')),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: Key('${widget.keyPrefix}.save'),
              label: l10n.aadhaarSave,
              loading: working,
              onPressed: working ? null : () => _save(context),
            ),
          ],
        );
      },
    );
  }
}

/// The reason for seeing the Aadhaar number, and then the number for as long as the sheet is open.
class _RevealSheet extends StatefulWidget {
  const new({required this.keyPrefix, required this.label, required this.protection, required this.errorText});

  final String keyPrefix;
  final String label;
  final ScreenProtection protection;
  final FailureText errorText;

  @override
  State<_RevealSheet> createState() => _RevealSheetState();
}

class _RevealSheetState extends State<_RevealSheet> {
  static const _minReason = 10;

  final _controller = TextEditingController();
  bool _tried = false;
  bool _protected = false;

  @override
  void dispose() {
    _controller.dispose();
    _protect(on: false);
    super.dispose();
  }

  /// The screen is kept out of screenshots from the moment the number is asked for, so that it is already so when it
  /// arrives, until the sheet lets go of it: Done, a swipe, or the profile closing over it.
  void _protect({required bool on}) {
    if (on == _protected) return;
    _protected = on;
    unawaited(on ? widget.protection.protect() : widget.protection.release());
  }

  void _reveal(BuildContext context) {
    final reason = _controller.text.trim();
    setState(() => _tried = true);
    if (reason.length >= _minReason) context.read<IdentityNumberBloc>().add(IdentityNumberRevealed(reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return BlocConsumer<IdentityNumberBloc, IdentityNumberState>(
      // Only a reveal is on its way while this sheet is open.
      listener: (context, state) => _protect(on: state is IdentityNumberShown || state is IdentityNumberWorking),
      builder: (context, state) {
        if (state case IdentityNumberShown(:final whole)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: widget.label, value: Aadhaar.grouped(whole), mono: true),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.aadhaarRevealed, style: text.bodySmall),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: Key('${widget.keyPrefix}.done'),
                label: l10n.aadhaarDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }
        final working = state is IdentityNumberWorking;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: Key('${widget.keyPrefix}.reason'),
              label: l10n.aadhaarReason,
              controller: _controller,
              error: _tried && _controller.text.trim().length < _minReason ? l10n.aadhaarReasonShort : null,
              maxLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              enabled: !working,
              onChanged: (_) {
                if (_tried) setState(() => _tried = false);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.aadhaarReasonHelper, style: text.bodySmall),
            if (state case IdentityNumberRefused(
              :final failure,
              action: IdentityNumberAction.reveal,
              inSheet: true,
            )) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(widget.errorText(l10n, failure), key: Key('${widget.keyPrefix}.revealError')),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: Key('${widget.keyPrefix}.show'),
              label: l10n.aadhaarRevealAction,
              loading: working,
              onPressed: working ? null : () => _reveal(context),
            ),
          ],
        );
      },
    );
  }
}
