import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/achievements/presentation/view/achievement_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ApiFailure _code(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  testWidgets('achievementErrorText has its own words for the codes the stars add', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(achievementErrorText(l10n, _code('NOT_ASSIGNED', status: 403)), l10n.errorNotAssigned);
    expect(achievementErrorText(l10n, _code('NO_CURRENT_PLACEMENT')), l10n.errorNoCurrentPlacement);
    expect(achievementErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorAchievementNotFound);
    expect(achievementErrorText(l10n, _code('FORBIDDEN', status: 403)), isNot(l10n.errorNotAssigned));
  });
}
