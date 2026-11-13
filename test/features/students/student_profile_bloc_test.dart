import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_profile_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';
import '../../helpers/staff.dart';
import '../../helpers/students.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');

void main() {
  late MockStudentsRepository students;
  late MockMastersRepository masters;
  late MockClassesRepository classes;
  late MockSectionsRepository sections;

  setUpAll(() => registerFallbackValue(MasterType.countries));
  setUp(() {
    students = MockStudentsRepository();
    masters = MockMastersRepository();
    classes = MockClassesRepository();
    sections = MockSectionsRepository();
    when(() => students.student('p1')).thenAnswer((_) async => ashaRecord);
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [countryEntry]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [stateEntry]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [cityEntry]);
    when(() => classes.classes('i1')).thenAnswer((_) async => [class1, pucClass]);
    when(() => sections.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]);
  });

  StudentProfileBloc build() => StudentProfileBloc(students, masters, classes, sections, 'p1');

  blocTest<StudentProfileBloc, StudentProfileState>(
    'reads the student, and the names of their class, section and place',
    build: build,
    act: (bloc) => bloc.add(const StudentProfileRequested()),
    expect: () => [
      const StudentProfileLoading(),
      const StudentProfileLoaded(
        StudentProfile(
          ashaRecord,
          placeName: 'Class 1 · Section A',
          countryName: 'India',
          stateName: 'Karnataka',
          cityName: 'Bengaluru',
        ),
      ),
    ],
    verify: (_) {
      // Only the class the student is in has its sections read.
      verify(() => sections.sections('k1')).called(1);
      verifyNoMoreInteractions(sections);
    },
  );

  blocTest<StudentProfileBloc, StudentProfileState>(
    'names only the class when the section is no longer offered, and reads no place for an address without one',
    setUp: () {
      when(() => sections.sections('k1')).thenAnswer((_) async => [sectionB]);
      when(() => students.student('p1')).thenAnswer(
        (_) async => StudentRecord(
          id: ashaRecord.id,
          institutionId: ashaRecord.institutionId,
          firstName: ashaRecord.firstName,
          mobile: null,
          address: const Address(),
          placement: ashaRecord.placement,
          guardians: ashaRecord.guardians,
          identity: ashaRecord.identity,
          isBlocked: false,
          isActive: true,
          version: 1,
        ),
      );
    },
    build: build,
    act: (bloc) => bloc.add(const StudentProfileRequested()),
    expect: () => [
      const StudentProfileLoading(),
      isA<StudentProfileLoaded>().having((s) => s.profile.placeName, 'place', 'Class 1').having(
        (s) => [s.profile.countryName, s.profile.stateName, s.profile.cityName],
        'places',
        [null, null, null],
      ),
    ],
    verify: (_) => verifyNever(() => masters.entries(any(), parentId: any(named: 'parentId'))),
  );

  blocTest<StudentProfileBloc, StudentProfileState>(
    'has no place name when the class is no longer there',
    setUp: () => when(() => classes.classes('i1')).thenAnswer((_) async => [pucClass]),
    build: build,
    act: (bloc) => bloc.add(const StudentProfileRequested()),
    expect: () => [
      const StudentProfileLoading(),
      isA<StudentProfileLoaded>().having((s) => s.profile.placeName, 'place', isNull),
    ],
    verify: (_) => verifyNever(() => sections.sections(any())),
  );

  blocTest<StudentProfileBloc, StudentProfileState>(
    'reads no class or section for a student without a placement',
    setUp: () => when(() => students.student('p1')).thenAnswer((_) async => balaRecord),
    build: build,
    act: (bloc) => bloc.add(const StudentProfileRequested()),
    expect: () => [
      const StudentProfileLoading(),
      const StudentProfileLoaded(StudentProfile(balaRecord)),
    ],
    verify: (_) {
      verifyNever(() => classes.classes(any()));
      verifyNever(() => sections.sections(any()));
    },
  );

  blocTest<StudentProfileBloc, StudentProfileState>(
    'fails when the student cannot be read, and reads again on Try again',
    setUp: () {
      var calls = 0;
      when(() => students.student('p1')).thenAnswer((_) async {
        if (calls++ == 0) throw _down;
        return ashaRecord;
      });
    },
    build: build,
    act: (bloc) async {
      bloc.add(const StudentProfileRequested());
      await bloc.stream.firstWhere((state) => state is StudentProfileFailed);
      bloc.add(const StudentProfileRequested());
    },
    expect: () => [
      const StudentProfileLoading(),
      const StudentProfileFailed(_down),
      const StudentProfileLoading(),
      isA<StudentProfileLoaded>(),
    ],
  );

  blocTest<StudentProfileBloc, StudentProfileState>(
    'fails when the names cannot be read',
    setUp: () => when(() => classes.classes('i1')).thenThrow(_down),
    build: build,
    act: (bloc) => bloc.add(const StudentProfileRequested()),
    expect: () => [const StudentProfileLoading(), const StudentProfileFailed(_down)],
  );
}
