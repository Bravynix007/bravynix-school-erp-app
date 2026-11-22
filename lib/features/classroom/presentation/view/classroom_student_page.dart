import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievements_repository.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/bloc/achievements_bloc.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/view/stars_section.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/student_attendance_tile.dart';
import 'package:bravynix_school_erp/features/auth/presentation/session/session_bloc.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/bloc/classroom_student_bloc.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/view/classroom_error_text.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/personal_rows.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_frame.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// My students → one student (STU-03, ACH-01 to ACH-03): who they are and where they sit, and their stars, which the
/// teacher gives and takes back (their own only).
class ClassroomStudentPage extends StatelessWidget {
  const new({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ClassroomStudentBloc(
      getIt<ClassroomRepository>(),
      SectionOptionsSource(
        years: getIt<AcademicYearsRepository>(),
        classes: getIt<ClassesRepository>(),
        sections: getIt<SectionsRepository>(),
      ),
      id,
    )..add(const ClassroomStudentRequested()),
    child: const ClassroomStudentView(),
  );
}

class ClassroomStudentView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StudentFrame(
      title: l10n.studentProfileTitle,
      child: BlocBuilder<ClassroomStudentBloc, ClassroomStudentState>(
        builder: (context, state) => switch (state) {
          ClassroomStudentLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 112]),
          ClassroomStudentFailed(:final failure) when failure.code == 'NOT_ASSIGNED' || failure.code == 'FORBIDDEN' =>
            StatePanel.forbidden(
              key: const Key('classroomStudent.forbidden'),
              title: classroomErrorText(l10n, failure),
            ),
          ClassroomStudentFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
            key: const Key('classroomStudent.notFound'),
            title: classroomErrorText(l10n, failure),
          ),
          ClassroomStudentFailed(:final failure) => StatePanel.error(
            key: const Key('classroomStudent.failed'),
            title: classroomErrorText(l10n, failure),
            actionLabel: l10n.retry,
            onAction: () => context.read<ClassroomStudentBloc>().add(const ClassroomStudentRequested()),
          ),
          ClassroomStudentLoaded(:final entry) => _Details(entry: entry),
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.entry});

  final ClassroomEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final student = entry.student;
    final where = [?entry.placeName, l10n.studentsRoll(student.placement.rollNumber)].join(' · ');
    // A teacher takes back the stars they gave; the API refuses the rest (ACH-03).
    final personId = switch (context.read<SessionBloc>().state) {
      SessionAuthenticated(:final session) => session.person.id,
      _ => null,
    };
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(student.fullName, style: text.headlineSmall),
              ),
              const SizedBox(height: AppSpacing.xs),
              KeyValueRow(label: l10n.studentFormPlacement, value: where),
              PersonalRows(
                gender: student.gender,
                dateOfBirth: student.dateOfBirth,
                bloodGroup: student.bloodGroup,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        StudentAttendanceTile(studentId: student.id, name: student.fullName),
        const SizedBox(height: AppSpacing.md),
        BlocProvider(
          create: (_) =>
              AchievementsBloc(getIt<AchievementsRepository>(), student.id)..add(const AchievementsStarted()),
          child: StarsSection(canRemove: (achievement) => achievement.createdBy == personId),
        ),
      ],
    );
  }
}
