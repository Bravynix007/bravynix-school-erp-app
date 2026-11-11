import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/app_tag.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_profile.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_access_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_admin_access_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_block_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_class_teacher_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_access_view.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_admin_access_section.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_class_teacher_section.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_page.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_names.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_settings_view.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Teachers / Staff → one staff member (STF-03): the personal information, access and settings tabs of
/// PRD 7.5. The documents tab arrives with the screen that acts on it.
class StaffProfilePage extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          StaffProfileBloc(getIt<StaffRepository>(), getIt<MastersRepository>(), id)
            ..add(const StaffProfileRequested()),
      child: StaffProfileView(
        isOwner: context.watch<SessionBloc>().state.isSocietyOwner,
      ),
    );
  }
}

class StaffProfileView extends StatelessWidget {
  const new({required this.isOwner, super.key});

  /// Only the Society Owner changes the extra Institutions.
  final bool isOwner;

  /// A saved change shows here, so the profile is read again when the form closes with true.
  static Future<void> _openEditForm(BuildContext context) async {
    final bloc = context.read<StaffProfileBloc>();
    final saved = await context.push<bool>(AppRoutes.staffForm, extra: StaffFormArgs.edit(bloc.id));
    if (saved ?? false) bloc.add(const StaffProfileRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(
            title: l10n.staffProfileTitle,
            onBack: () => context.pop(),
            backTooltip: l10n.back,
            actions: [
              if (context.select<StaffProfileBloc, bool>((bloc) => bloc.state is StaffProfileLoaded))
                AppIconButton(
                  key: const Key('staffProfile.edit'),
                  icon: Icons.edit_outlined,
                  tooltip: l10n.staffEditTitle,
                  onPressed: () => _openEditForm(context),
                ),
            ],
          ),
          Expanded(
            child: BlocBuilder<StaffProfileBloc, StaffProfileState>(
              builder: (context, state) => switch (state) {
                StaffProfileLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 112]),
                StaffProfileFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('staffProfile.forbidden'),
                  title: staffErrorText(l10n, failure),
                ),
                StaffProfileFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                  key: const Key('staffProfile.notFound'),
                  title: staffErrorText(l10n, failure),
                ),
                StaffProfileFailed(:final failure) => StatePanel.error(
                  key: const Key('staffProfile.failed'),
                  title: staffErrorText(l10n, failure),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<StaffProfileBloc>().add(const StaffProfileRequested()),
                ),
                // The two tabs that change the staff member are provided here, so what is ticked and not yet saved is still
                // there when the person comes back from another tab. They are made when their tab is first opened.
                StaffProfileLoaded(:final profile, :final tab) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) => StaffAccessBloc(
                        getIt<StaffRepository>(),
                        getIt<SubjectsRepository>(),
                        getIt<InstitutionsRepository>(),
                        member: profile.member,
                        canChangeInstitutions: isOwner,
                      )..add(const StaffAccessStarted()),
                    ),
                    BlocProvider(
                      create: (_) => StaffClassTeacherBloc(
                        getIt<StaffRepository>(),
                        getIt<AcademicYearsRepository>(),
                        getIt<ClassesRepository>(),
                        getIt<SectionsRepository>(),
                        member: profile.member,
                      )..add(const StaffClassTeacherStarted()),
                    ),
                    // The Society Owner's alone. It reads when the part is first shown.
                    if (isOwner)
                      BlocProvider(
                        create: (_) => StaffAdminAccessBloc(
                          getIt<InstitutionsRepository>(),
                          member: profile.member,
                        )..add(const StaffAdminAccessStarted()),
                      ),
                    BlocProvider(create: (_) => StaffBlockBloc(getIt<StaffRepository>(), profile.member)),
                  ],
                  // The Admin part reads again when the extra Institutions are saved, as those are the ones an Admin can
                  // be made at. It is told here and not made again, so the tab keeps its place and a change on its way.
                  child: BlocListener<StaffProfileBloc, StaffProfileState>(
                    listenWhen: (previous, current) =>
                        isOwner &&
                        previous is StaffProfileLoaded &&
                        current is StaffProfileLoaded &&
                        !listEquals(
                          previous.profile.member.institutionIds,
                          current.profile.member.institutionIds,
                        ),
                    listener: (context, state) => context.read<StaffAdminAccessBloc>().add(
                      StaffAdminInstitutionsChanged((state as StaffProfileLoaded).profile.member.institutionIds),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenMargin,
                            AppSpacing.screenMargin,
                            AppSpacing.screenMargin,
                            0,
                          ),
                          child: AppSegmentedControl<StaffProfileTab>(
                            options: StaffProfileTab.values,
                            labelOf: (tab) => switch (tab) {
                              StaffProfileTab.personal => l10n.staffTabPersonal,
                              StaffProfileTab.access => l10n.staffTabAccess,
                              StaffProfileTab.settings => l10n.staffTabSettings,
                            },
                            selected: tab,
                            onChanged: (tab) => context.read<StaffProfileBloc>().add(StaffProfileTabChosen(tab)),
                          ),
                        ),
                        Expanded(
                          child: switch (tab) {
                            StaffProfileTab.personal => _Details(profile: profile),
                            StaffProfileTab.access => StaffAccessView(
                              below: [
                                const StaffClassTeacherSection(),
                                if (isOwner) StaffAdminAccessView(memberName: profile.member.fullName),
                              ],
                            ),
                            StaffProfileTab.settings => const StaffSettingsView(),
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.profile});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final member = profile.member;
    final address = member.address;
    final addressText = [
      ?address.line1,
      ?address.line2,
      [?profile.cityName, ?profile.stateName, ?profile.countryName].join(', '),
      ?address.pincode,
    ].where((line) => line.isNotEmpty).join('\n');
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(member.fullName, style: text.headlineSmall),
              ),
              if (member.isBlocked) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusChip(label: l10n.staffBlocked, tone: StatusTone.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              if (member.employeeCode case final code?)
                KeyValueRow(label: l10n.staffEmployeeId, value: code, mono: true),
              if (profile.designationName case final designation?)
                KeyValueRow(label: l10n.staffDesignation, value: designation),
              if (profile.categoryName case final category?) KeyValueRow(label: l10n.staffCategory, value: category),
              if (member.gender case final gender?)
                KeyValueRow(label: l10n.staffGender, value: genderName(l10n, gender)),
              if (member.dateOfBirth case final day?)
                KeyValueRow(label: l10n.staffDateOfBirth, value: Formatters.schoolDate(day)),
              if (member.bloodGroup case final group?) KeyValueRow(label: l10n.staffBloodGroup, value: group),
              if (member.nationality case final nationality?)
                KeyValueRow(label: l10n.staffNationality, value: nationality),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.staffSectionContact),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyValueRow(label: l10n.profileEmail, value: member.email),
              KeyValueRow(label: l10n.staffMobile, value: member.mobile.display),
              if (member.alternateNumber case final number?)
                KeyValueRow(label: l10n.staffAlternateNumber, value: number),
              if (addressText.isNotEmpty) KeyValueRow(label: l10n.staffAddress, value: addressText),
            ],
          ),
        ),
        if (member.joiningDate != null || member.resignationDate != null || member.employmentType != null) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: l10n.staffSectionEmployment),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (member.employmentType case final type?)
                  KeyValueRow(label: l10n.staffEmploymentType, value: employmentName(l10n, type)),
                if (member.joiningDate case final day?)
                  KeyValueRow(label: l10n.staffJoiningDate, value: Formatters.schoolDate(day)),
                if (member.resignationDate case final day?)
                  KeyValueRow(label: l10n.staffResignationDate, value: Formatters.schoolDate(day)),
              ],
            ),
          ),
        ],
        if (member.educations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: l10n.staffSectionEducation),
          const SizedBox(height: AppSpacing.xs),
          for (final education in member.educations) ...[
            _EducationCard(education: education),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
        if (member.emergencyContacts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: l10n.staffSectionEmergency),
          const SizedBox(height: AppSpacing.xs),
          for (final contact in member.emergencyContacts) ...[
            _ContactCard(contact: contact),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

class _EducationCard extends StatelessWidget {
  const new({required this.education});

  final Education education;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = [
      ?education.qualification,
      ?education.specialization,
      ?education.institutionName,
      if (education.yearOfPassing case final year?) '$year',
    ].join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(education.degree, style: text.titleMedium),
          if (detail.isNotEmpty) Text(detail, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const new({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = contact.relation == null
        ? contact.contactName
        : l10n.staffContactRelation(contact.contactName, contact.relation!);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: text.titleMedium),
          Text([contact.phone.display, ?contact.alternateNumber].join(' · '), style: text.bodySmall),
          if (contact.isPrimary) ...[const SizedBox(height: AppSpacing.xxs), AppTag(l10n.staffPrimaryContact)],
        ],
      ),
    );
  }
}
