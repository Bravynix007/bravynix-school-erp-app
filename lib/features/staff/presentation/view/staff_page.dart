import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/paged_list_view.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_form_page.dart';
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

/// Opens the form that adds a staff member to this Institution; a saved one joins the list, so it is read again when the
/// form closes with true.
Future<void> _openAddForm(BuildContext context) async {
  final bloc = context.read<StaffBloc>();
  final saved = await context.push<bool>(AppRoutes.staffForm, extra: StaffFormArgs.add(bloc.institutionId));
  if (saved ?? false) bloc.add(const PagedListRequested());
}

/// The staff of one Institution, under the switcher: a search box over the pages read so far.
class StaffView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffBloc>();
    return PagedListView<StaffListEntry>(
      bloc: bloc,
      keyPrefix: 'staff',
      searchHint: l10n.staffSearchHint,
      searchClearTooltip: l10n.staffSearchClear,
      loadMoreLabel: l10n.staffLoadMore,
      errorText: (failure) => staffErrorText(l10n, failure),
      onRetry: () => bloc.add(const PagedListRequested()),
      empty: (context, query) => query.isEmpty
          ? StatePanel.empty(
              title: l10n.staffEmptyTitle,
              message: l10n.staffEmptyMessage,
              actionLabel: l10n.staffAddTitle,
              onAction: () => _openAddForm(context),
            )
          : StatePanel.empty(
              key: const Key('staff.noMatch'),
              title: l10n.staffNoMatchTitle(query),
              message: l10n.staffNoMatchMessage,
            ),
      leading: (context, {required idle}) => [
        AppButton(
          key: const Key('staff.add'),
          label: l10n.staffAddTitle,
          icon: Icons.add,
          variant: AppButtonVariant.secondary,
          onPressed: idle ? () => _openAddForm(context) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      idOf: (entry) => entry.summary.id,
      itemBuilder: (context, entry, {required busy, required locked}) =>
          _StaffCard(entry: entry, busy: busy, locked: locked),
      changedMessage: (entry) => l10n.staffDeactivated(entry.summary.fullName),
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
            onTap: locked ? null : () => _openProfile(context),
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

  /// The profile may have changed the person (Edit, and the access screens to come), so the list is read again on the
  /// way back.
  Future<void> _openProfile(BuildContext context) async {
    final bloc = context.read<StaffBloc>();
    await context.push<void>(AppRoutes.staffMember(entry.summary.id));
    if (!bloc.isClosed) bloc.add(const PagedListRequested());
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
