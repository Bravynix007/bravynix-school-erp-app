import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/bloc/academic_year_form_bloc.dart';
import 'package:bravynix_school_erp/features/academic_years/presentation/view/academic_year_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which Institution the form adds a year to, and the year it edits (null to add).
class AcademicYearFormArgs {
  const new({required this.institutionId, this.year});

  final String institutionId;
  final AcademicYear? year;
}

/// School setup → Academic years → Add, or Edit on one year (AY-02, AY-03). Closes with `true` once saved, so the list
/// behind it reads again.
class AcademicYearFormPage extends StatelessWidget {
  const new({required this.args, super.key});

  final AcademicYearFormArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AcademicYearFormBloc(getIt<AcademicYearsRepository>(), args.institutionId, existing: args.year),
    child: AcademicYearFormView(year: args.year),
  );
}

class AcademicYearFormView extends StatefulWidget {
  const new({this.year, super.key});

  final AcademicYear? year;

  @override
  State<AcademicYearFormView> createState() => _AcademicYearFormViewState();
}

class _AcademicYearFormViewState extends State<AcademicYearFormView> {
  late final TextEditingController _name = TextEditingController(text: widget.year?.name);
  late String _start = widget.year?.startDate ?? '';
  late String _end = widget.year?.endDate ?? '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(String current, ValueChanged<String> chosen) async {
    final today = DateTime.now();
    final initial = DateTime.tryParse(current) ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => chosen(Formatters.isoDay(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.year != null;
    return BlocConsumer<AcademicYearFormBloc, AcademicYearFormState>(
      listenWhen: (previous, current) => current is AcademicYearFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.academicYearSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      builder: (context, state) {
        final editing = state is AcademicYearFormEditing ? state : const AcademicYearFormEditing(saving: true);
        final failure = editing.failure;
        String? error(String field) => failure?.fieldError(field)?.message;
        // A refused field is shown under it; any other refusal (an overlap, a duplicate name, a stale year) is said above.
        final onFields = failure != null && failure.code == 'VALIDATION_FAILED' && failure.fieldErrors.isNotEmpty;
        return Scaffold(
          body: Column(
            children: [
              AppTopBar(
                title: isEdit ? l10n.academicYearEditTitle : l10n.academicYearAddTitle,
                onBack: () => context.pop(),
                backTooltip: l10n.back,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  children: [
                    if (failure != null && !onFields) ...[
                      InlineMessage.error(
                        academicYearErrorText(l10n, failure),
                        key: const Key('academicYearForm.error'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppTextField(
                      key: const Key('academicYearForm.name'),
                      label: l10n.academicYearName,
                      controller: _name,
                      helper: l10n.academicYearNameHelper,
                      required: true,
                      requiredLabel: l10n.fieldRequired,
                      error: error('name'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppDateField(
                      key: const Key('academicYearForm.start'),
                      label: l10n.academicYearStart,
                      valueText: Formatters.schoolDate(_start),
                      required: true,
                      requiredLabel: l10n.fieldRequired,
                      error: error('startDate'),
                      onTap: () => _pick(_start, (day) => _start = day),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppDateField(
                      key: const Key('academicYearForm.end'),
                      label: l10n.academicYearEnd,
                      valueText: Formatters.schoolDate(_end),
                      required: true,
                      requiredLabel: l10n.fieldRequired,
                      error: error('endDate'),
                      onTap: () => _pick(_end, (day) => _end = day),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: StickyBottomActions(
            primaryLabel: l10n.academicYearSave,
            primaryLoading: editing.saving,
            onPrimary: editing.saving
                ? null
                : () => context.read<AcademicYearFormBloc>().add(
                    AcademicYearFormSubmitted(AcademicYearFields(name: _name.text, startDate: _start, endDate: _end)),
                  ),
            secondaryLabel: l10n.cancel,
            onSecondary: () => context.pop(),
          ),
        );
      },
    );
  }
}
