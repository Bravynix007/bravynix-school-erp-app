import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_view.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/features/children/presentation/view/child_panel.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A parent's "Attendance": the month of the child shown at the top (ATT-07, ATT-08). Read only.
class AttendanceCalendarPage extends StatelessWidget {
  const new({this.clock = DateTime.now, super.key});

  /// What "today" is, for the month that opens first.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.attendanceTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
            child: ChildPanel(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: BlocBuilder<ActiveChildBloc, ActiveChildState>(
              builder: (context, child) => child is ActiveChildReady
                  // A new key per child starts the month again for that child, so the last child's never shows.
                  ? _CalendarOf(
                      key: ValueKey(child.selected.studentId),
                      studentId: child.selected.studentId,
                      clock: clock,
                    )
                  : StatePanel.empty(
                      key: const Key('attendanceCalendar.noChild'),
                      title: l10n.attendanceCalendarNoChildTitle,
                      message: l10n.attendanceCalendarNoChildMessage,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Which student the calendar screen opens for, and what to call them.
class StudentAttendanceArgs {
  const new({required this.studentId, required this.name});

  final String studentId;
  final String name;
}

/// A student's "Attendance" for an Owner, an Admin or a teacher, from the student's profile: the month, and Correct on a
/// day that was marked, which opens that register.
class StudentAttendancePage extends StatelessWidget {
  const new({required this.args, this.clock = DateTime.now, super.key});

  final StudentAttendanceArgs args;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.attendanceTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.xs,
              AppSpacing.screenMargin,
              AppSpacing.xs,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(args.name, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          Expanded(
            child: _CalendarOf(
              studentId: args.studentId,
              clock: clock,
              onCorrect: (focus) => context.push(AppRoutes.attendance, extra: focus),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarOf extends StatelessWidget {
  const new({required this.studentId, required this.clock, this.onCorrect, super.key});

  final String studentId;
  final DateTime Function() clock;
  final ValueChanged<SectionDay>? onCorrect;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        AttendanceCalendarBloc(getIt<AttendanceRepository>(), studentId, clock: clock)
          ..add(const AttendanceCalendarStarted()),
    child: AttendanceCalendarView(studentId: studentId, onCorrect: onCorrect),
  );
}
