import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_tag.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/person_names.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_profile_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_frame.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_names.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// School setup → Students → one student (STU-03): who they are, where they sit, their guardians and the identity
/// numbers, the Aadhaar masked.
class StudentProfilePage extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StudentProfileBloc(
      getIt<StudentsRepository>(),
      getIt<MastersRepository>(),
      getIt<ClassesRepository>(),
      getIt<SectionsRepository>(),
      id,
    )..add(const StudentProfileRequested()),
    child: const StudentProfileView(),
  );
}

class StudentProfileView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<StudentProfileBloc, StudentProfileState>(
      builder: (context, state) => StudentFrame(
        title: l10n.studentProfileTitle,
        child: switch (state) {
          StudentProfileLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 112]),
          StudentProfileFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
            key: const Key('studentProfile.forbidden'),
            title: studentErrorText(l10n, failure),
          ),
          StudentProfileFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
            key: const Key('studentProfile.notFound'),
            title: studentErrorText(l10n, failure),
          ),
          StudentProfileFailed(:final failure) => StatePanel.error(
            key: const Key('studentProfile.failed'),
            title: studentErrorText(l10n, failure),
            actionLabel: l10n.retry,
            onAction: () => context.read<StudentProfileBloc>().add(const StudentProfileRequested()),
          ),
          StudentProfileLoaded(:final profile) => _Details(profile: profile),
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final record = profile.record;
    final address = record.address;
    final addressText = [
      ?address.line1,
      ?address.line2,
      [?profile.cityName, ?profile.stateName, ?profile.countryName].join(', '),
      ?address.pincode,
    ].where((line) => line.isNotEmpty).join('\n');
    final where = [
      ?profile.placeName,
      if (record.placement case final placement?) l10n.studentsRoll(placement.rollNumber),
    ].join(' · ');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(record.fullName, style: text.headlineSmall),
              ),
              if (!record.isActive || record.isBlocked) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    if (!record.isActive) StatusChip(label: l10n.studentProfileDeactivated),
                    if (record.isBlocked) StatusChip(label: l10n.studentsBlocked, tone: StatusTone.error),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              if (record.admissionNo case final id?) KeyValueRow(label: l10n.studentAdmissionNo, value: id, mono: true),
              if (record.admissionDate case final day?)
                KeyValueRow(label: l10n.studentAdmissionDate, value: Formatters.schoolDate(day)),
              if (where.isNotEmpty) KeyValueRow(label: l10n.studentFormPlacement, value: where),
              if (record.gender case final gender?)
                KeyValueRow(label: l10n.personGender, value: genderName(l10n, gender)),
              if (record.dateOfBirth case final day?)
                KeyValueRow(label: l10n.personDateOfBirth, value: Formatters.schoolDate(day)),
              if (record.bloodGroup case final group?) KeyValueRow(label: l10n.personBloodGroup, value: group),
              if (record.nationality case final nationality?)
                KeyValueRow(label: l10n.personNationality, value: nationality),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.personFormContact),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (record.contactEmail case final email?) KeyValueRow(label: l10n.studentContactEmail, value: email),
              if (record.mobile case final mobile?) KeyValueRow(label: l10n.personMobile, value: mobile.display),
              if (record.alternateNumber case final number?)
                KeyValueRow(label: l10n.personAlternateNumber, value: number),
              if (addressText.isNotEmpty) KeyValueRow(label: l10n.personFormAddress, value: addressText),
              if (record.contactEmail == null &&
                  record.mobile == null &&
                  record.alternateNumber == null &&
                  addressText.isEmpty)
                Text(l10n.studentProfileNoContact, style: text.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.studentFormGuardians),
        const SizedBox(height: AppSpacing.xs),
        for (final guardian in record.guardians) ...[
          _GuardianCard(guardian: guardian),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SizedBox(height: AppSpacing.xs),
        SectionHeader(title: l10n.studentFormIdentity),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(
                label: l10n.studentAadhaar,
                value: record.identity.aadhaarMasked ?? l10n.studentProfileNotSet,
                mono: record.identity.aadhaarMasked != null,
              ),
              KeyValueRow(
                label: l10n.studentBirthCertificate,
                value: record.identity.birthCertificateNumber ?? l10n.studentProfileNotSet,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const new({required this.guardian});

  final Guardian guardian;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final relation = guardian.relation;
    return AppCard(
      key: ValueKey('studentProfile.guardian.${guardian.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(guardian.fullName, style: text.titleMedium),
          if (relation != null) Text(relationName(l10n, relation), style: text.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          KeyValueRow(label: l10n.personMobile, value: guardian.phone.display),
          if (guardian.alternatePhone case final number?) KeyValueRow(label: l10n.personAlternateNumber, value: number),
          if (guardian.email case final email?) KeyValueRow(label: l10n.studentGuardianEmail, value: email),
          if (guardian.occupation case final occupation?)
            KeyValueRow(label: l10n.studentGuardianOccupation, value: occupation),
          if (guardian.isPrimary || guardian.isEmergencyContact) ...[
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                if (guardian.isPrimary) AppTag(l10n.studentGuardianPrimary),
                if (guardian.isEmergencyContact) AppTag(l10n.studentGuardianEmergency),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
