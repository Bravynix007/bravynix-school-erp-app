import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_repository.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/timetable_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/timetable.dart';

void main() {
  late MockTimetableRepository repository;
  setUpAll(() => registerFallbackValue(const SectionWeek('x')));
  setUp(() {
    repository = MockTimetableRepository();
    getIt.registerSingleton<TimetableRepository>(repository);
  });
  tearDown(getIt.reset);

  testWidgets('names the section above its week, and reads the week of that section', (tester) async {
    when(() => repository.week(any())).thenAnswer((_) async => [mathsMonday]);
    await tester.pumpApp(
      SectionTimetablePage(
        args: const SectionTimetableArgs(sectionId: 'sec1', institutionId: 'i1', title: '7th - A'),
        clock: () => DateTime(2026, 11, 16),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('7th - A'), findsOneWidget);
    expect(find.text('Mathematics'), findsOneWidget);
    // The section's week is the one the person builds, so it offers Add, Edit and Delete.
    expect(find.byKey(const Key('timetable.add')), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable.edit.x1')), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable.delete.x1')), findsOneWidget);
    verify(() => repository.week(const SectionWeek('sec1'))).called(1);
  });
}
