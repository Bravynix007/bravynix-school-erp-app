import 'package:bravynix_school_erp/core/model/aadhaar.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_identity_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The identity part of the personal tab (STF-11, STF-12): the Aadhaar number masked, with a way to set it, clear it,
/// and show the whole number for a reason.
class StaffIdentitySection extends StatelessWidget {
  const new({required this.memberName, super.key});

  final String memberName;

  Future<void> _clear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffIdentityBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.staffAadhaarClearTitle(memberName),
      message: l10n.staffAadhaarClearMessage,
      confirmLabel: l10n.staffAadhaarClear,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(const StaffAadhaarCleared());
  }

  /// A sheet over the profile with the bloc of the section, which closes it by sending [StaffIdentityHidden].
  Future<void> _open(BuildContext context, {required String title, required WidgetBuilder builder}) {
    final bloc = context.read<StaffIdentityBloc>();
    return showAppBottomSheet<void>(
      context: context,
      title: title,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: Builder(builder: builder),
      ),
    ).whenComplete(() => bloc.add(const StaffIdentityHidden()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.staffIdentityTitle),
        const SizedBox(height: AppSpacing.xs),
        BlocConsumer<StaffIdentityBloc, StaffIdentityState>(
          // A save or a clear that went through; a reveal ends in the sheet that shows it, or in nothing when it was closed.
          listenWhen: (previous, current) =>
              previous is StaffIdentityWorking &&
              previous.action != StaffIdentityAction.reveal &&
              current is StaffIdentityIdle,
          listener: (context, state) => AppSnackbar.show(
            context,
            message: (state.masked == null) ? l10n.staffAadhaarCleared : l10n.staffAadhaarSaved,
            kind: AppSnackbarKind.success,
          ),
          builder: (context, state) {
            final working = state is StaffIdentityWorking;
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyValueRow(label: l10n.staffAadhaar, value: state.masked ?? l10n.staffAadhaarNotSet, mono: true),
                  // A refusal to clear is shown here, and so is one whose sheet was closed; the sheets that are open say
                  // theirs themselves.
                  if (state case StaffIdentityRefused(:final failure, inSheet: false)) ...[
                    const SizedBox(height: AppSpacing.xs),
                    InlineMessage.error(staffIdentityErrorText(l10n, failure), key: const Key('staffIdentity.error')),
                  ],
                  if (state.masked != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const Key('staffIdentity.reveal'),
                      label: l10n.staffAadhaarShow,
                      variant: AppButtonVariant.secondary,
                      onPressed: working
                          ? null
                          : () => _open(
                              context,
                              title: l10n.staffAadhaarRevealTitle,
                              builder: (_) => const _RevealSheet(),
                            ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: const Key('staffIdentity.set'),
                    label: state.masked == null ? l10n.staffAadhaarSet : l10n.staffAadhaarChange,
                    variant: AppButtonVariant.secondary,
                    onPressed: working
                        ? null
                        : () => _open(context, title: l10n.staffAadhaar, builder: (_) => const _SetSheet()),
                  ),
                  if (state.masked != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const Key('staffIdentity.clear'),
                      label: l10n.staffAadhaarClear,
                      variant: AppButtonVariant.text,
                      loading: state is StaffIdentityWorking && state.action == StaffIdentityAction.clear,
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
  const new();

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
    if (digits != null) context.read<StaffIdentityBloc>().add(StaffAadhaarSaved(digits));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<StaffIdentityBloc, StaffIdentityState>(
      // It is saved: the sheet is done.
      listenWhen: (previous, current) => previous is StaffIdentityWorking && current is StaffIdentityIdle,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final working = state is StaffIdentityWorking && state.action == StaffIdentityAction.save;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: const Key('staffIdentity.aadhaar'),
              label: l10n.staffAadhaar,
              controller: _controller,
              mono: true,
              error: _tried && _digits == null ? l10n.staffAadhaarInvalid : null,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9 -]')),
                LengthLimitingTextInputFormatter(14),
              ],
              enabled: !working,
              onChanged: (_) {
                if (_tried) setState(() => _tried = false);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.staffAadhaarSetHelper, style: Theme.of(context).textTheme.bodySmall),
            if (state case StaffIdentityRefused(:final failure, action: StaffIdentityAction.save, inSheet: true)) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(staffIdentityErrorText(l10n, failure), key: const Key('staffIdentity.saveError')),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('staffIdentity.save'),
              label: l10n.staffAadhaarSave,
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
  const new();

  @override
  State<_RevealSheet> createState() => _RevealSheetState();
}

class _RevealSheetState extends State<_RevealSheet> {
  static const _minReason = 10;

  final _controller = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reveal(BuildContext context) {
    final reason = _controller.text.trim();
    setState(() => _tried = true);
    if (reason.length >= _minReason) context.read<StaffIdentityBloc>().add(StaffAadhaarRevealed(reason));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return BlocBuilder<StaffIdentityBloc, StaffIdentityState>(
      builder: (context, state) {
        if (state case StaffIdentityRevealed(:final value)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: l10n.staffAadhaar, value: Aadhaar.grouped(value), mono: true),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.staffAadhaarRevealed, style: text.bodySmall),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const Key('staffIdentity.done'),
                label: l10n.staffAadhaarDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }
        final working = state is StaffIdentityWorking;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: const Key('staffIdentity.reason'),
              label: l10n.staffAadhaarReason,
              controller: _controller,
              error: _tried && _controller.text.trim().length < _minReason ? l10n.staffAadhaarReasonShort : null,
              maxLines: 3,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              enabled: !working,
              onChanged: (_) {
                if (_tried) setState(() => _tried = false);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.staffAadhaarReasonHelper, style: text.bodySmall),
            if (state case StaffIdentityRefused(:final failure, action: StaffIdentityAction.reveal, inSheet: true)) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(staffIdentityErrorText(l10n, failure), key: const Key('staffIdentity.revealError')),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('staffIdentity.show'),
              label: l10n.staffAadhaarRevealAction,
              loading: working,
              onPressed: working ? null : () => _reveal(context),
            ),
          ],
        );
      },
    );
  }
}
