import 'package:bravynix_school_erp/core/device/screen_protection.dart';
import 'package:bravynix_school_erp/core/model/aadhaar.dart';
import 'package:bravynix_school_erp/core/widgets/aadhaar_input.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/identity_number_bloc.dart'
    show IdentityNumberBloc;
import 'package:bravynix_school_erp/features/people/presentation/view/identity_number_card.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// The Aadhaar number of a profile (staff STF-11 and STF-12, student STU-10 and STU-11): masked, with a way to set it,
/// clear it, and show the whole number for a reason. It reads the [IdentityNumberBloc] above it, which has a reveal.
class AadhaarCard extends StatelessWidget {
  const new({
    required this.personName,
    required this.protection,
    required this.errorText,
    this.changeable = true,
    super.key,
  });

  /// Whose number it is, as the question to clear it names them.
  final String personName;

  /// Keeps the screen out of screenshots while the whole number is shown.
  final ScreenProtection protection;

  /// What a refusal of one of the calls says; the codes are the profile's own.
  final FailureText errorText;

  /// False for a record that is deactivated: the number can still be shown, but no longer set or cleared.
  final bool changeable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IdentityNumberCard(
      keyPrefix: 'aadhaar',
      copy: IdentityNumberCopy(
        label: l10n.aadhaar,
        notSet: l10n.aadhaarNotSet,
        set: l10n.aadhaarSet,
        change: l10n.aadhaarChange,
        clear: l10n.aadhaarClear,
        clearTitle: l10n.aadhaarClearTitle(personName),
        clearMessage: l10n.aadhaarClearMessage,
        saved: l10n.aadhaarSaved,
        savedElsewhere: l10n.aadhaarSavedElsewhere,
        cleared: l10n.aadhaarCleared,
        invalid: l10n.aadhaarInvalid,
        helper: l10n.aadhaarSetHelper,
      ),
      // Twelve digits are checked here, and the server checks the rest.
      rule: IdentityNumberRule(
        normalise: Aadhaar.typed,
        formatters: aadhaarInputFormatters(),
        keyboardType: TextInputType.number,
      ),
      errorText: errorText,
      protection: protection,
      changeable: changeable,
    );
  }
}
