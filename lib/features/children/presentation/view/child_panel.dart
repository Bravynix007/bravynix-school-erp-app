import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/switcher_card.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/children/presentation/bloc/active_child_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The top of a parent's home: which child the screens are about, with a switcher when there are several, and a notice
/// when that child's data is closed while a sibling's is open. When every child is blocked the home says so once for all
/// of them (`BlockedAccessNotice`). Shows nothing for anyone who is not a parent.
class ChildPanel extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ActiveChildBloc, ActiveChildState>(
      builder: (context, state) {
        if (state is! ActiveChildReady) return const SizedBox.shrink();
        final bloc = context.read<ActiveChildBloc>();
        String detail(LinkedChild child) => child.classSection.isEmpty
            ? child.institutionName
            : l10n.childDetail(child.classSection, child.institutionName);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitcherCard<LinkedChild>(
              key: const Key('child.switcher'),
              options: state.children,
              selected: state.selected,
              idOf: (child) => child.studentId,
              titleOf: (child) => child.fullName,
              subtitleOf: detail,
              detail: state.selected.classSection.isEmpty ? l10n.childNoClass : detail(state.selected),
              hint: l10n.childSwitchHint,
              sheetTitle: l10n.childSwitchTitle,
              optionKeyPrefix: 'child.option',
              onSelected: (child) => bloc.add(ActiveChildChosen(child.studentId)),
            ),
            if (state.selected.isBlocked && state.children.any((child) => !child.isBlocked)) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(l10n.blockedChildNotice(state.selected.firstName)),
            ],
          ],
        );
      },
    );
  }
}
