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
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/core/widgets/timetable_day_card.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/view/child_panel.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/timetable_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/day_name.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/entry_form_page.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/timetable_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "Timetable": a teacher's own week, under the Institution switcher, or a parent's child's section, under the child
/// shown at the top (API design 9.7). The days open and close; today's is open. Read only.
class TimetablePage extends StatelessWidget {
  const new({this.clock = DateTime.now, super.key});

  /// What "today" is, for the day that opens first.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parent = context.read<SessionBloc>().state.activeRole == RoleCode.studentParent;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.timetableTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          if (parent) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: ChildPanel(),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Expanded(
            child: parent
                ? BlocBuilder<ActiveChildBloc, ActiveChildState>(
                    builder: (context, child) => child is ActiveChildReady
                        // A new key per child starts the week again for that child, so the last child's never shows.
                        ? _WeekOf(
                            key: ValueKey(child.selected.studentId),
                            week: ChildWeek(child.selected.studentId),
                            today: clock(),
                          )
                        : const SizedBox.shrink(),
                  )
                : InstitutionScope(
                    builder: (context, institution) =>
                        _WeekOf(key: ValueKey(institution.id), week: OwnWeek(institution.id), today: clock()),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Which section the timetable screen opens on, and what to call it ("7th - A").
class SectionTimetableArgs {
  const new({required this.sectionId, required this.institutionId, required this.title});

  final String sectionId;
  final String institutionId;
  final String title;
}

/// School setup → Classes → a section → Timetable: the week of one section (TT-01), which an Owner or an Institution
/// Admin builds: they add, change and delete its lessons and breaks (TT-02 to TT-04).
class SectionTimetablePage extends StatelessWidget {
  const new({required this.args, this.clock = DateTime.now, super.key});

  final SectionTimetableArgs args;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.timetableTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.xs,
              AppSpacing.screenMargin,
              AppSpacing.xs,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(args.title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          Expanded(
            child: _WeekOf(
              week: SectionWeek(args.sectionId),
              today: clock(),
              institutionId: args.institutionId,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekOf extends StatelessWidget {
  const new({required this.week, required this.today, this.institutionId, super.key});

  final TimetableWeek week;
  final DateTime today;

  /// Set when the person builds this week: the Institution the form offers periods and teachers of.
  final String? institutionId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TimetableBloc(getIt<TimetableRepository>(), week)..add(const ListRequested()),
    child: TimetableView(week: week, today: today, institutionId: institutionId),
  );
}

/// The week as one card per day, Monday to Saturday. A teacher's lessons say which section they are in; everyone else's
/// say who teaches them. With an [institutionId] the person builds the week: they add entries, and change or delete
/// each.
class TimetableView extends StatelessWidget {
  const new({required this.week, required this.today, this.institutionId, super.key});

  final TimetableWeek week;

  /// Its weekday is the one that opens first (Sunday, the weekly off, opens none).
  final DateTime today;

  /// Set for a section's week that the person builds; the entry form offers this Institution's periods and teachers.
  final String? institutionId;

  static const days = [1, 2, 3, 4, 5, 6];

  bool get _editable => institutionId != null && week is SectionWeek;

  Future<void> _openForm(BuildContext context, {TimetableEntry? entry}) async {
    final bloc = context.read<TimetableBloc>();
    final saved = await context.push<bool>(
      AppRoutes.timetableEntryForm,
      extra: EntryFormArgs(sectionId: (week as SectionWeek).sectionId, institutionId: institutionId!, entry: entry),
    );
    if (saved ?? false) bloc.add(const ListRequested());
  }

  Future<void> _confirmDelete(BuildContext context, TimetableEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<TimetableBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.timetableEntryDeleteTitle,
      message: l10n.timetableEntryDeleteMessage,
      confirmLabel: l10n.timetableEntryDelete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(EntryRemoved(entry));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return BlocConsumer<TimetableBloc, ListState<TimetableEntry>>(
      listenWhen: (previous, current) => current is ListLoaded<TimetableEntry> && current.changed != null,
      listener: (context, state) =>
          AppSnackbar.show(context, message: l10n.timetableEntryDeleted, kind: AppSnackbarKind.success),
      builder: (context, state) => switch (state) {
        ListLoading<TimetableEntry>() => SkeletonCards(semanticLabel: l10n.loading, heights: const [72, 72, 72]),
        ListFailed<TimetableEntry>(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('timetable.forbidden'),
          title: timetableErrorText(l10n, failure),
        ),
        ListFailed<TimetableEntry>(:final failure) => StatePanel.error(
          key: const Key('timetable.failed'),
          title: timetableErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<TimetableBloc>().add(const ListRequested()),
        ),
        ListLoaded<TimetableEntry>(:final items) when items.isEmpty => StatePanel.empty(
          title: l10n.timetableEmptyTitle,
          message: l10n.timetableEmptyMessage,
          actionLabel: _editable ? l10n.timetableEntryAdd : null,
          onAction: _editable ? () => _openForm(context) : null,
        ),
        ListLoaded<TimetableEntry>(:final items) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            0,
            AppSpacing.screenMargin,
            AppSpacing.screenMargin,
          ),
          children: [
            if (state.actionFailure case final failure?) ...[
              InlineMessage.error(timetableEntryErrorText(l10n, failure), key: const Key('timetable.actionFailed')),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_editable) ...[
              AppButton(
                key: const Key('timetable.add'),
                label: l10n.timetableEntryAdd,
                icon: Icons.add,
                variant: AppButtonVariant.secondary,
                onPressed: () => _openForm(context),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final day in days) ...[
              _dayCard(context, l10n, locale, day, [
                for (final entry in items)
                  if (entry.dayOfWeek == day) entry,
              ], state),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      },
    );
  }

  Widget _dayCard(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    int day,
    List<TimetableEntry> entries,
    ListLoaded<TimetableEntry> state,
  ) => TimetableDayCard(
    key: ValueKey('timetable.day.$day'),
    title: dayName(locale, day),
    summary: l10n.timetableDayCount(entries.where((entry) => !entry.isBreak).length),
    initiallyOpen: today.weekday == day,
    child: entries.isEmpty
        ? Text(l10n.timetableDayEmpty, style: Theme.of(context).textTheme.bodyMedium)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries) ...[
                _EntryTile(
                  entry: entry,
                  showSection: week is OwnWeek,
                  busy: state.busyId == entry.id,
                  // A change to any entry is on its way, so no tile starts another.
                  locked: state.busyId != null,
                  onEdit: _editable ? () => _openForm(context, entry: entry) : null,
                  onDelete: _editable ? () => _confirmDelete(context, entry) : null,
                ),
                if (entry != entries.last) const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
  );
}

class _EntryTile extends StatelessWidget {
  const new({
    required this.entry,
    required this.showSection,
    required this.busy,
    required this.locked,
    this.onEdit,
    this.onDelete,
  });

  final TimetableEntry entry;

  /// A teacher's own week says which section each lesson is in; a section's week says who teaches it.
  final bool showSection;

  /// A change to this entry is on its way.
  final bool busy;
  final bool locked;

  /// Both are set when the person builds the week, and neither otherwise.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final slot = entry.slot;
    final when = [l10n.timeSlotName(slot.periodNo), l10n.timeSlotTimes(slot.startTime, slot.endTime)].join(' · ');
    final who = showSection ? entry.classSection : entry.teacher?.name;
    return AppCard(
      key: ValueKey('timetable.entry.${entry.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                entry.isBreak ? (slot.label ?? l10n.timetableBreak) : entry.subject?.name ?? '',
                style: text.titleSmall,
              ),
              if (entry.isBreak) StatusChip(label: l10n.timetableBreak),
            ],
          ),
          Text(when, style: text.bodySmall),
          if (who != null && who.isNotEmpty) Text(who, style: text.bodyMedium),
          if (onEdit != null && onDelete != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppButton(
                  key: ValueKey('timetable.edit.${entry.id}'),
                  label: l10n.timetableEntryEdit,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.medium,
                  onPressed: locked ? null : onEdit,
                ),
                AppButton(
                  key: ValueKey('timetable.delete.${entry.id}'),
                  label: l10n.timetableEntryDelete,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.medium,
                  loading: busy,
                  onPressed: locked ? null : onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
