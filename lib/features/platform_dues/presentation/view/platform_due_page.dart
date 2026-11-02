import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/format/money.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/amount_text.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/bloc/platform_due_bloc.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/due_error_text.dart';
import 'package:bravynix_school_erp/features/platform_dues/presentation/view/due_status_chips.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One due: what it is for, how the total was reached and, once paid, how it was paid (BIL-02). View only.
class PlatformDuePage extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    // One bloc per due, so opening another due reads that one.
    key: ValueKey('platformDue.$id'),
    create: (_) => PlatformDueBloc(getIt<PlatformDuesRepository>(), id: id)..add(const PlatformDueRequested()),
    child: const PlatformDueView(),
  );
}

class PlatformDueView extends StatelessWidget {
  const new({this.clock = DateTime.now, super.key});

  /// What "today" is, for the Overdue chip.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.dueDetailTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocBuilder<PlatformDueBloc, PlatformDueState>(
              builder: (context, state) => switch (state) {
                PlatformDueLoading() => const _Skeleton(),
                // A due that is not this Society's cannot be opened again: only the other failures can be retried.
                PlatformDueFailed(:final failure) when failure.code == 'NOT_FOUND' || failure.code == 'FORBIDDEN' =>
                  StatePanel.forbidden(
                    key: const Key('platformDue.unavailable'),
                    title: dueErrorText(l10n, failure),
                  ),
                PlatformDueFailed(:final failure) => StatePanel.error(
                  key: const Key('platformDue.failed'),
                  title: dueErrorText(l10n, failure),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<PlatformDueBloc>().add(const PlatformDueRequested()),
                ),
                PlatformDueLoaded(:final due) => _Due(due: due, today: Formatters.schoolDay(clock())),
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
        SkeletonBox(height: 160, radius: AppRadius.card),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 140, radius: AppRadius.card),
      ],
    ),
  );
}

class _Due extends StatelessWidget {
  const new({required this.due, required this.today});

  final PlatformDue due;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final adjusted = !isZeroAmount(due.adjustmentAmount);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (due.status == DueStatus.cancelled) ...[
          InlineMessage.info(l10n.dueCancelledNote),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(due.institutionName, style: text.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              DueStatusChips(due: due, today: today),
              const SizedBox(height: AppSpacing.sm),
              KeyValueRow(label: l10n.dueInvoiceNumber, value: due.invoiceNo, mono: true),
              KeyValueRow(
                label: l10n.duePeriodLabel,
                value: l10n.duePeriod(
                  Formatters.schoolDate(due.periodStartDate),
                  Formatters.schoolDate(due.periodEndDate),
                ),
              ),
              if (due.status == DueStatus.due && due.dueDate != null)
                KeyValueRow(label: l10n.duePayByLabel, value: Formatters.schoolDate(due.dueDate!)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.dueHowReached),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountSplitRow(
                label: l10n.dueStudentsTimesRate(due.studentCount, formatRupees(due.ratePerStudentAmount)),
                amount: due.baseAmount,
              ),
              if (adjusted)
                AmountSplitRow(label: l10n.dueAdjustment, amount: due.adjustmentAmount, note: due.adjustmentNote),
              const Divider(),
              AmountSplitRow(label: l10n.dueTotal, amount: due.totalAmount, emphasis: true),
            ],
          ),
        ),
        if (due.status == DueStatus.paid) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(title: l10n.duePaymentTitle),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Column(
              children: [
                if (due.paidDate != null)
                  KeyValueRow(label: l10n.duePaidOnLabel, value: Formatters.schoolDate(due.paidDate!)),
                if (due.paymentMode case final mode?) KeyValueRow(label: l10n.duePaidBy, value: _modeName(l10n, mode)),
                if (due.paymentReference case final reference?)
                  KeyValueRow(label: l10n.duePaymentReference, value: reference, mono: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _modeName(AppLocalizations l10n, PaymentMode mode) => switch (mode) {
    PaymentMode.cash => l10n.paymentModeCash,
    PaymentMode.bankTransfer => l10n.paymentModeBankTransfer,
    PaymentMode.upi => l10n.paymentModeUpi,
    PaymentMode.cheque => l10n.paymentModeCheque,
  };
}
