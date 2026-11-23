import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/day_picker.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_day_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What a screen that reads a section's day shows while its [SectionDayBloc] reads the classes: a skeleton, the reason
/// they could not be read (with Try again unless the person may not), and a panel when the Institution has no section
/// to choose. Then [builder] draws the screen. The keys are `$keyPrefix.forbidden`, `.failed` and `.noSections`.
class SectionDayFrame extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.errorText,
    required this.builder,
    this.noSectionsTitle,
    this.noSectionsMessage,
    super.key,
  });

  final String keyPrefix;
  final String Function(AppLocalizations l10n, ApiFailure failure) errorText;

  /// The panel for an Institution with no section; null for a screen that chooses the day only.
  final String? noSectionsTitle;
  final String? noSectionsMessage;
  final Widget Function(BuildContext context, SectionDayReady ready) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SectionDayBloc, SectionDayState>(
      builder: (context, state) => switch (state) {
        SectionDayLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [64, 64, 120]),
        SectionDayFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: Key('$keyPrefix.forbidden'),
          title: errorText(l10n, failure),
        ),
        SectionDayFailed(:final failure) => StatePanel.error(
          key: Key('$keyPrefix.failed'),
          title: errorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<SectionDayBloc>().add(const SectionDayStarted()),
        ),
        SectionDayReady(:final classes) when noSectionsTitle != null && classes.isEmpty => StatePanel.empty(
          key: Key('$keyPrefix.noSections'),
          title: noSectionsTitle!,
          message: noSectionsMessage,
        ),
        SectionDayReady() => builder(context, state),
      },
    );
  }
}

/// Tells a screen what its [SectionDayBloc] has chosen, each time the section or the day changes, and once it has read
/// the classes.
class SectionDayListener extends StatelessWidget {
  const new({required this.onChosen, required this.child, super.key});

  final void Function(BuildContext context, SectionDayReady chosen) onChosen;
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocListener<SectionDayBloc, SectionDayState>(
    listenWhen: (previous, current) =>
        current is SectionDayReady &&
        (previous is! SectionDayReady || previous.sectionId != current.sectionId || previous.day != current.day),
    listener: (context, state) => onChosen(context, state as SectionDayReady),
    child: child,
  );
}

/// The class, section and day fields of a [SectionDayBloc], with the keys `$keyPrefix.class`, `.section` and `.day`.
/// [enabled] is false while an action on the list below is on its way: its answer belongs to the list on screen. A
/// screen that chooses the day only has no class and section.
class SectionDayFields extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.state,
    required this.dayLabel,
    this.enabled = true,
    this.chooseSection = true,
    super.key,
  });

  final String keyPrefix;
  final SectionDayReady state;
  final String dayLabel;
  final bool enabled;
  final bool chooseSection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SectionDayBloc>();
    final end = Formatters.parseDay(state.today)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chooseSection) ...[
          MasterDropdown(
            key: Key('$keyPrefix.class'),
            label: l10n.studentClass,
            entries: [for (final choice in state.classes) MasterEntry(id: choice.id, name: choice.name)],
            value: state.classId,
            onChanged: enabled ? (id) => bloc.add(SectionDayClassChosen(id)) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          MasterDropdown(
            key: Key('$keyPrefix.section'),
            label: l10n.studentSection,
            entries: [for (final choice in state.sectionsInClass) MasterEntry(id: choice.id, name: choice.name)],
            value: state.sectionId,
            onChanged: enabled && state.classId != null ? (id) => bloc.add(SectionDaySectionChosen(id)) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        DayField(
          key: Key('$keyPrefix.day'),
          label: dayLabel,
          day: state.day,
          // The registers and the diary of the current year are what anyone looks at, so a year back is as far as the
          // calendar goes.
          firstDay: DateTime(end.year - 1, end.month, end.day),
          lastDay: end,
          onChanged: enabled ? (day) => bloc.add(SectionDayDayChosen(day)) : null,
        ),
      ],
    );
  }
}
