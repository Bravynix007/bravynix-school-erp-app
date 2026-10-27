import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/cubit/society_blocks_cubit.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What is blocked in the Owner's Society and why (SOC-02; API design 10.4e). Shows nothing while
/// nothing is blocked, so an Owner of a Society in good standing sees no new section.
class SocietyBlocksSection extends StatelessWidget {
  const new({required this.societyName, super.key});

  final String societyName;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = SocietyBlocksCubit(getIt<BlocksRepository>());
      unawaited(cubit.load());
      return cubit;
    },
    child: SocietyBlocksView(societyName: societyName),
  );
}

class SocietyBlocksView extends StatelessWidget {
  const new({required this.societyName, super.key});

  final String societyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SocietyBlocksCubit, SocietyBlocksState>(
      builder: (context, state) => switch (state) {
        // A short wait for a section that is usually empty: nothing to show yet.
        SocietyBlocksLoading() => const SizedBox.shrink(),
        SocietyBlocksFailed(:final failure) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InlineMessage.warning(roleErrorText(l10n, failure)),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              key: const Key('blocks.retry'),
              label: l10n.retry,
              variant: AppButtonVariant.text,
              size: AppButtonSize.small,
              onPressed: context.read<SocietyBlocksCubit>().load,
            ),
          ],
        ),
        SocietyBlocksLoaded(:final blocks) when blocks.isEmpty => const SizedBox.shrink(),
        SocietyBlocksLoaded(:final blocks) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.blocksTitle(societyName)),
            const SizedBox(height: AppSpacing.xs),
            for (final block in blocks) ...[_BlockCard(block: block), const SizedBox(height: AppSpacing.xs)],
          ],
        ),
      },
    );
  }
}

class _BlockCard extends StatelessWidget {
  const new({required this.block});

  final SectionBlock block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final institution = block.institutionName ?? '';
    final title = switch (block.section) {
      BlockSection.owners => l10n.blockTitleOwners,
      BlockSection.staff => l10n.blockTitleStaff(institution),
      BlockSection.students => l10n.blockTitleStudents(institution),
    };
    return AppCard(
      key: ValueKey('block.${block.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.blockReason(block.reason), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.blockedOn(Formatters.instant(block.blockedAt)),
            style: text.bodySmall?.copyWith(color: AppColors.inkSecondary),
          ),
        ],
      ),
    );
  }
}
