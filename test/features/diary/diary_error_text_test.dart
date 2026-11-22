import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/diary/presentation/view/diary_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

ApiFailure _code(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: 'x');

void main() {
  late AppLocalizations l10n;
  setUp(() => l10n = AppLocalizationsEn());

  test('the list has its own words for a section that is not theirs, a year that is not set and a missing section', () {
    expect(diaryErrorText(l10n, _code('NOT_ASSIGNED', status: 403)), l10n.errorDiaryNotAssigned);
    expect(diaryErrorText(l10n, _code('CURRENT_YEAR_REQUIRED')), l10n.errorDiaryNoYear);
    expect(diaryErrorText(l10n, _code('NOT_FOUND', status: 404)), l10n.errorDiaryNotFound);
  });

  test('the rest reads as everywhere else, a blocked child included', () {
    expect(diaryErrorText(l10n, _code('CHILD_ACCESS_BLOCKED', status: 403)), l10n.errorChildAccessBlocked);
    expect(diaryErrorText(l10n, _code('FORBIDDEN', status: 403)), l10n.errorForbidden);
  });

  test('an entry has its own words for each date it can be refused for, each its own', () {
    final dates = {
      'DATE_IN_FUTURE': l10n.errorDiaryFuture,
      'DATE_TOO_OLD': l10n.errorDiaryTooOld,
      'DATE_OUTSIDE_CURRENT_YEAR': l10n.errorDiaryOutsideYear,
    };
    for (final MapEntry(:key, :value) in dates.entries) {
      expect(diaryEntryErrorText(l10n, _code(key), adding: true), value, reason: key);
    }
    expect(dates.values.toSet(), hasLength(dates.length));
  });

  test('NOT_ASSIGNED says what a teacher may write when adding, and who may change an entry otherwise', () {
    final failure = _code('NOT_ASSIGNED', status: 403);
    expect(diaryEntryErrorText(l10n, failure, adding: true), l10n.errorDiaryNotAssignedAdd);
    expect(diaryEntryErrorText(l10n, failure, adding: false), l10n.errorDiaryNotAssignedChange);
  });

  test('a subject or section closed meanwhile is said as everywhere', () {
    expect(diaryEntryErrorText(l10n, _code('REFERENCE_INACTIVE'), adding: true), l10n.errorReferenceInactive);
  });

  test('a 404 is an entry already removed for a change or a delete, and a missing section for an add', () {
    final failure = _code('NOT_FOUND', status: 404);
    expect(diaryEntryErrorText(l10n, failure, adding: false), l10n.errorDiaryEntryGone);
    expect(diaryEntryErrorText(l10n, failure, adding: true), l10n.errorDiaryNotFound);
  });
}
