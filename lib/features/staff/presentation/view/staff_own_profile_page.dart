import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_segmented_control.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/documents/domain/documents_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/file_opening.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_documents_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_documents_view.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_profile_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Profile → My details: a teacher's own staff record (STF-03) and the documents kept with it (STF-14), to read and to
/// open. A teacher changes nothing here: the school's Admin edits the record and adds the documents.
class StaffOwnProfilePage extends StatelessWidget {
  const new({required this.staffMemberId, super.key});

  final String staffMemberId;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) =>
            StaffProfileBloc(getIt<StaffRepository>(), getIt<MastersRepository>(), staffMemberId)
              ..add(const StaffProfileRequested()),
      ),
      BlocProvider(
        create: (_) => StaffDocumentsBloc(
          getIt<DocumentsRepository>(),
          getIt<FilesRepository>(),
          getIt<FileOpening>(),
          staffMemberId: staffMemberId,
        ),
      ),
    ],
    child: const StaffOwnProfileView(),
  );
}

class StaffOwnProfileView extends StatelessWidget {
  const new({super.key});

  /// The parts a teacher reads: the access and settings tabs are the Admin's.
  static const List<StaffProfileTab> _tabs = [StaffProfileTab.personal, StaffProfileTab.documents];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.staffOwnTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocBuilder<StaffProfileBloc, StaffProfileState>(
              builder: (context, state) => switch (state) {
                StaffProfileLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 112]),
                StaffProfileFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('staffOwn.forbidden'),
                  title: staffErrorText(l10n, failure),
                ),
                StaffProfileFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                  key: const Key('staffOwn.notFound'),
                  title: staffErrorText(l10n, failure),
                ),
                StaffProfileFailed(:final failure) => StatePanel.error(
                  key: const Key('staffOwn.failed'),
                  title: staffErrorText(l10n, failure),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<StaffProfileBloc>().add(const StaffProfileRequested()),
                ),
                StaffProfileLoaded(:final profile, :final tab) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenMargin,
                        AppSpacing.screenMargin,
                        AppSpacing.screenMargin,
                        0,
                      ),
                      child: AppSegmentedControl<StaffProfileTab>(
                        options: _tabs,
                        scrollable: true,
                        labelOf: (tab) => staffProfileTabLabel(l10n, tab),
                        selected: tab,
                        onChanged: (tab) => context.read<StaffProfileBloc>().add(StaffProfileTabChosen(tab)),
                      ),
                    ),
                    Expanded(
                      child: switch (tab) {
                        StaffProfileTab.documents => const StaffDocumentsView(),
                        // The Admin's tabs are not offered here, so only the personal one is ever chosen.
                        StaffProfileTab.personal ||
                        StaffProfileTab.access ||
                        StaffProfileTab.settings => StaffDetails(profile: profile, own: true),
                      },
                    ),
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
