import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/birth_certificate_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockStudentsRepository students;

  const held = 'BC/2019/4471';
  const refused = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');

  setUp(() => students = MockStudentsRepository());

  BirthCertificateBloc build({String? number = held}) =>
      BirthCertificateBloc(students, studentId: 'p1', number: number);

  group('saving a number', () {
    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'sends it and shows the number the API answers with',
      setUp: () => when(() => students.setBirthCertificate('p1', 'BC-2')).thenAnswer(
        (_) async => const IdentitySaved(StudentIdentity(birthCertificateNumber: 'BC-2')),
      ),
      build: build,
      act: (bloc) => bloc.add(const BirthCertificateSaved('BC-2')),
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.save),
        const BirthCertificateIdle('BC-2'),
      ],
    );

    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'keeps the number it had, and says why in the sheet, when it is refused',
      setUp: () => when(() => students.setBirthCertificate(any(), any())).thenThrow(refused),
      build: build,
      act: (bloc) => bloc.add(const BirthCertificateSaved('BC-2')),
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.save),
        const BirthCertificateRefused(held, BirthCertificateAction.save, refused, inSheet: true),
      ],
    );

    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'says the refusal on the card when the sheet was closed while it was on its way',
      setUp: () {
        final reply = Completer<IdentitySaved>();
        when(() => students.setBirthCertificate(any(), any())).thenAnswer((_) => reply.future);
        Timer(Duration.zero, () => reply.completeError(refused));
      },
      build: build,
      act: (bloc) => bloc
        ..add(const BirthCertificateSaved('BC-2'))
        ..add(const BirthCertificateHidden()),
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.save),
        const BirthCertificateRefused(held, BirthCertificateAction.save, refused, inSheet: false),
      ],
    );

    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'does nothing more while a call is on its way',
      setUp: () {
        final reply = Completer<IdentitySaved>();
        when(() => students.setBirthCertificate(any(), any())).thenAnswer((_) => reply.future);
        Timer(
          Duration.zero,
          () => reply.complete(const IdentitySaved(StudentIdentity(birthCertificateNumber: 'BC-2'))),
        );
      },
      build: build,
      act: (bloc) => bloc
        ..add(const BirthCertificateSaved('BC-2'))
        ..add(const BirthCertificateSaved('BC-3'))
        ..add(const BirthCertificateCleared()),
      verify: (_) => verify(() => students.setBirthCertificate('p1', any())).called(1),
    );
  });

  group('clearing the number', () {
    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'sends null and shows none',
      setUp: () => when(() => students.setBirthCertificate('p1', null)).thenAnswer(
        (_) async => const IdentitySaved(StudentIdentity()),
      ),
      build: build,
      act: (bloc) => bloc.add(const BirthCertificateCleared()),
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.clear),
        const BirthCertificateIdle(null),
      ],
    );

    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'keeps the number, and says why on the card, when it is refused',
      setUp: () => when(() => students.setBirthCertificate(any(), any())).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) => bloc.add(const BirthCertificateCleared()),
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.clear),
        const BirthCertificateRefused(held, BirthCertificateAction.clear, ApiFailure.network(), inSheet: false),
      ],
    );
  });

  group('closing the sheet', () {
    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'forgets a refusal, so the card does not repeat what the sheet said',
      setUp: () => when(() => students.setBirthCertificate(any(), any())).thenThrow(refused),
      build: build,
      act: (bloc) async {
        bloc.add(const BirthCertificateSaved('BC-2'));
        await bloc.stream.firstWhere((state) => state is BirthCertificateRefused);
        bloc.add(const BirthCertificateHidden());
      },
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.save),
        const BirthCertificateRefused(held, BirthCertificateAction.save, refused, inSheet: true),
        const BirthCertificateIdle(held),
      ],
    );

    blocTest<BirthCertificateBloc, BirthCertificateState>(
      'is a retry of a closed sheet that is shown again in the sheet',
      setUp: () => when(() => students.setBirthCertificate(any(), any())).thenThrow(refused),
      build: build,
      act: (bloc) async {
        bloc
          ..add(const BirthCertificateHidden())
          ..add(const BirthCertificateSaved('BC-2'));
      },
      expect: () => [
        const BirthCertificateWorking(held, BirthCertificateAction.save),
        const BirthCertificateRefused(held, BirthCertificateAction.save, refused, inSheet: true),
      ],
    );
  });
}
