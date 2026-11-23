import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/app_tag.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/bloc/achievements_bloc.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/view/achievement_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The words for a kind of star.
String starTierName(AppLocalizations l10n, StarTier tier) => switch (tier) {
  StarTier.silver => l10n.starSilver,
  StarTier.gold => l10n.starGold,
  StarTier.platinum => l10n.starPlatinum,
};

/// The stars of a student (ACH-01), with a way to give one (ACH-02) and to take one back (ACH-03). The
/// [AchievementsBloc] comes from the context. [canRemove] says which stars the caller may take back: an Owner or Admin
/// any, a teacher the ones they gave.
class StarsSection extends StatefulWidget {
  const new({required this.canRemove, super.key});

  final bool Function(Achievement achievement) canRemove;

  @override
  State<StarsSection> createState() => _StarsSectionState();
}

class _StarsSectionState extends State<StarsSection> {
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    Achievement achievement,
  ) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<AchievementsBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.achievementsRemoveTitle,
      message: l10n.achievementsRemoveMessage,
      confirmLabel: l10n.achievementsRemove,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(AchievementsRemoved(achievement.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.achievementsTitle),
        const SizedBox(height: AppSpacing.xs),
        BlocConsumer<AchievementsBloc, AchievementsState>(
          // A star that was given empties the form.
          listenWhen: (previous, current) =>
              current is AchievementsReady && current.description.isEmpty && _description.text.isNotEmpty,
          listener: (context, state) => _description.clear(),
          builder: (context, state) => switch (state) {
            AchievementsLoading() => Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const ExcludeSemantics(
                child: SkeletonBox(height: 120, radius: AppRadius.card),
              ),
            ),
            AchievementsFailed(:final failure) => InlineMessage.error(
              achievementErrorText(l10n, failure),
              key: const Key('stars.failed'),
              // A student outside the teacher's sections does not come back by asking again.
              actionLabel: failure.refused ? null : l10n.retry,
              onAction: () => context.read<AchievementsBloc>().add(
                const AchievementsStarted(),
              ),
            ),
            AchievementsReady() => _Ready(
              state: state,
              description: _description,
              onRemove: _confirmRemove,
              canRemove: widget.canRemove,
            ),
          },
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const new({
    required this.state,
    required this.description,
    required this.onRemove,
    required this.canRemove,
  });

  final AchievementsReady state;
  final TextEditingController description;
  final Future<void> Function(BuildContext context, Achievement achievement) onRemove;
  final bool Function(Achievement achievement) canRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bloc = context.read<AchievementsBloc>();
    final stars = state.stars;
    final failure = state.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.achievementsTotal(stars.total),
                  key: const Key('stars.total'),
                  style: text.titleMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final tier in StarTier.values)
                    AppTag(
                      '${starTierName(l10n, tier)} · ${stars.countOf(tier)}',
                    ),
                ],
              ),
              for (final achievement in stars.achievements) ...[
                const Divider(height: AppSpacing.md * 2),
                Column(
                  key: ValueKey('stars.item.${achievement.id}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        ?achievement.tier == null ? null : starTierName(l10n, achievement.tier!),
                        Formatters.schoolDate(
                          Formatters.schoolDay(achievement.createdAt),
                        ),
                      ].join(' · '),
                      style: text.bodySmall,
                    ),
                    Text(achievement.description, style: text.bodyMedium),
                    if (canRemove(achievement))
                      // Under the words, so that a large text size leaves them the whole width.
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: AppButton(
                          key: ValueKey('stars.remove.${achievement.id}'),
                          label: l10n.achievementsRemove,
                          variant: AppButtonVariant.text,
                          size: AppButtonSize.small,
                          loading: state.removing == achievement.id,
                          onPressed: state.busy ? null : () => onRemove(context, achievement),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineMessage.error(
            achievementErrorText(l10n, failure),
            key: const Key('stars.error'),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionHeader(title: l10n.achievementsGiveTitle),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSegmentedControl<StarTier>(
                options: StarTier.values,
                scrollable: true,
                labelOf: (tier) => starTierName(l10n, tier),
                selected: state.tier,
                onChanged: (tier) => bloc.add(AchievementsTierChosen(tier)),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                key: const Key('stars.description'),
                controller: description,
                label: l10n.achievementsDescription,
                maxLength: 500,
                maxLines: 3,
                enabled: !state.busy,
                onChanged: (value) => bloc.add(AchievementsDescriptionChanged(value)),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const Key('stars.give'),
                label: l10n.achievementsGive,
                loading: state.giving,
                onPressed: state.canGive ? () => bloc.add(const AchievementsGiven()) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
