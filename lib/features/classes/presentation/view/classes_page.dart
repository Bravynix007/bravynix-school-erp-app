import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_bulk_page.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_error_text.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_form_page.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/sections_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Classes: the classes of the chosen Institution (CLS-01). Owners and Institution Admins reach School
/// setup, and both may add, change and deactivate (API design 10.4j).
class ClassesPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.classesTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              builder: (context, institution) => BlocProvider(
                create: (_) => ClassesBloc(getIt<ClassesRepository>(), institution.id)..add(const ListRequested()),
                child: const ClassesView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The classes of one Institution, under the switcher.
class ClassesView extends StatelessWidget {
  const new({super.key});

  /// A saved class joins the list, so it is read again when a form closes with true.
  static Future<void> _open(BuildContext context, String route, Object extra, {bool always = false}) async {
    final bloc = context.read<ClassesBloc>();
    final saved = await context.push<bool>(route, extra: extra);
    if (always || (saved ?? false)) bloc.add(const ListRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ClassesBloc>();
    void add() => _open(context, AppRoutes.classForm, ClassFormArgs(institutionId: bloc.institutionId));
    return BlocConsumer<ClassesBloc, ListState<SchoolClass>>(
      listenWhen: (previous, current) => current is ListLoaded<SchoolClass> && current.changed != null,
      listener: (context, state) {
        if (state is ListLoaded<SchoolClass>) {
          AppSnackbar.show(
            context,
            message: l10n.classDeactivated(state.changed!.displayName),
            kind: AppSnackbarKind.success,
          );
        }
      },
      builder: (context, state) => switch (state) {
        ListLoading<SchoolClass>() => SkeletonCards(semanticLabel: l10n.loading, heights: const [96, 96]),
        ListFailed<SchoolClass>(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('classes.forbidden'),
          title: classErrorText(l10n, failure),
        ),
        ListFailed<SchoolClass>(:final failure) => StatePanel.error(
          key: const Key('classes.failed'),
          title: classErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => bloc.add(const ListRequested()),
        ),
        ListLoaded<SchoolClass>(:final items) when items.isEmpty => StatePanel.empty(
          title: l10n.classesEmptyTitle,
          message: l10n.classesEmptyMessage,
          actionLabel: l10n.classAdd,
          onAction: add,
        ),
        ListLoaded<SchoolClass>() => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            if (state.actionFailure case final failure?) ...[
              InlineMessage.error(classErrorText(l10n, failure), key: const Key('classes.actionFailed')),
              const SizedBox(height: AppSpacing.sm),
            ],
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppButton(
                  key: const Key('classes.add'),
                  label: l10n.classAdd,
                  icon: Icons.add,
                  variant: AppButtonVariant.secondary,
                  onPressed: add,
                ),
                AppButton(
                  key: const Key('classes.addSeveral'),
                  label: l10n.classAddSeveral,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _open(
                    context,
                    AppRoutes.classBulk,
                    ClassBulkArgs(
                      institutionId: bloc.institutionId,
                      added: {for (final item in state.items) item.predefinedClass.id},
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final schoolClass in state.items) ...[
              _ClassCard(
                schoolClass: schoolClass,
                busy: state.busyId == schoolClass.id,
                locked: state.busyId != null,
                onEdit: () => _open(
                  context,
                  AppRoutes.classForm,
                  ClassFormArgs(institutionId: bloc.institutionId, schoolClass: schoolClass),
                ),
                // Sections are added and deactivated there, so the count on the card is read again on the way back.
                onSections: () =>
                    _open(context, AppRoutes.classSections, SectionsArgs(schoolClass: schoolClass), always: true),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  const new({
    required this.schoolClass,
    required this.busy,
    required this.locked,
    required this.onEdit,
    required this.onSections,
  });

  final SchoolClass schoolClass;

  /// A change to this class is on its way.
  final bool busy;

  /// A change to any class is on its way, so no card starts another.
  final bool locked;
  final VoidCallback onEdit;
  final VoidCallback onSections;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final detail = [
      schoolClass.category.name,
      l10n.classSections(schoolClass.sectionCount),
      ?schoolClass.code,
    ].join(' · ');
    return AppCard(
      key: ValueKey('class.${schoolClass.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(schoolClass.displayName, style: text.titleMedium),
          Text(detail, style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton(
                key: ValueKey('class.edit.${schoolClass.id}'),
                label: l10n.classEdit,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: locked ? null : onEdit,
              ),
              AppButton(
                key: ValueKey('class.sections.${schoolClass.id}'),
                label: l10n.classOpenSections,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: locked ? null : onSections,
              ),
              AppButton(
                key: ValueKey('class.deactivate.${schoolClass.id}'),
                label: l10n.classDeactivate,
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
    final bloc = context.read<ClassesBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.classDeactivateTitle(schoolClass.displayName),
      message: l10n.classDeactivateMessage,
      confirmLabel: l10n.classDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(ClassDeactivated(schoolClass));
  }
}
