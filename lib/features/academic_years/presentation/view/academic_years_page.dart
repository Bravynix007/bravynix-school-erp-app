import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/bloc/academic_years_bloc.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_error_text.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_form_page.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Academic years: the years of the chosen Institution, with the current one marked (AY-01). Owners and
/// Institution Admins reach School setup, and both may add, change, make current and deactivate (API design 10.4h).
class AcademicYearsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.academicYearsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              builder: (context, institution) => BlocProvider(
                create: (_) =>
                    AcademicYearsBloc(getIt<AcademicYearsRepository>(), institution.id)
                      ..add(const AcademicYearsRequested()),
                child: const AcademicYearsView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The years of one Institution, under the switcher.
class AcademicYearsView extends StatelessWidget {
  const new({super.key});

  Future<void> _openForm(BuildContext context, {AcademicYear? year}) async {
    final bloc = context.read<AcademicYearsBloc>();
    final saved = await context.push<bool>(
      AppRoutes.academicYearForm,
      extra: AcademicYearFormArgs(institutionId: bloc.institutionId, year: year),
    );
    if (saved ?? false) bloc.add(const AcademicYearsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AcademicYearsBloc, AcademicYearsState>(
      listenWhen: (previous, current) => current is AcademicYearsLoaded && current.notice != null,
      listener: (context, state) {
        if (state is! AcademicYearsLoaded) return;
        AppSnackbar.show(
          context,
          message: switch (state.notice!) {
            AcademicYearsNotice.madeCurrent => l10n.academicYearMadeCurrent(state.noticeYear!.name),
            AcademicYearsNotice.deactivated => l10n.academicYearDeactivated,
          },
          kind: AppSnackbarKind.success,
        );
      },
      builder: (context, state) => switch (state) {
        AcademicYearsLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [120, 120]),
        AcademicYearsFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('academicYears.forbidden'),
          title: academicYearErrorText(l10n, failure),
        ),
        AcademicYearsFailed(:final failure) => StatePanel.error(
          key: const Key('academicYears.failed'),
          title: academicYearErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<AcademicYearsBloc>().add(const AcademicYearsRequested()),
        ),
        AcademicYearsLoaded(:final years) when years.isEmpty => StatePanel.empty(
          title: l10n.academicYearsEmptyTitle,
          message: l10n.academicYearsEmptyMessage,
          actionLabel: l10n.academicYearAdd,
          onAction: () => _openForm(context),
        ),
        AcademicYearsLoaded() => ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            if (state.actionFailure case final failure?) ...[
              InlineMessage.error(academicYearErrorText(l10n, failure), key: const Key('academicYears.actionFailed')),
              const SizedBox(height: AppSpacing.sm),
            ],
            AppButton(
              key: const Key('academicYears.add'),
              label: l10n.academicYearAdd,
              icon: Icons.add,
              variant: AppButtonVariant.secondary,
              onPressed: () => _openForm(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final year in state.years) ...[
              _YearCard(
                year: year,
                busy: state.busyId == year.id,
                locked: state.busyId != null,
                onEdit: () => _openForm(context, year: year),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      },
    );
  }
}

class _YearCard extends StatelessWidget {
  const new({required this.year, required this.busy, required this.locked, required this.onEdit});

  final AcademicYear year;

  /// A change to this year is on its way.
  final bool busy;

  /// A change to any year is on its way, so no card starts another.
  final bool locked;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bloc = context.read<AcademicYearsBloc>();
    return AppCard(
      key: ValueKey('academicYear.${year.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(year.name, style: text.titleMedium),
              if (year.isCurrent) StatusChip(label: l10n.academicYearCurrent, tone: StatusTone.success),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.academicYearDates(Formatters.schoolDate(year.startDate), Formatters.schoolDate(year.endDate)),
            style: text.bodyMedium,
          ),
          if (year.isCurrent) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.academicYearCurrentHint, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton(
                key: ValueKey('academicYear.edit.${year.id}'),
                label: l10n.academicYearEdit,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: locked ? null : onEdit,
              ),
              if (!year.isCurrent) ...[
                AppButton(
                  key: ValueKey('academicYear.makeCurrent.${year.id}'),
                  label: l10n.academicYearMakeCurrent,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  loading: busy,
                  onPressed: locked ? null : () => bloc.add(AcademicYearMadeCurrent(year)),
                ),
                // The current year cannot be deactivated (409 CURRENT_YEAR_LOCKED): another is made current first.
                AppButton(
                  key: ValueKey('academicYear.deactivate.${year.id}'),
                  label: l10n.academicYearDeactivate,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.medium,
                  onPressed: locked ? null : () => _confirmDeactivate(context),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AcademicYearsBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.academicYearDeactivateTitle(year.name),
      message: l10n.academicYearDeactivateMessage,
      confirmLabel: l10n.academicYearDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(AcademicYearDeactivated(year));
  }
}
