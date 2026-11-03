import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/sections_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_error_text.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_form_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which class the sections belong to. The class list hands it over: no endpoint reads one class.
class SectionsArgs {
  const new({required this.schoolClass});

  final SchoolClass schoolClass;
}

/// School setup → Classes → Sections of one class (SEC-01). Owners and Institution Admins reach School setup, and both
/// may add, change and deactivate (API design 10.4j). The class list behind reads again when this closes, as the count
/// of sections it shows may have changed.
class SectionsPage extends StatelessWidget {
  const new({required this.args, super.key});

  final SectionsArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final schoolClass = args.schoolClass;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.sectionsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocProvider(
              create: (_) => SectionsBloc(getIt<SectionsRepository>(), schoolClass.id)..add(const SectionsRequested()),
              child: SectionsView(schoolClass: schoolClass),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionsView extends StatelessWidget {
  const new({required this.schoolClass, super.key});

  final SchoolClass schoolClass;

  /// A saved section joins the list, so it is read again when a form closes with true.
  Future<void> _open(BuildContext context, SectionFormArgs args) async {
    final bloc = context.read<SectionsBloc>();
    final saved = await context.push<bool>(AppRoutes.sectionForm, extra: args);
    if (saved ?? false) bloc.add(const SectionsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SectionsBloc>();
    final text = Theme.of(context).textTheme;
    return BlocConsumer<SectionsBloc, SectionsState>(
      listenWhen: (previous, current) => current is SectionsLoaded && current.deactivated != null,
      listener: (context, state) {
        if (state is SectionsLoaded) {
          AppSnackbar.show(
            context,
            message: l10n.sectionDeactivated(state.deactivated!.displayName),
            kind: AppSnackbarKind.success,
          );
        }
      },
      builder: (context, state) {
        void add(List<Section> sections) => _open(
          context,
          SectionFormArgs(
            classId: schoolClass.id,
            taken: {for (final section in sections) section.predefinedSection.id},
          ),
        );
        return switch (state) {
          SectionsLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [96, 96]),
          SectionsFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
            key: const Key('sections.forbidden'),
            title: sectionErrorText(l10n, failure),
          ),
          SectionsFailed(:final failure) => StatePanel.error(
            key: const Key('sections.failed'),
            title: sectionErrorText(l10n, failure),
            actionLabel: l10n.retry,
            onAction: () => bloc.add(const SectionsRequested()),
          ),
          SectionsLoaded(:final sections) when sections.isEmpty => StatePanel.empty(
            title: l10n.sectionsEmptyTitle,
            message: l10n.sectionsEmptyMessage(schoolClass.displayName),
            actionLabel: l10n.sectionAdd,
            onAction: () => add(sections),
          ),
          SectionsLoaded(:final sections) => ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              Text(schoolClass.displayName, style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (state.actionFailure case final failure?) ...[
                InlineMessage.error(sectionErrorText(l10n, failure), key: const Key('sections.actionFailed')),
                const SizedBox(height: AppSpacing.sm),
              ],
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  key: const Key('sections.add'),
                  label: l10n.sectionAdd,
                  icon: Icons.add,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => add(sections),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final section in sections) ...[
                _SectionCard(
                  section: section,
                  busy: state.busyId == section.id,
                  locked: state.busyId != null,
                  onEdit: () => _open(context, SectionFormArgs(classId: schoolClass.id, section: section)),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        };
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const new({required this.section, required this.busy, required this.locked, required this.onEdit});

  final Section section;

  /// A change to this section is on its way.
  final bool busy;

  /// A change to any section is on its way, so no card starts another.
  final bool locked;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final detail = [
      if (section.predefinedSection.name != section.displayName) section.predefinedSection.name,
      if (section.capacity == null) l10n.sectionNoCapacity else l10n.sectionCapacity(section.capacity!),
      // The count comes with the People module (Phase 4); until then a dash.
      l10n.sectionStudents(section.currentStudentCount?.toString() ?? '—'),
    ].join(' · ');
    return AppCard(
      key: ValueKey('section.${section.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(section.displayName, style: text.titleMedium),
          Text(detail, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton(
                key: ValueKey('section.edit.${section.id}'),
                label: l10n.sectionEdit,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: locked ? null : onEdit,
              ),
              AppButton(
                key: ValueKey('section.deactivate.${section.id}'),
                label: l10n.sectionDeactivate,
                variant: AppButtonVariant.text,
                size: AppButtonSize.medium,
                loading: busy,
                onPressed: locked ? null : () => _confirmDeactivate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SectionsBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.sectionDeactivateTitle(section.displayName),
      message: l10n.sectionDeactivateMessage,
      confirmLabel: l10n.sectionDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(SectionDeactivated(section));
  }
}
