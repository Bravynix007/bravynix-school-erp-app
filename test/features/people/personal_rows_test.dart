import 'package:bravynix_school_erp/core/model/gender.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/personal_rows.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows gender, date of birth, blood group and nationality, as they are set', (tester) async {
    await tester.pumpApp(
      const PersonalRows(gender: Gender.female, dateOfBirth: '2018-04-17', bloodGroup: 'O+', nationality: 'Indian'),
    );
    for (final text in [
      'Gender',
      'Female',
      'Date of birth',
      '17-04-2018',
      'Blood group',
      'O+',
      'Nationality',
      'Indian',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('shows a row only for what is set', (tester) async {
    await tester.pumpApp(const PersonalRows(bloodGroup: 'B-'));
    expect(find.text('B-'), findsOneWidget);
    for (final label in ['Gender', 'Date of birth', 'Nationality']) {
      expect(find.text(label), findsNothing, reason: label);
    }
  });
}
