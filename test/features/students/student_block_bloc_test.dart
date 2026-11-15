import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_block_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/students.dart';

const _already = ApiFailure(statusCode: 409, code: 'INVALID_STATE', message: 'x');
const _forbidden = ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x');
const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');

void main() {
  late MockStudentsRepository students;

  setUp(() {
    students = MockStudentsRepository();
    when(() => students.block('p3')).thenAnswer((_) async => chitraBlockedRecord);
    when(() => students.unblock('p3')).thenAnswer((_) async => chitraRecord);
  });

  blocTest<StudentBlockBloc, StudentBlockState>(
    'blocks a student who is not blocked',
    build: () => StudentBlockBloc(students, chitraRecord),
    act: (bloc) => bloc.add(const StudentBlockToggled()),
    expect: () => [const StudentBlockWorking(chitraRecord), const StudentBlockIdle(chitraBlockedRecord)],
    verify: (_) {
      verify(() => students.block('p3')).called(1);
      verifyNever(() => students.unblock(any()));
    },
  );

  blocTest<StudentBlockBloc, StudentBlockState>(
    'lifts the block of a student who is blocked',
    build: () => StudentBlockBloc(students, chitraBlockedRecord),
    act: (bloc) => bloc.add(const StudentBlockToggled()),
    expect: () => [const StudentBlockWorking(chitraBlockedRecord), const StudentBlockIdle(chitraRecord)],
    verify: (_) {
      verify(() => students.unblock('p3')).called(1);
      verifyNever(() => students.block(any()));
    },
  );

  blocTest<StudentBlockBloc, StudentBlockState>(
    'takes the student as they are now when someone else already did what was asked',
    setUp: () {
      when(() => students.block('p3')).thenThrow(_already);
      when(() => students.student('p3')).thenAnswer((_) async => chitraBlockedRecord);
    },
    build: () => StudentBlockBloc(students, chitraRecord),
    act: (bloc) => bloc.add(const StudentBlockToggled()),
    expect: () => [
      const StudentBlockWorking(chitraRecord),
      const StudentBlockRefused(chitraBlockedRecord, _already),
    ],
  );

  blocTest<StudentBlockBloc, StudentBlockState>(
    'stays as it was when that cannot be read either',
    setUp: () {
      when(() => students.block('p3')).thenThrow(_already);
      when(() => students.student('p3')).thenThrow(_down);
    },
    build: () => StudentBlockBloc(students, chitraRecord),
    act: (bloc) => bloc.add(const StudentBlockToggled()),
    expect: () => [const StudentBlockWorking(chitraRecord), const StudentBlockRefused(chitraRecord, _already)],
  );

  blocTest<StudentBlockBloc, StudentBlockState>(
    'keeps the student as they were on any other refusal, and does not read them again',
    setUp: () => when(() => students.block('p3')).thenThrow(_forbidden),
    build: () => StudentBlockBloc(students, chitraRecord),
    act: (bloc) => bloc.add(const StudentBlockToggled()),
    expect: () => [const StudentBlockWorking(chitraRecord), const StudentBlockRefused(chitraRecord, _forbidden)],
    verify: (_) => verifyNever(() => students.student(any())),
  );

  test('asks once when pressed twice while it is working', () async {
    when(() => students.block('p3')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return chitraBlockedRecord;
    });
    final bloc = StudentBlockBloc(students, chitraRecord)
      ..add(const StudentBlockToggled())
      ..add(const StudentBlockToggled());
    await bloc.stream.firstWhere((state) => state is StudentBlockIdle);
    verify(() => students.block('p3')).called(1);
    await bloc.close();
  });
}
