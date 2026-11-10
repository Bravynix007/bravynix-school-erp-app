import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_dropdown_field.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/auth/presentation/role/view/role_error_text.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/bloc/place_bloc.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The country, state and city of an address, chosen through the [PlaceBloc] above it. [keyPrefix] names the three
/// fields (`<prefix>.country`, `.state`, `.city`); a start that failed shows `<prefix>.placeFailed` with
/// `<prefix>.placeRetry`, and a list that failed later shows `<prefix>.listFailed` with `<prefix>.listRetry`. The
/// errors are what the API said about each of the three.
class PlaceFields extends StatelessWidget {
  const new({required this.keyPrefix, this.countryError, this.stateError, this.cityError, super.key});

  final String keyPrefix;
  final String? countryError;
  final String? stateError;
  final String? cityError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<PlaceBloc>();
    return BlocBuilder<PlaceBloc, PlaceState>(
      builder: (context, state) => switch (state) {
        PlaceLoading() => Semantics(label: l10n.loading, child: const SkeletonBox(height: 56)),
        PlaceFailed(:final failure) => InlineMessage.error(
          apiErrorText(l10n, failure, notFound: l10n.errorGeneric),
          key: Key('$keyPrefix.placeFailed'),
          actionLabel: l10n.retry,
          onAction: () => bloc.add(const PlaceStarted()),
          actionKey: Key('$keyPrefix.placeRetry'),
        ),
        PlaceReady() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlaceDropdown(
              fieldKey: Key('$keyPrefix.country'),
              label: l10n.placeCountry,
              entries: state.countries,
              value: state.choice.countryId,
              error: countryError,
              onChanged: (id) => bloc.add(PlaceCountryChosen(id)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlaceDropdown(
              fieldKey: Key('$keyPrefix.state'),
              label: l10n.placeState,
              entries: state.states,
              value: state.choice.stateId,
              error: stateError,
              // A state is chosen within a country.
              onChanged: state.choice.countryId == null ? null : (id) => bloc.add(PlaceStateChosen(id)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlaceDropdown(
              fieldKey: Key('$keyPrefix.city'),
              label: l10n.placeCity,
              entries: state.cities,
              value: state.choice.cityId,
              error: cityError,
              onChanged: state.choice.stateId == null ? null : (id) => bloc.add(PlaceCityChosen(id)),
            ),
            // A list that could not be read is said under the lists, with a way to read it again.
            if (state.failure case final failure?) ...[
              const SizedBox(height: AppSpacing.sm),
              InlineMessage.error(
                apiErrorText(l10n, failure, notFound: l10n.errorGeneric),
                key: Key('$keyPrefix.listFailed'),
                actionLabel: l10n.retry,
                onAction: () => bloc.add(const PlaceListsRetried()),
                actionKey: Key('$keyPrefix.listRetry'),
              ),
            ],
          ],
        ),
      },
    );
  }
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
