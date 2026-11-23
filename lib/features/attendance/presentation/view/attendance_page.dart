import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/attendance_status_selector.dart';
import 'package:bravynix_school_erp/core/widgets/day_picker.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_roster.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_error_text.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/void_register_sheet.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "Attendance": an Owner, an Admin or a teacher takes a section's register for a day, under the Institution switcher
/// (API design 10.10 to 10.12a). Everyone is Present until marked otherwise; a register already taken opens for
/// correction, and an Owner or an Admin can void it.
class AttendancePage extends StatelessWidget {
  const new({this.focus, this.clock = DateTime.now, super.key});

  /// The register to open on, when another screen sent the person here to correct one.
  final AttendanceFocus? focus;

  /// What "today" is: the school day it falls on in IST, as everywhere in the app.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = context.read<SessionBloc>().state;
    final session = active is SessionAuthenticated ? active.session.activeContext : null;
    final admin = session?.role == RoleCode.societyOwner || session?.role == RoleCode.institutionAdmin;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.attendanceTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              // The scope builds its child again for each Institution, so the classes are those of the one chosen.
              builder: (context, institution) => BlocProvider(
                create: (_) =>
                    AttendanceBloc(getIt<AttendanceRepository>(), institution.id, clock: clock, focus: focus)
                      ..add(const AttendanceStarted()),
                child: AttendanceView(
                  // An Owner or an Admin marks at every Institution they reach; a teacher at their own only (API design
                  // 10.11): at another Institution of theirs they read the register.
                  mayMark: admin || institution.id == session?.homeInstitutionId,
                  mayVoid: admin,
                  today: Formatters.schoolDay(clock()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceView extends StatelessWidget {
  const new({required this.mayMark, required this.mayVoid, required this.today, super.key});

  /// Whether the person may take and correct registers at this Institution.
  final bool mayMark;

  /// Whether the person may void a register (an Owner or an Admin).
  final bool mayVoid;

  /// The school day (IST), `YYYY-MM-DD`: the last day that can be marked.
  final String today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listenWhen: (previous, current) =>
          current is AttendanceReady &&
          current.outcome != null &&
          (previous is! AttendanceReady || previous.outcome != current.outcome),
      listener: (context, state) {
        final outcome = (state as AttendanceReady).outcome!;
        AppSnackbar.show(
          context,
          message: switch (outcome.kind) {
            AttendanceOutcomeKind.submitted => l10n.attendanceSubmitted(outcome.count),
            AttendanceOutcomeKind.corrected => l10n.attendanceCorrected,
            AttendanceOutcomeKind.voided => l10n.attendanceVoided,
          },
          kind: AppSnackbarKind.success,
        );
      },
      builder: (context, state) => switch (state) {
        AttendanceLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [64, 64, 120]),
        AttendanceFailed(:final failure) when failure.refused => StatePanel.forbidden(
          key: const Key('attendance.forbidden'),
          title: attendanceErrorText(l10n, failure),
        ),
        AttendanceFailed(:final failure) => StatePanel.error(
          key: const Key('attendance.failed'),
          title: attendanceErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<AttendanceBloc>().add(const AttendanceStarted()),
        ),
        AttendanceReady(:final classes) when classes.isEmpty => StatePanel.empty(
          key: const Key('attendance.noSections'),
          title: l10n.attendanceNoSectionsTitle,
          message: l10n.attendanceNoSectionsMessage,
        ),
        AttendanceReady() => _Screen(state: state, mayMark: mayMark, mayVoid: mayVoid, today: today),
      },
    );
  }
}

class _Screen extends StatelessWidget {
  const new({required this.state, required this.mayMark, required this.mayVoid, required this.today});

  final AttendanceReady state;
  final bool mayMark;
  final bool mayVoid;
  final String today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AttendanceBloc>();
    final board = state.board;
    final end = Formatters.parseDay(today)!;
    final labels = _labels(l10n);
    // The roll can be changed when a register may be taken for the day, or one is taken and the person may correct it.
    final loaded = board is BoardLoaded ? board : null;
    final roll = loaded?.roster;
    final editable = roll != null && mayMark && (roll.canMark || roll.taken != null);
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                sliver: SliverList.list(
                  children: [
                    MasterDropdown(
                      key: const Key('attendance.class'),
                      label: l10n.studentClass,
                      entries: [for (final choice in state.classes) MasterEntry(id: choice.id, name: choice.name)],
                      value: state.classId,
                      onChanged: (id) => bloc.add(AttendanceClassChosen(id)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    MasterDropdown(
                      key: const Key('attendance.section'),
                      label: l10n.studentSection,
                      entries: [
                        for (final choice in state.sectionsInClass) MasterEntry(id: choice.id, name: choice.name),
                      ],
                      value: state.sectionId,
                      onChanged: state.classId == null ? null : (id) => bloc.add(AttendanceSectionChosen(id)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DayField(
                      key: const Key('attendance.day'),
                      label: l10n.attendanceDate,
                      day: state.day,
                      // A register is taken for the days of the current year, so a year back is as far as anyone looks.
                      firstDay: DateTime(end.year - 1, end.month, end.day),
                      lastDay: end,
                      onChanged: (day) => bloc.add(AttendanceDayChosen(day)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._body(context, board, labels, editable: editable),
                  ],
                ),
              ),
              if (loaded != null && _showsRoll(loaded.roster))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenMargin,
                    0,
                    AppSpacing.screenMargin,
                    AppSpacing.screenMargin,
                  ),
                  sliver: SliverList.separated(
                    itemCount: loaded.roster.students.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) => _StudentCard(
                      student: loaded.roster.students[index],
                      mark: loaded.markOf(loaded.roster.students[index]),
                      labels: labels,
                      editable: editable && !loaded.saving,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (loaded != null && editable && loaded.roster.taken == null)
          StickyBottomActions(
            primaryLabel: l10n.attendanceSubmit,
            primaryLoading: loaded.saving,
            onPrimary: loaded.saving || loaded.roster.students.isEmpty
                ? null
                : () => bloc.add(const AttendanceSubmitted()),
            notice: _notice(l10n, loaded),
          ),
        if (loaded != null && editable && loaded.roster.taken != null)
          StickyBottomActions(
            primaryLabel: l10n.attendanceSaveCorrections,
            primaryLoading: loaded.saving,
            onPrimary: loaded.saving || loaded.changes.isEmpty ? null : () => bloc.add(const AttendanceCorrected()),
            secondaryLabel: mayVoid ? l10n.attendanceVoid : null,
            onSecondary: mayVoid && !loaded.saving ? () => _void(context) : null,
            notice: _notice(l10n, loaded),
          ),
      ],
    );
  }

  /// A roll with no register that cannot be marked shows only why: everyone would read as Present.
  bool _showsRoll(AttendanceRoster roll) => roll.students.isNotEmpty && (roll.taken != null || roll.canMark);

  Widget? _notice(AppLocalizations l10n, BoardLoaded board) {
    final failure = board.failure;
    return failure == null
        ? null
        : InlineMessage.error(attendanceActionErrorText(l10n, failure), key: const Key('attendance.error'));
  }

  Future<void> _void(BuildContext context) async {
    final bloc = context.read<AttendanceBloc>();
    final reason = await showVoidRegisterSheet(context);
    if (reason != null) bloc.add(AttendanceVoided(reason));
  }

  List<Widget> _body(
    BuildContext context,
    AttendanceBoard board,
    Map<AttendanceMark, AttendanceMarkLabel> labels, {
    required bool editable,
  }) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    switch (board) {
      case BoardEmpty():
        return [
          StatePanel.empty(
            key: const Key('attendance.pick'),
            title: l10n.attendancePickTitle,
            message: l10n.attendancePickMessage,
          ),
        ];
      case BoardLoading():
        return [
          SkeletonCards(semanticLabel: l10n.loading, heights: const [80, 80, 80]),
        ];
      case BoardFailed(:final failure):
        return [
          StatePanel.error(
            key: const Key('attendance.rollFailed'),
            title: attendanceErrorText(l10n, failure),
            actionLabel: l10n.retry,
            onAction: () => context.read<AttendanceBloc>().add(const AttendanceRollRetried()),
          ),
        ];
      case BoardLoaded(:final roster, :final failure):
        return [
          // Why the roll was read again, when it was out of date: said over the roll, not only above the buttons.
          if (failure != null && !editable) ...[
            InlineMessage.error(attendanceActionErrorText(l10n, failure), key: const Key('attendance.error')),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (roster.taken case final taken?) ...[
            InlineMessage.info(
              l10n.attendanceTakenBy(taken.takenBy, Formatters.instant(taken.takenAt)),
              key: const Key('attendance.taken'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (roster.taken == null && !roster.canMark) ...[
            InlineMessage.info(_closedText(l10n, roster), key: const Key('attendance.closed')),
          ] else if (roster.taken != null && !mayMark) ...[
            InlineMessage.info(l10n.attendanceViewOnly, key: const Key('attendance.viewOnly')),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (roster.students.isEmpty && (roster.canMark || roster.taken != null))
            StatePanel.empty(
              key: const Key('attendance.noStudents'),
              title: l10n.attendanceNoStudentsTitle,
              message: l10n.attendanceNoStudentsMessage,
            )
          else if (roster.canMark || roster.taken != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.attendancePresentCount(board.present, roster.students.length),
                key: const Key('attendance.counter'),
                style: text.titleMedium,
              ),
            ),
        ];
    }
  }

  /// Why a day with no register cannot be marked, in the order the API refuses it.
  String _closedText(AppLocalizations l10n, AttendanceRoster roster) {
    if (roster.isHoliday) {
      final title = roster.holidayTitle;
      return title == null || title.isEmpty ? l10n.attendanceHolidayUntitled : l10n.attendanceHoliday(title);
    }
    return mayMark ? l10n.attendanceClosed : l10n.attendanceViewOnly;
  }

  static Map<AttendanceMark, AttendanceMarkLabel> _labels(AppLocalizations l10n) => {
    AttendanceMark.present: AttendanceMarkLabel(
      short: l10n.attendanceMarkPresentShort,
      full: l10n.attendanceMarkPresent,
    ),
    AttendanceMark.absent: AttendanceMarkLabel(short: l10n.attendanceMarkAbsentShort, full: l10n.attendanceMarkAbsent),
    AttendanceMark.late: AttendanceMarkLabel(short: l10n.attendanceMarkLateShort, full: l10n.attendanceMarkLate),
    AttendanceMark.halfDay: AttendanceMarkLabel(
      short: l10n.attendanceMarkHalfDayShort,
      full: l10n.attendanceMarkHalfDay,
    ),
    AttendanceMark.leave: AttendanceMarkLabel(short: l10n.attendanceMarkLeaveShort, full: l10n.attendanceMarkLeave),
  };
}

/// One student: roll number and name, and the mark as five buttons, or as a chip when the register cannot be changed.
class _StudentCard extends StatelessWidget {
  const new({required this.student, required this.mark, required this.labels, required this.editable});

  final RosterStudent student;
  final AttendanceMark mark;
  final Map<AttendanceMark, AttendanceMarkLabel> labels;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: ValueKey('attendance.student.${student.enrolmentId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.attendanceStudentMark(student.fullName, student.rollNumber), style: text.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (editable)
            AttendanceStatusSelector(
              labels: labels,
              selected: mark,
              onChanged: (chosen) => context.read<AttendanceBloc>().add(AttendanceMarked(student.enrolmentId, chosen)),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusChip(label: labels[mark]!.full, tone: _tone(mark)),
            ),
        ],
      ),
    );
  }

  static StatusTone _tone(AttendanceMark mark) => switch (mark) {
    AttendanceMark.present => StatusTone.success,
    AttendanceMark.absent => StatusTone.error,
    AttendanceMark.late || AttendanceMark.halfDay => StatusTone.warning,
    AttendanceMark.leave => StatusTone.info,
  };
}
