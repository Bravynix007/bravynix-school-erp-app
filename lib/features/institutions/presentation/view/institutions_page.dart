import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institutions_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/board_name.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Institutions: the Institutions the signed-in Owner or Institution Admin can work in (INS-01).
class InstitutionsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => InstitutionsBloc(getIt<InstitutionsRepository>())..add(const InstitutionsRequested()),
    child: const InstitutionsView(),
  );
}

class InstitutionsView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.institutionsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocBuilder<InstitutionsBloc, InstitutionsState>(
              builder: (context, state) => switch (state) {
                InstitutionsLoading() => const _Skeleton(),
                InstitutionsFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('institutions.forbidden'),
                  title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
                ),
                InstitutionsFailed(:final failure) => StatePanel.error(
                  key: const Key('institutions.failed'),
                  title: apiErrorText(l10n, failure, notFound: l10n.errorInstitutionNotFound),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<InstitutionsBloc>().add(const InstitutionsRequested()),
                ),
                InstitutionsLoaded(:final institutions) when institutions.isEmpty => StatePanel.empty(
                  title: l10n.institutionsEmptyTitle,
                  message: l10n.institutionsEmptyMessage,
                ),
                InstitutionsLoaded(:final institutions) => _Institutions(institutions: institutions),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).loading,
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 88, radius: AppRadius.card),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 88, radius: AppRadius.card),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 88, radius: AppRadius.card),
      ],
    ),
  );
}

class _Institutions extends StatelessWidget {
  const new({required this.institutions});

  final List<InstitutionSummary> institutions;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screenMargin),
    children: [
      for (final institution in institutions) ...[
        _InstitutionCard(institution: institution),
        const SizedBox(height: AppSpacing.xs),
      ],
    ],
  );
}

class _InstitutionCard extends StatelessWidget {
  const new({required this.institution});

  final InstitutionSummary institution;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final secondary = text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final detail = [
      ?institution.place,
      if (institution.board case final board?) boardName(l10n, board),
    ].join(' · ');
    return AppCard(
      key: ValueKey('institution.${institution.id}'),
      onTap: () async {
        // A deactivated Institution leaves the list, so it is read again when the detail closes with true.
        final changed = await context.push<bool>(AppRoutes.institution(institution.id));
        if (changed == true && context.mounted) context.read<InstitutionsBloc>().add(const InstitutionsRequested());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(institution.name, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(institution.code, style: AppTextStyles.code.copyWith(color: secondary?.color)),
          if (detail.isNotEmpty) Text(detail, style: secondary),
        ],
      ),
    );
  }
}
