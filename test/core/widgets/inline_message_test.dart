import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('says its sentence as a live region, with no button unless it is given an action', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpApp(const Scaffold(body: InlineMessage.error('Check the fields.')));
    expect(find.text('Check the fields.'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(
      tester.getSemantics(find.text('Check the fields.')).getSemanticsData().flagsCollection.isLiveRegion,
      isTrue,
    );
    handle.dispose();
  });

  testWidgets('offers one way forward under the sentence, and takes it when tapped', (tester) async {
    var taken = 0;
    await tester.pumpApp(
      Scaffold(
        body: InlineMessage.error(
          'Someone else changed this.',
          actionLabel: 'Back to the list',
          onAction: () => taken++,
          actionKey: const Key('message.action'),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('message.action')));
    expect(taken, 1);
    expect(find.text('Back to the list'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Back to the list')).dy,
      greaterThan(tester.getBottomLeft(find.text('Someone else changed this.')).dy - 1),
    );
  });

  testWidgets('an action label with no action, or the reverse, shows no button', (tester) async {
    await tester.pumpApp(const Scaffold(body: InlineMessage.warning('Careful', actionLabel: 'Do it')));
    expect(find.text('Do it'), findsNothing);
  });
}
