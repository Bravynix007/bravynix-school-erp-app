import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_form_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/board_name.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_form_error_text.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Institutions → Add Institution, or Edit on one Institution (INS-02, INS-04). Only an Owner reaches
/// it; the API refuses anyone else. Closes with `true` once saved, so the screen behind reads its data again.
class InstitutionFormPage extends StatelessWidget {
  /// [id] set edits that Institution; null adds one.
  const new({this.id, super.key});

  final String? id;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        InstitutionFormBloc(getIt<InstitutionsRepository>(), getIt<MastersRepository>(), institutionId: id)
          ..add(const InstitutionFormStarted()),
    child: const InstitutionFormView(),
  );
}

class InstitutionFormView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<InstitutionFormBloc, InstitutionFormState>(
      listenWhen: (previous, current) => current is InstitutionFormSaved,
      listener: (context, _) {
        AppSnackbar.show(context, message: l10n.institutionSaved, kind: AppSnackbarKind.success);
        context.pop(true);
      },
      child: BlocBuilder<InstitutionFormBloc, InstitutionFormState>(
        builder: (context, state) {
          final isEdit = context.read<InstitutionFormBloc>().institutionId != null;
          final title = isEdit ? l10n.institutionEditTitle : l10n.institutionAddTitle;
          return switch (state) {
            InstitutionFormReady() => _Form(state: state, title: title),
            _ => Scaffold(
              body: Column(
                children: [
                  AppTopBar(title: title, onBack: () => context.pop(), backTooltip: l10n.back),
                  Expanded(
                    child: switch (state) {
                      InstitutionFormFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                        key: const Key('institutionForm.forbidden'),
                        title: institutionFormErrorText(l10n, failure),
                      ),
                      InstitutionFormFailed(:final failure) when failure.code == 'NOT_FOUND' => StatePanel.empty(
                        key: const Key('institutionForm.notFound'),
                        title: institutionFormErrorText(l10n, failure),
                      ),
                      InstitutionFormFailed(:final failure) => StatePanel.error(
                        key: const Key('institutionForm.failed'),
                        title: institutionFormErrorText(l10n, failure),
                        actionLabel: l10n.retry,
                        onAction: () => context.read<InstitutionFormBloc>().add(const InstitutionFormStarted()),
                      ),
                      _ => const _Skeleton(),
                    },
                  ),
                ],
              ),
            ),
          };
        },
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
        SkeletonBox(height: 280, radius: AppRadius.card),
        SizedBox(height: AppSpacing.sm),
        SkeletonBox(height: 160, radius: AppRadius.card),
      ],
    ),
  );
}

/// The dial code a new Institution's phone starts with: India is the only country for now.
const _indiaDialCode = '91';

class _Form extends StatefulWidget {
  const new({required this.state, required this.title});

  final InstitutionFormReady state;
  final String title;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _place;
  late final TextEditingController _affiliation;
  late final TextEditingController _gstin;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _pincode;
  late final TextEditingController _email;
  late final TextEditingController _phoneCode;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _telephone;

  @override
  void initState() {
    super.initState();
    final existing = widget.state.existing;
    _name = TextEditingController(text: existing?.name);
    _code = TextEditingController(text: existing?.code);
    _place = TextEditingController(text: existing?.place);
    _affiliation = TextEditingController(text: existing?.affiliationNumber);
    _gstin = TextEditingController(text: existing?.gstin);
    _line1 = TextEditingController(text: existing?.addressLine1);
    _line2 = TextEditingController(text: existing?.addressLine2);
    _pincode = TextEditingController(text: existing?.pincode);
    _email = TextEditingController(text: existing?.email);
    _phoneCode = TextEditingController(text: existing == null ? _indiaDialCode : existing.phone?.countryCode);
    _phoneNumber = TextEditingController(text: existing?.phone?.number);
    _telephone = TextEditingController(text: existing?.telephone);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _code,
      _place,
      _affiliation,
      _gstin,
      _line1,
      _line2,
      _pincode,
      _email,
      _phoneCode,
      _phoneNumber,
      _telephone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() => context.read<InstitutionFormBloc>().add(
    InstitutionFormSubmitted(
      InstitutionTexts(
        name: _name.text,
        code: _code.text,
        addressLine1: _line1.text,
        place: _place.text,
        affiliationNumber: _affiliation.text,
        gstin: _gstin.text,
        email: _email.text,
        phoneCountryCode: _phoneCode.text,
        phoneNumber: _phoneNumber.text,
        telephone: _telephone.text,
        addressLine2: _line2.text,
        pincode: _pincode.text,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final bloc = context.read<InstitutionFormBloc>();
    final failure = state.failure;
    String? error(String field) => failure?.fieldError(field)?.message;
    // A save that failed on fields of this form is shown under them; any other failure, and a list that did not load,
    // is said above.
    final banner = failure != null && !_isFieldFailure(failure) ? institutionFormErrorText(l10n, failure) : null;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: widget.title, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                if (banner != null) ...[
                  InlineMessage.error(banner, key: const Key('institutionForm.error')),
                  // Someone else saved first, so the form is read again before another Save can succeed (API design 8.2).
                  if (failure?.code == 'VERSION_CONFLICT')
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        key: const Key('institutionForm.reload'),
                        label: l10n.institutionReload,
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.medium,
                        onPressed: () => bloc.add(const InstitutionFormStarted()),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SectionHeader(title: l10n.institutionFormBasics),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('institutionForm.name'),
                        label: l10n.institutionName,
                        controller: _name,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('name'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.code'),
                        label: l10n.institutionCode,
                        controller: _code,
                        mono: true,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        // The code is set when the Institution is added and never changed.
                        enabled: !state.isEdit,
                        helper: state.isEdit ? null : l10n.institutionCodeHelper,
                        error: error('code'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.place'),
                        label: l10n.institutionPlace,
                        controller: _place,
                        error: error('place'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppDropdownField<Board?>(
                        key: const Key('institutionForm.board'),
                        label: l10n.institutionBoard,
                        value: state.board,
                        error: error('boardCode'),
                        items: [
                          DropdownMenuItem<Board?>(child: Text(l10n.institutionBoardNone)),
                          for (final board in Board.values)
                            DropdownMenuItem<Board?>(value: board, child: Text(boardName(l10n, board))),
                        ],
                        onChanged: (board) => bloc.add(InstitutionBoardChosen(board)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.affiliation'),
                        label: l10n.institutionAffiliation,
                        controller: _affiliation,
                        mono: true,
                        error: error('affiliationNumber'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.gstin'),
                        label: l10n.institutionGstin,
                        controller: _gstin,
                        mono: true,
                        error: error('gstin'),
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.institutionClassesOffered),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: state.categories.isEmpty
                      ? Text(l10n.institutionNoCategories, style: Theme.of(context).textTheme.bodyMedium)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final category in state.categories)
                              AppCheckboxTile(
                                key: ValueKey('institutionForm.category.${category.id}'),
                                title: category.name,
                                value: state.categoryIds.contains(category.id),
                                onChanged: (_) => bloc.add(InstitutionCategoryToggled(category.id)),
                              ),
                            if (error('classesOffered') case final message?)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  message,
                                  key: const Key('institutionForm.categoriesError'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.institutionAddress),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('institutionForm.line1'),
                        label: l10n.institutionAddressLine1,
                        controller: _line1,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('address.line1'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.line2'),
                        label: l10n.institutionAddressLine2,
                        controller: _line2,
                        error: error('address.line2'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PlaceDropdown(
                        fieldKey: const Key('institutionForm.country'),
                        label: l10n.institutionCountry,
                        entries: state.countries,
                        value: state.countryId,
                        error: error('address.countryId'),
                        onChanged: (id) => bloc.add(InstitutionCountryChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PlaceDropdown(
                        fieldKey: const Key('institutionForm.state'),
                        label: l10n.institutionState,
                        entries: state.states,
                        value: state.stateId,
                        error: error('address.stateId'),
                        // A state is chosen within a country.
                        onChanged: state.countryId == null ? null : (id) => bloc.add(InstitutionStateChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PlaceDropdown(
                        fieldKey: const Key('institutionForm.city'),
                        label: l10n.institutionCity,
                        entries: state.cities,
                        value: state.cityId,
                        error: error('address.cityId'),
                        onChanged: state.stateId == null ? null : (id) => bloc.add(InstitutionCityChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.pincode'),
                        label: l10n.institutionPincode,
                        controller: _pincode,
                        mono: true,
                        keyboardType: TextInputType.number,
                        error: error('address.pincode'),
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(title: l10n.institutionContact),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        key: const Key('institutionForm.email'),
                        label: l10n.profileEmail,
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        error: error('email'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.phoneCode'),
                        label: l10n.institutionCountryCode,
                        controller: _phoneCode,
                        mono: true,
                        keyboardType: TextInputType.number,
                        error: error('phone.countryCode'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.phoneNumber'),
                        label: l10n.institutionPhoneNumber,
                        controller: _phoneNumber,
                        mono: true,
                        keyboardType: TextInputType.phone,
                        error: error('phone.number') ?? error('phone'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('institutionForm.telephone'),
                        label: l10n.institutionTelephone,
                        controller: _telephone,
                        keyboardType: TextInputType.phone,
                        error: error('telephone'),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: l10n.institutionSave,
        primaryLoading: state.saving,
        onPrimary: state.saving ? null : _save,
        secondaryLabel: l10n.cancel,
        onSecondary: () => context.pop(),
      ),
    );
  }

  /// The fields the form shows an error under, named as the API names them.
  static const _fields = {
    'name',
    'code',
    'place',
    'boardCode',
    'affiliationNumber',
    'gstin',
    'email',
    'phone',
    'phone.countryCode',
    'phone.number',
    'telephone',
    'classesOffered',
    'address.line1',
    'address.line2',
    'address.pincode',
    'address.countryId',
    'address.stateId',
    'address.cityId',
  };

  /// True when every field error of the failure belongs to a field of this form, so each shows under its own field.
  /// A field it does not know (`classesOffered[1]`) would show nowhere, so the failure is said above instead.
  static bool _isFieldFailure(ApiFailure failure) =>
      failure.fieldErrors.isNotEmpty && failure.fieldErrors.every((error) => _fields.contains(error.field));
}

/// A country, state or city picker. A value that is not in [entries] (the list is still loading, or the entry was
/// hidden since it was chosen) shows as empty rather than breaking the dropdown.
class _PlaceDropdown extends StatelessWidget {
  const new({
    required this.fieldKey,
    required this.label,
    required this.entries,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final Key fieldKey;
  final String label;
  final List<MasterEntry> entries;
  final String? value;
  final String? error;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) => AppDropdownField<String>(
    key: fieldKey,
    label: label,
    value: entries.any((entry) => entry.id == value) ? value : null,
    error: error,
    items: [for (final entry in entries) DropdownMenuItem(value: entry.id, child: Text(entry.name))],
    onChanged: onChanged,
  );
}
