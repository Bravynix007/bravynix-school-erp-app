import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/features/events/domain/event.dart';
import 'package:bravynix_school_erp/features/events/presentation/view/event_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/events.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('says each audience, scope and kind of holiday in its own words', () {
    expect(
      [for (final audience in EventAudience.values) EventText.audience(l10n, audience)],
      ['Everyone', 'Students and parents', 'Staff'],
    );
    expect(
      [for (final scope in EventScope.values) EventText.scope(l10n, scope)],
      [
        'The whole Society',
        'One Institution',
      ],
    );
    expect(
      [for (final type in HolidayType.values) EventText.holidayType(l10n, type)],
      ['Public holiday', 'Vacation', 'Event holiday', 'Optional'],
    );
  });

  test('gives each preset picture its own icon, and a holiday without one a beach', () {
    final icons = {
      'assembly': Icons.groups_outlined,
      'celebration': Icons.celebration_outlined,
      'cultural': Icons.theater_comedy_outlined,
      'exam': Icons.edit_note_outlined,
      'festival': Icons.festival_outlined,
      'holiday': Icons.beach_access_outlined,
      'meeting': Icons.handshake_outlined,
      'science': Icons.science_outlined,
      'sports': Icons.sports_soccer_outlined,
      'trip': Icons.directions_bus_outlined,
    };
    for (final MapEntry(:key, :value) in icons.entries) {
      expect(EventText.icon(schoolEvent(presetImageCode: key)), value, reason: key);
    }
    expect(EventText.icon(schoolEvent()), Icons.event_outlined);
    expect(EventText.icon(schoolEvent(isHoliday: true)), Icons.beach_access_outlined);
    expect(EventText.icon(schoolEvent(presetImageCode: 'unknown')), Icons.event_outlined);
  });

  group('AppRoutes.diaryOn', () {
    test('opens the diary on the day a notice names, and on today for none', () {
      expect(AppRoutes.diaryOn('2026-11-21'), '/diary?day=2026-11-21');
      expect(AppRoutes.diaryOn(null), '/diary');
    });
  });

  group('AppRoutes.event', () {
    test('encodes the ID it puts in the path', () {
      expect(AppRoutes.event('a/b c'), '/events/a%2Fb%20c');
    });

    test('carries the child a notice is about, when there is one', () {
      expect(AppRoutes.event('e1', studentId: 's2'), '/events/e1?studentId=s2');
      expect(AppRoutes.event('a/b', studentId: 's 2'), '/events/a%2Fb?studentId=s+2');
    });
  });
}
