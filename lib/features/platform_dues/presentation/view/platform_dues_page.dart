import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/format/money.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/widgets/amount_text.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/bloc/platform_dues_bloc.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/due_error_text.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/due_status_chips.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Profile → Platform dues (PRD 9.3): "You are due ₹X" or "All dues are paid", and what BravyNix charged each
/// Institution, newest first. View only. Only the Owners of the Society get it (API design 10.22).
class PlatformDuesPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PlatformDuesBloc(getIt<PlatformDuesRepository>())..add(const PlatformDuesRequested()),
    child: const PlatformDuesView(),
  );
}

class PlatformDuesView extends StatelessWidget {
  const new({this.clock = DateTime.now, super.key});

  /// What "today" is, for the Overdue chip.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.platformDuesTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocBuilder<PlatformDuesBloc, PlatformDuesState>(
              builder: (context, state) => switch (state) {
                PlatformDuesLoading() => const _Skeleton(),
                PlatformDuesFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('platformDues.forbidden'),
                  title: dueErrorText(l10n, failure),
                ),
                PlatformDuesFailed(:final failure) => StatePanel.error(
                  key: const Key('platformDues.failed'),
                  title: dueErrorText(l10n, failure),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<PlatformDuesBloc>().add(const PlatformDuesRequested()),
                ),
                PlatformDuesLoaded(:final dues) when dues.dues.isEmpty => StatePanel.empty(
                  title: l10n.platformDuesEmptyTitle,
                  message: l10n.platformDuesEmptyMessage,
                ),
                PlatformDuesLoaded(:final dues) => _Dues(dues: dues, today: Formatters.schoolDay(clock())),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 88, radius: AppRadius.card),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 112, radius: AppRadius.card),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 112, radius: AppRadius.card),
      ],
    ),
  );
}

class _Dues extends StatelessWidget {
  const new({required this.dues, required this.today});

  final PlatformDues dues;
  final String today;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screenMargin),
    children: [
      _Banner(dues: dues),
      const SizedBox(height: AppSpacing.md),
      for (final due in dues.dues) ...[_DueCard(due: due, today: today), const SizedBox(height: AppSpacing.xs)],
    ],
  );
}

/// What is owed, in words that cannot be mistaken (PRD 9.3). A due of 0.00 is listed but owes nothing.
class _Banner extends StatelessWidget {
  const new({required this.dues});

  final PlatformDues dues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: const Key('platformDues.banner'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              dues.hasOpenDues
                  ? l10n.platformDuesBannerDue(formatRupees(dues.totalDueAmount))
                  : l10n.platformDuesBannerPaid,
              style: text.headlineSmall,
            ),
          ),
          if (!dues.hasOpenDues) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(l10n.platformDuesBannerPaidDetail, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const new({required this.due, required this.today});

  final PlatformDueLine due;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final secondary = text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return AppCard(
      key: ValueKey('due.${due.id}'),
      onTap: () => context.push(AppRoutes.platformDue(due.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(due.institutionName, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(due.invoiceNo, style: AppTextStyles.code.copyWith(color: secondary?.color)),
          Text(
            l10n.duePeriod(Formatters.schoolDate(due.periodStartDate), Formatters.schoolDate(due.periodEndDate)),
            style: secondary,
          ),
          const SizedBox(height: AppSpacing.xs),
          AmountText(due.totalAmount, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          DueStatusChips(due: due, today: today),
          if (_dateLine(l10n) case final line?) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(line, style: secondary),
          ],
        ],
      ),
    );
  }

  /// "Pay by" for what is still owed, "Paid on" for what was paid; a cancelled due has neither.
  String? _dateLine(AppLocalizations l10n) => switch (due.status) {
    DueStatus.due when due.dueDate != null => l10n.duePayBy(Formatters.schoolDate(due.dueDate!)),
    DueStatus.paid when due.paidDate != null => l10n.duePaidOn(Formatters.schoolDate(due.paidDate!)),
    _ => null,
  };
}
