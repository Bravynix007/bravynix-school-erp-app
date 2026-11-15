import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/model/typed_text.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/aadhaar_bloc.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/aadhaar_section.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/birth_certificate_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The identity part of the student profile (STU-10, STU-11): the Aadhaar number masked, as for staff, and the birth
/// certificate number whole, each with a way to set it and clear it.
class StudentIdentitySection extends StatelessWidget {
  const new({required this.record, super.key});

  final StudentRecord record;

  @override
  Widget build(BuildContext context) {
    final students = getIt<StudentsRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AadhaarBloc(
            save: (aadhaar) async {
              final saved = await students.setAadhaar(record.id, aadhaar);
              return (masked: saved.identity.aadhaarMasked, elsewhere: saved.aadhaarElsewhere);
            },
            reveal: (reason) => students.revealAadhaar(record.id, reason: reason),
            masked: record.identity.aadhaarMasked,
          ),
        ),
        BlocProvider(
          create: (_) => BirthCertificateBloc(
            students,
            studentId: record.id,
            number: record.identity.birthCertificateNumber,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AadhaarSection(
            personName: record.fullName,
            protection: getIt<ScreenProtection>(),
            errorText: studentIdentityErrorText,
            // A deactivated student's number can still be shown (STU-11) but not changed (STU-10 is 404).
            changeable: record.isActive,
          ),
          const SizedBox(height: AppSpacing.xs),
          _BirthCertificateCard(personName: record.fullName, changeable: record.isActive),
        ],
      ),
    );
  }
}

class _BirthCertificateCard extends StatelessWidget {
  const new({required this.personName, required this.changeable});

  final String personName;
  final bool changeable;

  Future<void> _clear(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<BirthCertificateBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.studentCertificateClearTitle(personName),
      message: l10n.studentCertificateClearMessage,
      confirmLabel: l10n.studentCertificateClear,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(const BirthCertificateCleared());
  }

  /// A sheet over the profile with the bloc of the card, which closes it by sending [BirthCertificateHidden].
  Future<void> _open(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<BirthCertificateBloc>();
    return showAppBottomSheet<void>(
      context: context,
      title: l10n.studentBirthCertificate,
      builder: (_) => BlocProvider.value(value: bloc, child: const _SetSheet()),
    ).whenComplete(() => bloc.add(const BirthCertificateHidden()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<BirthCertificateBloc, BirthCertificateState>(
      // A save or a clear that went through.
      listenWhen: (previous, current) => previous is BirthCertificateWorking && current is BirthCertificateIdle,
      listener: (context, state) => AppSnackbar.show(
        context,
        message: state.number == null ? l10n.studentCertificateCleared : l10n.studentCertificateSaved,
        kind: AppSnackbarKind.success,
      ),
      builder: (context, state) {
        final working = state is BirthCertificateWorking;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: l10n.studentBirthCertificate, value: state.number ?? l10n.studentProfileNotSet),
              // A refusal to clear is shown here, and so is one whose sheet was closed; the sheet that is open says its
              // own.
              if (state case BirthCertificateRefused(:final failure, inSheet: false)) ...[
                const SizedBox(height: AppSpacing.xs),
                InlineMessage.error(
                  studentIdentityErrorText(l10n, failure),
                  key: const Key('studentCertificate.error'),
                ),
              ],
              if (changeable) ...[
                const SizedBox(height: AppSpacing.xs),
                AppButton(
                  key: const Key('studentCertificate.set'),
                  label: state.number == null ? l10n.studentCertificateSet : l10n.studentCertificateChange,
                  variant: AppButtonVariant.secondary,
                  onPressed: working ? null : () => _open(context),
                ),
                if (state.number != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: const Key('studentCertificate.clear'),
                    label: l10n.studentCertificateClear,
                    variant: AppButtonVariant.text,
                    loading: state is BirthCertificateWorking && state.action == BirthCertificateAction.clear,
                    onPressed: working ? null : () => _clear(context),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The field for the number. It is checked to be there, and the server checks the rest.
class _SetSheet extends StatefulWidget {
  const new();

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  static const _longest = 50;

  late final _controller = TextEditingController(text: context.read<BirthCertificateBloc>().state.number);
  bool _tried = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final number = TypedText.text(_controller.text);
    setState(() => _tried = true);
    if (number != null) context.read<BirthCertificateBloc>().add(BirthCertificateSaved(number));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<BirthCertificateBloc, BirthCertificateState>(
      // It is saved: the sheet is done.
      listenWhen: (previous, current) => previous is BirthCertificateWorking && current is BirthCertificateIdle,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final working = state is BirthCertificateWorking && state.action == BirthCertificateAction.save;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              key: const Key('studentCertificate.number'),
              label: l10n.studentBirthCertificate,
              controller: _controller,
              mono: true,
              error: _tried && TypedText.text(_controller.text) == null ? l10n.studentCertificateRequired : null,
              inputFormatters: [LengthLimitingTextInputFormatter(_longest)],
              enabled: !working,
              onChanged: (_) {
                if (_tried) setState(() => _tried = false);
              },
            ),
            if (state case BirthCertificateRefused(:final failure, inSheet: true)) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(
                studentIdentityErrorText(l10n, failure),
                key: const Key('studentCertificate.saveError'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('studentCertificate.save'),
              label: l10n.studentCertificateSave,
              loading: working,
              onPressed: working ? null : () => _save(context),
            ),
          ],
        );
      },
    );
  }
}
