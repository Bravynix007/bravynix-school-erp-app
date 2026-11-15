import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/access_block_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The words of an [AccessBlockCard]: what it says of the access as it is, and the question, the button and the
/// thanks of a block and of a lift, each given the name of the record.
class AccessBlockCopy {
  const new({
    required this.statusActive,
    required this.statusBlocked,
    required this.blockAction,
    required this.unblockAction,
    required this.blockTitle,
    required this.blockMessage,
    required this.unblockTitle,
    required this.unblockMessage,
    required this.blockDone,
    required this.unblockDone,
  });

  final String statusActive;
  final String statusBlocked;
  final String blockAction;
  final String unblockAction;
  final String Function(String name) blockTitle;
  final String blockMessage;
  final String Function(String name) unblockTitle;
  final String unblockMessage;
  final String Function(String name) blockDone;
  final String Function(String name) unblockDone;
}

/// The card that says whether a record's access is blocked and blocks or lifts it after a question, on the profile of a
/// staff member and of a student. It needs the [AccessBlockBloc] of [T] above it and tells the profile behind of the
/// answer through [onChanged], or, when the record is gone ([onGone]), that it must be read again. The profile keeps
/// its own screen around the card; the keys of the card start with [keyPrefix].
class AccessBlockCard<T> extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.copy,
    required this.nameOf,
    required this.errorText,
    required this.onChanged,
    required this.onGone,
    this.blockedBadge,
    super.key,
  });

  final String keyPrefix;
  final AccessBlockCopy copy;
  final String Function(T record) nameOf;

  /// The words for a refused block or lift.
  final String Function(ApiFailure failure) errorText;

  /// A block or a lift changed the record, or a refusal read it again because it was already as asked.
  final void Function(BuildContext context, T record) onChanged;

  /// The record was deactivated meanwhile (404): the profile behind reads again.
  final void Function(BuildContext context) onGone;

  /// A chip shown while the access is blocked; none when the card's words say it.
  final String? blockedBadge;

  Future<void> _confirm(BuildContext context, T record) async {
    final bloc = context.read<AccessBlockBloc<T>>();
    final blocked = bloc.isBlocked(record);
    final confirmed = await showConfirmDialog(
      context: context,
      title: blocked ? copy.unblockTitle(nameOf(record)) : copy.blockTitle(nameOf(record)),
      message: blocked ? copy.unblockMessage : copy.blockMessage,
      confirmLabel: blocked ? copy.unblockAction : copy.blockAction,
      cancelLabel: AppLocalizations.of(context).cancel,
      destructive: !blocked,
    );
    if (confirmed ?? false) bloc.add(const AccessBlockToggled());
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = context.read<AccessBlockBloc<T>>().isBlocked;
    return BlocConsumer<AccessBlockBloc<T>, AccessBlockState<T>>(
      // A block or a lift changes the record, which the profile behind keeps; so does a refusal that read it again
      // because it was already as asked. A record that is gone is told apart.
      listenWhen: (previous, current) =>
          previous.record != current.record ||
          (current is AccessBlockRefused<T> && current.failure.code == 'NOT_FOUND'),
      listener: (context, state) {
        if (state case AccessBlockRefused<T>(:final failure) when failure.code == 'NOT_FOUND') {
          onGone(context);
          return;
        }
        onChanged(context, state.record);
        if (state is AccessBlockIdle<T>) {
          final name = nameOf(state.record);
          AppSnackbar.show(
            context,
            message: isBlocked(state.record) ? copy.blockDone(name) : copy.unblockDone(name),
            kind: AppSnackbarKind.success,
          );
        }
      },
      builder: (context, state) {
        final record = state.record;
        final blocked = isBlocked(record);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (blocked && blockedBadge != null) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusChip(label: blockedBadge!, tone: StatusTone.error),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                blocked ? copy.statusBlocked : copy.statusActive,
                key: Key('$keyPrefix.status'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (state case AccessBlockRefused<T>(:final failure)) ...[
                const SizedBox(height: AppSpacing.sm),
                InlineMessage.error(errorText(failure), key: Key('$keyPrefix.error')),
              ],
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: Key('$keyPrefix.toggle'),
                label: blocked ? copy.unblockAction : copy.blockAction,
                variant: blocked ? AppButtonVariant.primary : AppButtonVariant.danger,
                loading: state is AccessBlockWorking<T>,
                // A second question must not open while the first answer is on its way.
                onPressed: state is AccessBlockWorking<T> ? null : () => _confirm(context, record),
              ),
            ],
          ),
        );
      },
    );
  }
}
