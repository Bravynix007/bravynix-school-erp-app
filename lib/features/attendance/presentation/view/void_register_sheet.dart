import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The shortest and longest reason ATT-06 takes.
const minVoidReason = 5;
const maxVoidReason = 500;

/// Asks why a register is voided (ATT-06) and answers the reason, or null when the sheet is closed without confirming.
Future<String?> showVoidRegisterSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<String>(
    context: context,
    title: l10n.attendanceVoidTitle,
    builder: (_) => const _VoidReason(),
  );
}

class _VoidReason extends StatefulWidget {
  const new();

  @override
  State<_VoidReason> createState() => _VoidReasonState();
}

class _VoidReasonState extends State<_VoidReason> {
  final _controller = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _controller.text.trim();
    if (reason.length < minVoidReason) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.attendanceVoidMessage, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          key: const Key('attendanceVoid.reason'),
          label: l10n.attendanceVoidReason,
          controller: _controller,
          error: _tried && _controller.text.trim().length < minVoidReason ? l10n.attendanceVoidReasonShort : null,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(maxVoidReason)],
          onChanged: (_) {
            if (_tried) setState(() => _tried = false);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const Key('attendanceVoid.confirm'),
          label: l10n.attendanceVoidConfirm,
          variant: AppButtonVariant.danger,
          onPressed: _confirm,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: const Key('attendanceVoid.cancel'),
          label: l10n.cancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
