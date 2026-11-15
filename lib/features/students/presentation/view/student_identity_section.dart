import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/model/typed_text.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/identity_number_bloc.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/aadhaar_card.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/identity_number_card.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The identity part of the student profile (STU-10, STU-11): the Aadhaar number masked, as for staff, and the birth
/// certificate number whole, each with a way to set it and clear it.
class StudentIdentitySection extends StatelessWidget {
  const new({required this.record, super.key});

  /// The longest a birth certificate number can be (STU-10).
  static const _longestCertificate = 50;

  final StudentRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final students = getIt<StudentsRepository>();
    // A deactivated student's numbers can still be shown (STU-11) but not changed (STU-10 is 404).
    final changeable = record.isActive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.identityTitle),
        const SizedBox(height: AppSpacing.xs),
        // Each number has its own bloc, so each card is given its own.
        BlocProvider(
          create: (_) => IdentityNumberBloc(
            save: (aadhaar) async {
              final saved = await students.setAadhaar(record.id, aadhaar);
              return (number: saved.identity.aadhaarMasked, elsewhere: saved.aadhaarElsewhere);
            },
            reveal: (reason) => students.revealAadhaar(record.id, reason: reason),
            number: record.identity.aadhaarMasked,
          ),
          child: AadhaarCard(
            personName: record.fullName,
            protection: getIt<ScreenProtection>(),
            errorText: studentIdentityErrorText,
            changeable: changeable,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        BlocProvider(
          create: (_) => IdentityNumberBloc(
            save: (number) async {
              final saved = await students.setBirthCertificate(record.id, number);
              return (number: saved.identity.birthCertificateNumber, elsewhere: false);
            },
            number: record.identity.birthCertificateNumber,
          ),
          child: IdentityNumberCard(
            keyPrefix: 'studentCertificate',
            copy: IdentityNumberCopy(
              label: l10n.studentBirthCertificate,
              notSet: l10n.studentProfileNotSet,
              set: l10n.studentCertificateSet,
              change: l10n.studentCertificateChange,
              clear: l10n.studentCertificateClear,
              clearTitle: l10n.studentCertificateClearTitle(record.fullName),
              clearMessage: l10n.studentCertificateClearMessage,
              saved: l10n.studentCertificateSaved,
              cleared: l10n.studentCertificateCleared,
              invalid: l10n.studentCertificateRequired,
            ),
            // It is checked to be there, and the server checks the rest.
            rule: IdentityNumberRule(
              normalise: TypedText.text,
              formatters: [LengthLimitingTextInputFormatter(_longestCertificate)],
              prefill: true,
            ),
            errorText: studentIdentityErrorText,
            changeable: changeable,
          ),
        ),
      ],
    );
  }
}
