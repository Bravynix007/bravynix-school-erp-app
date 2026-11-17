import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_switch_tile.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/stale_copy_guard.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/bloc/time_slot_form_bloc.dart';
import 'package:bravynix_school_erp/features/time_slots/presentation/view/time_slot_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which Institution the form adds a period to, and the period it edits (null to add).
class TimeSlotFormArgs {
  const new({required this.institutionId, this.slot});

  final String institutionId;
  final TimeSlot? slot;
}

/// School setup → Period timings → Add, or Edit on one period (TTS-02, TTS-03). Closes with `true` once saved, so the
/// list behind it reads again.
class TimeSlotFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final TimeSlotFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TimeSlotFormBloc(getIt<TimeSlotsRepository>(), args.institutionId, existing: args.slot),
    child: TimeSlotFormView(slot: args.slot),
  );
}

class TimeSlotFormView extends StatefulWidget {
  const new({this.slot, super.key});

  final TimeSlot? slot;

  @override
  State<TimeSlotFormView> createState() => _TimeSlotFormViewState();
}

class _TimeSlotFormViewState extends State<TimeSlotFormView> {
  late final TextEditingController _number = TextEditingController(text: widget.slot?.periodNo.toString());
  late final TextEditingController _label = TextEditingController(text: widget.slot?.label);
  late String _start = widget.slot?.startTime ?? '';
  late String _end = widget.slot?.endTime ?? '';
  bool _isBreak = false;

  /// The fields a refusal can name; a refusal that names anything else is said above the form.
  static const _fields = {'periodNo', 'label', 'startTime', 'endTime'};

  @override
  void dispose() {
    _number.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _pick(String current, ValueChanged<String> chosen) async {
    final parts = current.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked != null) setState(() => chosen(Formatters.clockTime(picked.hour, picked.minute)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slot = widget.slot;
    return BlocConsumer<TimeSlotFormBloc, TimeSlotFormState>(
      listenWhen: (previous, current) => current is TimeSlotFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.timeSlotSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is TimeSlotFormEditing ? state : const TimeSlotFormEditing(saving: true);
        final failure = editing.failure;
        String? error(String field) => failure == null ? null : timeSlotFieldError(l10n, failure, field);
        // A refused field is shown under it; any other refusal (no current year, a stale period) is said above.
        final onFields = failure != null && failure.namesOnly(_fields);
        return StaleCopyGuard(
          stale: failure?.outdatesCopy ?? false,
          child: Scaffold(
            body: Column(
              children: [
                AppTopBar(
                  title: slot == null ? l10n.timeSlotAddTitle : l10n.timeSlotEditTitle,
                  onBack: () => Navigator.maybePop(context),
                  backTooltip: l10n.back,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    children: [
                      if (failure != null && !onFields) ...[
                        // The period was changed meanwhile and no endpoint reads one period, so the list is read again.
                        InlineMessage.error(
                          timeSlotErrorText(l10n, failure),
                          key: const Key('timeSlotForm.error'),
                          actionLabel: failure.code == 'VERSION_CONFLICT' ? l10n.backToList : null,
                          onAction: () => context.pop(true),
                          actionKey: const Key('timeSlotForm.backToList'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      AppTextField(
                        key: const Key('timeSlotForm.number'),
                        label: l10n.timeSlotNumber,
                        controller: _number,
                        helper: slot == null ? l10n.timeSlotNumberHelper : null,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        // The number is fixed once the period is added.
                        enabled: slot == null,
                        error: error('periodNo'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('timeSlotForm.label'),
                        label: l10n.timeSlotLabel,
                        controller: _label,
                        helper: l10n.timeSlotLabelHelper,
                        error: error('label'),
                        inputFormatters: [LengthLimitingTextInputFormatter(100)],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppDateField(
                        key: const Key('timeSlotForm.start'),
                        label: l10n.timeSlotStart,
                        valueText: _start,
                        icon: Icons.schedule_outlined,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('startTime'),
                        onTap: () => _pick(_start, (time) => _start = time),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppDateField(
                        key: const Key('timeSlotForm.end'),
                        label: l10n.timeSlotEnd,
                        valueText: _end,
                        icon: Icons.schedule_outlined,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('endTime'),
                        onTap: () => _pick(_end, (time) => _end = time),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitchTile(
                        key: const Key('timeSlotForm.break'),
                        title: l10n.timeSlotBreak,
                        subtitle: l10n.timeSlotBreakHelper,
                        // Whether it is a break is fixed once the period is added.
                        value: slot?.isBreak ?? _isBreak,
                        onChanged: slot == null ? (value) => setState(() => _isBreak = value) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: StickyBottomActions(
              primaryLabel: l10n.timeSlotSave,
              primaryLoading: editing.saving,
              onPrimary: editing.saving
                  ? null
                  : () => context.read<TimeSlotFormBloc>().add(
                      TimeSlotFormSubmitted(
                        TimeSlotFields(
                          periodNo: _number.text,
                          label: _label.text,
                          startTime: _start,
                          endTime: _end,
                          isBreak: _isBreak,
                        ),
                      ),
                    ),
              secondaryLabel: l10n.cancel,
              onSecondary: () => Navigator.maybePop(context),
            ),
          ),
        );
      },
    );
  }
}
