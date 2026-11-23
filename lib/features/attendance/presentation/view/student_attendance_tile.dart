import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/widgets/menu_list_tile.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The row on a student's profile that opens their attendance calendar, for staff.
class StudentAttendanceTile extends StatelessWidget {
  const new({required this.studentId, required this.name, super.key});

  final String studentId;
  final String name;

  @override
  Widget build(BuildContext context) => MenuListTile(
    key: const Key('student.attendance'),
    icon: Icons.event_available_outlined,
    title: AppLocalizations.of(context).attendanceTitle,
    onTap: () => context.push(
      AppRoutes.studentAttendance,
      extra: StudentAttendanceArgs(studentId: studentId, name: name),
    ),
  );
}
