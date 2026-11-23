import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/key_value_row.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_calendar.dart';
import 'package:bravynix_school_erp/features/attendance/domain/attendance_repository.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/bloc/day_detail_bloc.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_calendar_style.dart';
import 'package:bravynix_school_erp/features/attendance/presentation/view/attendance_error_text.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A day of a student (ATT-08): how it was marked, and by whom. Answers the register to open when the person asks to
/// correct it (only offered with [canCorrect]), or null when the sheet is closed.
Future<SectionDay?> showDayDetailSheet(
  BuildContext context, {
  required String studentId,
  required String day,
  required bool canCorrect,
}) => showAppBottomSheet<SectionDay>(
  context: context,
  // The title is the screen's name: a date in it would break across lines at a large text size.
  title: AppLocalizations.of(context).attendanceDayTitle,
  builder: (_) => BlocProvider(
    create: (_) => DayDetailBloc(getIt<AttendanceRepository>(), studentId, day)..add(const DayDetailRequested()),
    child: _DayDetail(canCorrect: canCorrect),
  ),
);

class _DayDetail extends StatelessWidget {
  const new({required this.canCorrect});

  final bool canCorrect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xs,
        AppSpacing.screenMargin,
        AppSpacing.md,
      ),
      child: BlocBuilder<DayDetailBloc, DayDetailState>(
        builder: (context, state) => switch (state) {
          // A box and not SkeletonCards or a StatePanel, which fill a screen: this sits in a sheet as tall as it needs.
          DayDetailLoading() => Semantics(
            label: l10n.loading,
            liveRegion: true,
            child: const ExcludeSemantics(child: SkeletonBox(height: 96, radius: AppRadius.card)),
          ),
          DayDetailFailed(:final failure) => InlineMessage.error(
            attendanceCalendarErrorText(l10n, failure),
            key: const Key('dayDetail.failed'),
            actionLabel: l10n.retry,
            onAction: () => context.read<DayDetailBloc>().add(const DayDetailRequested()),
          ),
          DayDetailLoaded(:final detail) => _Loaded(detail: detail, canCorrect: canCorrect),
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const new({required this.detail, required this.canCorrect});

  final DayDetail detail;
  final bool canCorrect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final section = detail.section;
    final where = [?section?.className, ?section?.name].join(' · ');
    final status = detail.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            StatusChip(
              key: const Key('dayDetail.status'),
              label: status == DayStatus.holiday && (detail.holidayTitle?.isNotEmpty ?? false)
                  ? l10n.attendanceHoliday(detail.holidayTitle!)
                  : status.label(l10n),
              tone: status.tone,
            ),
            if (detail.isWeekend) StatusChip(label: l10n.attendanceCalendarWeeklyOff),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        KeyValueRow(label: l10n.attendanceDate, value: Formatters.schoolDate(detail.day)),
        if (where.isNotEmpty) KeyValueRow(label: l10n.attendanceDaySection, value: where),
        if (detail.markedBy case final name?) ...[
          KeyValueRow(label: l10n.attendanceDayMarkedBy, value: name),
          if (detail.markedAt case final at?)
            KeyValueRow(label: l10n.attendanceDayMarkedAt, value: Formatters.instant(at)),
          if (detail.lastCorrectedAt case final at?)
            KeyValueRow(label: l10n.attendanceDayCorrectedAt, value: Formatters.instant(at)),
        ] else if (status != DayStatus.holiday && status != DayStatus.notEnrolled)
          Text(l10n.attendanceDayNoRegister, style: Theme.of(context).textTheme.bodyMedium),
        if (canCorrect && detail.markedBy != null && section != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const Key('dayDetail.correct'),
            label: l10n.attendanceDayCorrect,
            onPressed: () => Navigator.of(context).pop(SectionDay(sectionId: section.id, day: detail.day)),
          ),
        ],
      ],
    );
  }
}
