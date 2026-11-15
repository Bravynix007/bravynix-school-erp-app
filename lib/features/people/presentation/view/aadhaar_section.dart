import 'dart:async';

import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/model/aadhaar.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/aadhaar_input.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/aadhaar_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The words for a refusal of one of the calls.
typedef FailureText = String Function(AppLocalizations l10n, ApiFailure failure);

/// The identity part of a profile (staff STF-11 and STF-12, student STU-10 and STU-11): the Aadhaar number masked, with
/// a way to set it, clear it, and show the whole number for a reason.
class AadhaarSection extends StatelessWidget {
  const new({
    required this.personName,
    required this.protection,
    required this.errorText,
    this.changeable = true,
    super.key,
  });

  /// False for a record that is deactivated: the number can still be shown, but no longer set or cleared.
  final bool changeable;

  /// Whose number it is, as the question to clear it names them.
  final String personName;

  /// What a refusal of one of the calls says; the codes are the profile's own.
  final FailureText errorText;

  /// Keeps the screen out of screenshots while the whole number is shown.
  final ScreenProtection protection;

  Future<void> _clear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AadhaarBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.aadhaarClearTitle(personName),
      message: l10n.aadhaarClearMessage,
      confirmLabel: l10n.aadhaarClear,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(const AadhaarCleared());
  }

  /// A sheet over the profile with the bloc of the section, which closes it by sending [AadhaarHidden].
  Future<void> _open(BuildContext context, {required String title, required WidgetBuilder builder}) {
    final bloc = context.read<AadhaarBloc>();
    return showAppBottomSheet<void>(
      context: context,
      title: title,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: Builder(builder: builder),
      ),
    ).whenComplete(() => bloc.add(const AadhaarHidden()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.identityTitle),
        const SizedBox(height: AppSpacing.xs),
        BlocConsumer<AadhaarBloc, AadhaarState>(
          // A save or a clear that went through; a reveal ends in the sheet that shows it, or in nothing when it was
          // closed.
          listenWhen: (previous, current) =>
              previous is AadhaarWorking && previous.action != AadhaarAction.reveal && current is AadhaarIdle,
          listener: (context, state) => AppSnackbar.show(
            context,
            message: switch (state) {
              AadhaarIdle(elsewhere: true) => l10n.aadhaarSavedElsewhere,
              AadhaarState(masked: null) => l10n.aadhaarCleared,
              _ => l10n.aadhaarSaved,
            },
            kind: AppSnackbarKind.success,
          ),
          builder: (context, state) {
            final working = state is AadhaarWorking;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyValueRow(label: l10n.aadhaar, value: state.masked ?? l10n.aadhaarNotSet, mono: true),
                  // A refusal to clear is shown here, and so is one whose sheet was closed; the sheets that are open
                  // say theirs themselves.
                  if (state case AadhaarRefused(:final failure, inSheet: false)) ...[
                    const SizedBox(height: AppSpacing.xs),
                    InlineMessage.error(errorText(l10n, failure), key: const Key('aadhaar.error')),
                  ],
                  if (state.masked != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const Key('aadhaar.reveal'),
                      label: l10n.aadhaarShow,
                      variant: AppButtonVariant.secondary,
                      onPressed: working
                          ? null
                          : () => _open(
                              context,
                              title: l10n.aadhaarRevealTitle,
                              builder: (_) => _RevealSheet(protection: protection, errorText: errorText),
                            ),
                    ),
                  ],
                  if (changeable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const Key('aadhaar.set'),
                      label: state.masked == null ? l10n.aadhaarSet : l10n.aadhaarChange,
                      variant: AppButtonVariant.secondary,
                      onPressed: working
                          ? null
                          : () => _open(
                              context,
                              title: l10n.aadhaar,
                              builder: (_) => _SetSheet(errorText: errorText),
                            ),
                    ),
                  ],
                  if (changeable && state.masked != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const Key('aadhaar.clear'),
                      label: l10n.aadhaarClear,
                      variant: AppButtonVariant.text,
                      loading: state is AadhaarWorking && state.action == AadhaarAction.clear,
                      onPressed: working ? null : () => _clear(context),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The field for a new number. It is checked for twelve digits here, and the server checks the rest.
class _SetSheet extends StatefulWidget {
  const new({required this.errorText});

  final FailureText errorText;

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  final _controller = TextEditingController();
  String? _digits;
  bool _tried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final digits = Aadhaar.typed(_controller.text);
    setState(() {
      _digits = digits;
      _tried = true;
    });
    if (digits != null) context.read<AadhaarBloc>().add(AadhaarSaved(digits));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AadhaarBloc, AadhaarState>(
      // It is saved: the sheet is done.
      listenWhen: (previous, current) => previous is AadhaarWorking && current is AadhaarIdle,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final working = state is AadhaarWorking && state.action == AadhaarAction.save;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: const Key('aadhaar.aadhaar'),
              label: l10n.aadhaar,
              controller: _controller,
              mono: true,
              error: _tried && _digits == null ? l10n.aadhaarInvalid : null,
              keyboardType: TextInputType.number,
              inputFormatters: aadhaarInputFormatters(),
              enabled: !working,
              onChanged: (_) {
                if (_tried) setState(() => _tried = false);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.aadhaarSetHelper, style: Theme.of(context).textTheme.bodySmall),
            if (state case AadhaarRefused(:final failure, action: AadhaarAction.save, inSheet: true)) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(widget.errorText(l10n, failure), key: const Key('aadhaar.saveError')),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('aadhaar.save'),
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

/// The reason for seeing the number, and then the number for as long as the sheet is open.
class _RevealSheet extends StatefulWidget {
  const new({required this.protection, required this.errorText});

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
    if (reason.length >= _minReason) context.read<AadhaarBloc>().add(AadhaarRevealed(reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return BlocConsumer<AadhaarBloc, AadhaarState>(
      // Only a reveal is on its way while this sheet is open.
      listener: (context, state) => _protect(on: state is AadhaarShown || state is AadhaarWorking),
      builder: (context, state) {
        if (state case AadhaarShown(:final value)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: l10n.aadhaar, value: Aadhaar.grouped(value), mono: true),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.aadhaarRevealed, style: text.bodySmall),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const Key('aadhaar.done'),
                label: l10n.aadhaarDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }
        final working = state is AadhaarWorking;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: const Key('aadhaar.reason'),
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
            if (state case AadhaarRefused(:final failure, action: AadhaarAction.reveal, inSheet: true)) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(widget.errorText(l10n, failure), key: const Key('aadhaar.revealError')),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('aadhaar.show'),
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
