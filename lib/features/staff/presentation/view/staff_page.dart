import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_search_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Teachers / Staff: the staff of the chosen Institution (STF-01). Owners and Institution Admins reach
/// School setup, and both may deactivate (STF-05).
class StaffPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.staffTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              builder: (context, institution) => BlocProvider(
                create: (_) =>
                    StaffBloc(getIt<StaffRepository>(), getIt<MastersRepository>(), institution.id)
                      ..add(const PagedListRequested()),
                child: const StaffView(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The staff of one Institution, under the switcher: a search box over the pages read so far.
class StaffView extends StatefulWidget {
  const new({super.key});

  @override
  State<StaffView> createState() => _StaffViewState();
}

class _StaffViewState extends State<StaffView> {
  static const _maxSearch = 100;

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffBloc>();
    final idle = context.select<StaffBloc, bool>(
      (bloc) => switch (bloc.state) {
        PagedListLoaded<StaffListEntry>(:final busyId) => busyId == null,
        _ => true,
      },
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin, AppSpacing.sm, AppSpacing.screenMargin, 0),
          // The search waits while a deactivation goes, so its outcome is not lost to a new list.
          child: AppSearchField(
            key: const Key('staff.search'),
            controller: _search,
            hint: l10n.staffSearchHint,
            clearTooltip: l10n.staffSearchClear,
            enabled: idle,
            // STF-01 takes 2 to 100 letters (API design 13.1); a pasted line is cut instead of refused.
            maxLength: _maxSearch,
            // The search is sent on the keyboard's search key, and cleared as soon as the box is emptied.
            onSubmitted: (text) => bloc.add(PagedListSearched(text)),
            onChanged: (text) {
              if (text.isEmpty) bloc.add(const PagedListSearched(''));
            },
          ),
        ),
        Expanded(
          child: BlocConsumer<StaffBloc, PagedListState<StaffListEntry>>(
            listenWhen: (previous, current) => current is PagedListLoaded<StaffListEntry> && current.changed != null,
            listener: (context, state) {
              if (state is PagedListLoaded<StaffListEntry>) {
                AppSnackbar.show(
                  context,
                  message: l10n.staffDeactivated(state.changed!.summary.fullName),
                  kind: AppSnackbarKind.success,
                );
              }
            },
            builder: (context, state) => switch (state) {
              PagedListLoading<StaffListEntry>() => SkeletonCards(
                semanticLabel: l10n.loading,
                heights: const [96, 96],
              ),
              PagedListFailed<StaffListEntry>(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                key: const Key('staff.forbidden'),
                title: staffErrorText(l10n, failure),
              ),
              PagedListFailed<StaffListEntry>(:final failure) => StatePanel.error(
                key: const Key('staff.failed'),
                title: staffErrorText(l10n, failure),
                actionLabel: l10n.retry,
                onAction: () => bloc.add(const PagedListRequested()),
              ),
              PagedListLoaded<StaffListEntry>(:final items, :final query) when items.isEmpty =>
                query.isEmpty
                    ? StatePanel.empty(title: l10n.staffEmptyTitle, message: l10n.staffEmptyMessage)
                    : StatePanel.empty(
                        key: const Key('staff.noMatch'),
                        title: l10n.staffNoMatchTitle(query),
                        message: l10n.staffNoMatchMessage,
                      ),
              PagedListLoaded<StaffListEntry>() => _StaffList(state: state),
            },
          ),
        ),
      ],
    );
  }
}

class _StaffList extends StatelessWidget {
  const new({required this.state});

  final PagedListLoaded<StaffListEntry> state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffBloc>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        if (state.actionFailure case final failure?) ...[
          InlineMessage.error(staffErrorText(l10n, failure), key: const Key('staff.actionFailed')),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final entry in state.items) ...[
          _StaffCard(entry: entry, busy: state.busyId == entry.summary.id, locked: state.busyId != null),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.moreFailure case final failure?) ...[
          InlineMessage.error(staffErrorText(l10n, failure), key: const Key('staff.moreFailed')),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (state.hasMore)
          AppButton(
            key: const Key('staff.more'),
            label: state.moreFailure == null ? l10n.staffLoadMore : l10n.retry,
            variant: AppButtonVariant.secondary,
            loading: state.loadingMore,
            onPressed: state.busyId == null ? () => bloc.add(const PagedListMoreRequested()) : null,
          ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  const new({required this.entry, required this.busy, required this.locked});

  final StaffListEntry entry;

  /// A change to this staff member is on its way.
  final bool busy;

  /// A change to any staff member is on its way, so no card starts another.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = entry.summary;
    final detail = [?summary.employeeCode, ?entry.designationName, ?entry.categoryName].join(' · ');
    return AppCard(
      key: ValueKey('staff.${summary.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PersonListTile(
            name: summary.fullName,
            subtitle: detail,
            trailing: summary.isBlocked ? StatusChip(label: l10n.staffBlocked, tone: StatusTone.error) : null,
            onTap: locked ? null : () => context.push(AppRoutes.staffMember(summary.id)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              key: ValueKey('staff.deactivate.${summary.id}'),
              label: l10n.staffDeactivate,
              variant: AppButtonVariant.text,
              size: AppButtonSize.medium,
              loading: busy,
              onPressed: locked ? null : () => _confirmDeactivate(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.staffDeactivateTitle(entry.summary.fullName),
      message: l10n.staffDeactivateMessage,
      confirmLabel: l10n.staffDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(StaffDeactivated(entry));
  }
}
