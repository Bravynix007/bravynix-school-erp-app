import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/promotion.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/promotion_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_frame.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_warnings.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Who the form promotes: one student as the list shows them, or the students of a class or section of an Institution.
class StudentPromoteArgs {
  const new one(StudentListEntry this.entry) : institutionId = null;

  const new group(String this.institutionId) : entry = null;

  final StudentListEntry? entry;
  final String? institutionId;

  PromotionScope get scope => switch (entry) {
    final entry? => PromoteOne(entry.summary),
    null => PromoteGroup(institutionId!),
  };
}

/// School setup → Students → Promote (STU-09, PRM-01). Closes with `true` once it went through, so the list reads again.
class StudentPromotePage extends StatelessWidget {
  const new({required this.args, super.key});

  final StudentPromoteArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PromotionBloc(
      getIt<StudentsRepository>(),
      SectionOptionsSource(
        years: getIt<AcademicYearsRepository>(),
        classes: getIt<ClassesRepository>(),
        sections: getIt<SectionsRepository>(),
      ),
      args.scope,
    )..add(const PromotionStarted()),
    child: StudentPromoteView(entry: args.entry),
  );
}

class StudentPromoteView extends StatelessWidget {
  const new({required this.entry, super.key});

  /// The student that is promoted; null for a class or section.
  final StudentListEntry? entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = entry == null ? l10n.promotionTitleGroup : l10n.promotionTitleOne;
    return BlocBuilder<PromotionBloc, PromotionState>(
      builder: (context, state) => switch (state) {
        PromotionReady() => _Form(entry: entry, state: state),
        PromotionDone() => _Done(entry: entry, state: state),
        PromotionFailed(:final failure) when failure.code == 'FORBIDDEN' => StudentFrame(
          title: title,
          child: StatePanel.forbidden(key: const Key('promotion.forbidden'), title: studentErrorText(l10n, failure)),
        ),
        PromotionFailed(:final failure) => StudentFrame(
          title: title,
          child: StatePanel.error(
            key: const Key('promotion.failed'),
            title: studentErrorText(l10n, failure),
            actionLabel: l10n.retry,
            onAction: () => context.read<PromotionBloc>().add(const PromotionStarted()),
          ),
        ),
        PromotionLoading() => StudentFrame(
          title: title,
          child: SkeletonCards(semanticLabel: l10n.loading, heights: const [120, 200]),
        ),
      },
    );
  }
}

class _Form extends StatefulWidget {
  const new({required this.entry, required this.state});

  final StudentListEntry? entry;
  final PromotionReady state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _rollNumber = TextEditingController(text: widget.entry?.summary.placement.rollNumber);

  @override
  void dispose() {
    _rollNumber.dispose();
    super.dispose();
  }

  /// The fields the form shows an error under, named as the API names them.
  static const _fields = {'toAcademicYearId', 'toClassId', 'toSectionId', 'rollNumber'};

  /// One question before what is hard to take back: students who complete are deactivated, and a class goes at once.
  Future<void> _submit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<PromotionBloc>();
    final state = widget.state;
    final roll = _rollNumber.text;
    if (widget.entry == null || state.completes) {
      final confirmed = await showConfirmDialog(
        context: context,
        title: state.completes
            ? l10n.promotionConfirmCompletesTitle
            : l10n.promotionConfirmTitle(state.targetName ?? ''),
        message: state.completes ? l10n.promotionConfirmCompletes : l10n.promotionConfirmGroup,
        confirmLabel: l10n.promotionAction,
        cancelLabel: l10n.cancel,
        destructive: state.completes,
      );
      if (!(confirmed ?? false)) return;
    }
    bloc.add(PromotionSubmitted(rollNumber: roll));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bloc = context.read<PromotionBloc>();
    final state = widget.state;
    final entry = widget.entry;
    final failure = state.failure;
    String? error(String field) => failure?.fieldError(field)?.message;
    // A refusal that names only fields of this form is said under them; any other is said at the top.
    final banner = failure != null && !failure.namesOnly(_fields) ? promotionErrorText(l10n, failure) : null;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(
            title: entry == null ? l10n.promotionTitleGroup : l10n.promotionTitleOne,
            onBack: () => Navigator.maybePop(context),
            backTooltip: l10n.back,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                if (banner != null) ...[
                  InlineMessage.error(banner, key: const Key('promotion.error')),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (entry != null) ...[
                  Text(entry.summary.fullName, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [?entry.placeName, l10n.studentsRoll(entry.summary.placement.rollNumber)].join(' · '),
                    key: const Key('promotion.now'),
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  SectionHeader(title: l10n.promotionFrom),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MasterDropdown(
                          key: const Key('promotion.sourceYear'),
                          label: l10n.studentYear,
                          entries: [for (final year in state.years) MasterEntry(id: year.id, name: year.name)],
                          value: state.sourceYearId,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          onChanged: (id) => bloc.add(PromotionSourceYearChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('promotion.sourceClass'),
                          label: l10n.studentClass,
                          entries: [for (final choice in state.classes) MasterEntry(id: choice.id, name: choice.name)],
                          value: state.sourceClassId,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          onChanged: (id) => bloc.add(PromotionSourceClassChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('promotion.sourceSection'),
                          label: l10n.studentSection,
                          entries: [
                            for (final choice in state.sourceSections) MasterEntry(id: choice.id, name: choice.name),
                          ],
                          value: state.sourceSectionId,
                          noneLabel: l10n.promotionAllSections,
                          onChanged: (id) => bloc.add(PromotionSourceSectionChosen(id)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SectionHeader(title: l10n.promotionTo),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSwitchTile(
                        key: const Key('promotion.completes'),
                        title: l10n.promotionCompletes,
                        subtitle: l10n.promotionCompletesHelper,
                        value: state.completes,
                        onChanged: state.saving ? null : (value) => bloc.add(PromotionCompletesToggled(value: value)),
                      ),
                      if (!state.completes) ...[
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('promotion.targetYear'),
                          label: l10n.studentYear,
                          entries: [for (final year in state.targetYears) MasterEntry(id: year.id, name: year.name)],
                          value: state.targetYearId,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          error: error('toAcademicYearId'),
                          onChanged: (id) => bloc.add(PromotionTargetYearChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('promotion.targetClass'),
                          label: l10n.studentClass,
                          entries: [for (final choice in state.classes) MasterEntry(id: choice.id, name: choice.name)],
                          value: state.targetClassId,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          error: error('toClassId'),
                          onChanged: (id) => bloc.add(PromotionTargetClassChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        MasterDropdown(
                          key: const Key('promotion.targetSection'),
                          label: l10n.studentSection,
                          entries: [
                            for (final choice in state.targetSections) MasterEntry(id: choice.id, name: choice.name),
                          ],
                          value: state.targetSectionId,
                          required: true,
                          requiredLabel: l10n.fieldRequired,
                          error: error('toSectionId'),
                          onChanged: (id) => bloc.add(PromotionTargetSectionChosen(id)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (entry != null) ...[
                          AppTextField(
                            key: const Key('promotion.rollNumber'),
                            label: l10n.studentRollNumber,
                            controller: _rollNumber,
                            mono: true,
                            error: error('rollNumber'),
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(l10n.promotionRollNumberHelper, style: text.bodySmall),
                        ] else
                          AppSwitchTile(
                            key: const Key('promotion.keepRollNumbers'),
                            title: l10n.promotionKeepRollNumbers,
                            subtitle: l10n.promotionKeepRollNumbersHelper,
                            value: state.keepRollNumbers,
                            onChanged: state.saving
                                ? null
                                : (value) => bloc.add(PromotionKeepRollNumbersToggled(value: value)),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: l10n.promotionAction,
        primaryLoading: state.saving,
        onPrimary: state.canSubmit ? () => _submit(context) : null,
        secondaryLabel: l10n.cancel,
        onSecondary: () => Navigator.maybePop(context),
      ),
    );
  }
}

/// What the promotion did: who went where, who was left and why, and the second looks the server asked for.
class _Done extends StatelessWidget {
  const new({required this.entry, required this.state});

  final StudentListEntry? entry;
  final PromotionDone state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final result = state.result;
    final target = state.targetName;
    final headline = switch ((entry, target)) {
      (final entry?, null) => l10n.promotionDoneOneCompleted(entry.summary.fullName),
      (final entry?, final target?) => l10n.promotionDoneOne(entry.summary.fullName, target),
      (null, null) => l10n.promotionDoneCompleted(result.promotedCount),
      (null, final target?) => l10n.promotionDoneGroup(result.promotedCount, target),
    };
    final notes = [
      for (final reason in SkipReason.values)
        if (result.skippedFor(reason) case final count when count > 0)
          switch (reason) {
            SkipReason.notInSource => l10n.promotionSkippedNotInSource(count),
            SkipReason.alreadyEnrolled => l10n.promotionSkippedAlreadyEnrolled(count),
          },
      ...studentWarningLines(l10n, result.warnings),
    ];
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(
            title: entry == null ? l10n.promotionTitleGroup : l10n.promotionTitleOne,
            onBack: () => context.pop(true),
            backTooltip: l10n.back,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        liveRegion: true,
                        header: true,
                        child: Text(headline, key: const Key('promotion.done'), style: text.titleMedium),
                      ),
                      for (final note in notes) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(note, style: text.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: l10n.promotionDoneAction,
        onPrimary: () => context.pop(true),
      ),
    );
  }
}
