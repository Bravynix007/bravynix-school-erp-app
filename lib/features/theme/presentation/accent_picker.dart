import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/features/theme/presentation/bloc/accent_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The theme colour row of Profile: the seven accents as swatches, the chosen one with a check and a ring
/// (PRD 6.3). Only the accent changes; status and attendance colours never follow it.
class AccentPicker extends StatelessWidget {
  const new({super.key});

  static const _swatch = 40.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.themeColour, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          BlocBuilder<AccentBloc, AccentState>(
            builder: (context, state) => Wrap(
              children: [
                for (final accent in AppAccent.values)
                  _Swatch(
                    key: Key('accent.${accent.name}'),
                    accent: accent,
                    selected: accent == state.accent,
                    onTap: () => context.read<AccentBloc>().add(AccentChosen(accent)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const new({required this.accent, required this.selected, required this.onTap, super.key});

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: accent.label,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: AppSpacing.minTouchTarget,
        child: Center(
          child: RingInkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: AccentPicker._swatch,
              height: AccentPicker._swatch,
              decoration: BoxDecoration(
                color: accent.primary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: selected ? Border.all(color: AppColors.ink, width: 2) : null,
              ),
              child: selected ? Icon(Icons.check, color: accent.onPrimary, size: 20) : null,
            ),
          ),
        ),
      ),
    );
  }
}
