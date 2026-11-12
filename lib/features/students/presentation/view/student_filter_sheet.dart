import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Opens a sheet to choose one of [options] (ID and name), or "Any" for none, for a filter of the students list. The
/// answer holds the ID chosen, null for Any; a sheet dismissed without a choice answers null itself.
Future<({String? id})?> showStudentFilterSheet(
  BuildContext context, {
  required String title,
  required List<({String id, String name})> options,
  required String? selected,
}) => showAppBottomSheet<({String? id})>(
  context: context,
  title: title,
  builder: (sheet) => Column(
    children: [
      AppRadioTile<String?>(
        key: const Key('studentFilter.any'),
        title: AppLocalizations.of(sheet).studentsFilterAny,
        value: null,
        groupValue: selected,
        onChanged: (_) => Navigator.of(sheet).pop((id: null)),
      ),
      for (final option in options)
        AppRadioTile<String?>(
          key: ValueKey('studentFilter.option.${option.id}'),
          title: option.name,
          value: option.id,
          groupValue: selected,
          onChanged: (_) => Navigator.of(sheet).pop((id: option.id)),
        ),
    ],
  ),
);
