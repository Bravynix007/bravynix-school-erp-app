import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart' show SchoolClass;
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';

/// A class whose sections a teacher does not lead or teach.
const class2 = SchoolClass(
  id: 'k2',
  institutionId: 'i1',
  predefinedClass: class2Ref,
  category: lowerPrimaryCategory,
  displayName: 'Class 2',
  sectionCount: 1,
  version: 1,
);

void main() {
  late MockAcademicYearsRepository years;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;
  late SectionOptionsSource source;

  setUp(() {
    years = MockAcademicYearsRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    when(() => years.years('i1')).thenAnswer((_) async => [earlierYear, currentYear]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
    source = SectionOptionsSource(years: years, classes: classes, sections: sections);
  });

  test('reads the years, and each section named with its class, of the classes that have any', () async {
    final options = await source.read('i1');
    expect(options.years, [earlierYear, currentYear]);
    expect(options.sections, const [
      SectionChoice(id: 'e1', name: 'Class 1 · Section A', classId: 'k1'),
      SectionChoice(id: 'e2', name: 'Class 1 · Blue', classId: 'k1'),
    ]);
    expect(options.classes, const [ClassChoice(id: 'k1', name: 'Class 1')]);
    verifyNever(() => sections.sections('k9'));
  });

  test('reads once for the sections that ask for the same Institution, and again for another', () async {
    when(() => years.years('i2')).thenAnswer((_) async => []);
    when(() => classes.classes('i2')).thenAnswer((_) async => []);
    final both = await Future.wait([source.read('i1'), source.read('i1')]);
    expect(both.first, same(both.last));
    await source.read('i1');
    verify(() => years.years('i1')).called(1);
    verify(() => sections.sections('k1')).called(1);
    expect((await source.read('i2')).years, isEmpty);
  });

  test('throws what could not be read, and tries again on the next read', () async {
    when(() => sections.sections('k1')).thenThrow(const ApiFailure.network());
    await expectLater(source.read('i1'), throwsA(isA<ApiFailure>()));
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA]);
    expect((await source.read('i1')).sections, const [
      SectionChoice(id: 'e1', name: 'Class 1 · Section A', classId: 'k1'),
    ]);
  });

  test('leaves out the classes where a teacher has no section, which the API refuses with NOT_ASSIGNED', () async {
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, class2]);
    when(() => sections.sections('k2')).thenThrow(
      const ApiFailure(statusCode: 403, code: 'NOT_ASSIGNED', message: 'x'),
    );
    final options = await source.read('i1');
    expect(options.classes, const [ClassChoice(id: 'k1', name: 'Class 1')]);
    expect([for (final section in options.sections) section.id], ['e1', 'e2']);
  });

  test('still throws any other refusal of the sections of a class', () async {
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, class2]);
    when(() => sections.sections('k2')).thenThrow(
      const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x'),
    );
    await expectLater(source.read('i1'), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'FORBIDDEN')));
  });

  group('the year to look at first', () {
    test(
      'is the current one',
      () => expect(const SectionOptions(years: [earlierYear, currentYear], sections: []).firstYearId, 'y1'),
    );

    test('is the first when none is current', () {
      expect(const SectionOptions(years: [earlierYear], sections: []).firstYearId, 'y0');
    });

    test(
      'is none when there is no year',
      () => expect(const SectionOptions(years: [], sections: []).firstYearId, isNull),
    );
  });

  group('the sections in a class', () {
    const choices = [
      SectionChoice(id: 'e1', name: 'Class 1 · A', classId: 'k1'),
      SectionChoice(id: 'e2', name: 'Class 1 · B', classId: 'k1'),
      SectionChoice(id: 'e3', name: 'Class 2 · A', classId: 'k2'),
    ];

    test('are those of the class, in their order', () {
      expect(choices.inClass('k1').map((s) => s.id), ['e1', 'e2']);
      expect(choices.inClass('k2').map((s) => s.id), ['e3']);
    });

    test('are none for a class without sections and while no class is chosen', () {
      expect(choices.inClass('k9'), isEmpty);
      expect(choices.inClass(null), isEmpty);
    });

    test('have their name found by ID, and none for an ID that is not there or not chosen', () {
      expect(choices.nameOf('e2'), 'Class 1 · B');
      expect(choices.nameOf('e9'), isNull);
      expect(choices.nameOf(null), isNull);
    });
  });
}
