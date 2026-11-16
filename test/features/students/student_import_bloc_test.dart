import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_import_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/mocks.dart';
import '../../helpers/students.dart';

const _down = ApiFailure(statusCode: 503, code: 'UNAVAILABLE', message: 'x');
const _running = ApiFailure(statusCode: 409, code: 'IMPORT_ALREADY_RUNNING', message: 'x');
const _keyBusy = ApiFailure(statusCode: 409, code: 'IDEMPOTENCY_IN_PROGRESS', message: 'x');
const _busyLater = ApiFailure(
  statusCode: 409,
  code: 'IMPORT_ALREADY_RUNNING',
  message: 'x',
  retryAfter: Duration(seconds: 5),
);

const _ready = StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1');
const _filled = StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', fileId: 'f1');

void main() {
  late MockAcademicYearsRepository years;
  late MockStudentImportsRepository imports;
  late List<Duration> pauses;
  late int keys;
  late Future<void> Function(Duration) pause;

  setUp(() {
    years = MockAcademicYearsRepository();
    imports = MockStudentImportsRepository();
    pauses = [];
    keys = 0;
    pause = (duration) async => pauses.add(duration);
    when(() => years.years('i1')).thenAnswer((_) async => [currentYear, earlierYear]);
  });

  StudentImportBloc build() => StudentImportBloc(
    years,
    imports,
    'i1',
    newKey: () => 'key-${++keys}',
    pause: (duration) => pause(duration),
  );

  void startsAs(String id) => when(
    () => imports.start(
      institutionId: 'i1',
      fileId: 'f1',
      academicYearId: any(named: 'academicYearId'),
      idempotencyKey: any(named: 'idempotencyKey'),
    ),
  ).thenAnswer((_) async => id);

  Future<StudentImportBloc> filled() async {
    final bloc = build()..add(const StudentImportStarted());
    await bloc.stream.firstWhere((state) => state is StudentImportReady);
    bloc.add(const StudentImportFileChosen('f1'));
    await bloc.stream.firstWhere((state) => state is StudentImportReady && state.fileId != null);
    return bloc;
  }

  group('opening', () {
    blocTest<StudentImportBloc, StudentImportState>(
      'offers the years, with the current one chosen',
      build: build,
      act: (bloc) => bloc.add(const StudentImportStarted()),
      expect: () => [const StudentImportLoading(), _ready],
    );

    blocTest<StudentImportBloc, StudentImportState>(
      'chooses no year when none is current',
      setUp: () => when(() => years.years('i1')).thenAnswer((_) async => [earlierYear]),
      build: build,
      act: (bloc) => bloc.add(const StudentImportStarted()),
      expect: () => [
        const StudentImportLoading(),
        const StudentImportReady(years: [earlierYear]),
      ],
    );

    blocTest<StudentImportBloc, StudentImportState>(
      'says the years could not be read, and reads them again on a second start',
      setUp: () => when(() => years.years('i1')).thenThrow(_down),
      build: build,
      act: (bloc) async {
        bloc.add(const StudentImportStarted());
        await Future<void>.delayed(Duration.zero);
        when(() => years.years('i1')).thenAnswer((_) async => [currentYear]);
        bloc.add(const StudentImportStarted());
      },
      expect: () => [
        const StudentImportLoading(),
        const StudentImportFailed(_down),
        const StudentImportLoading(),
        const StudentImportReady(years: [currentYear], yearId: 'y1'),
      ],
    );
  });

  group('the form', () {
    blocTest<StudentImportBloc, StudentImportState>(
      'cannot start before a file went up, and can after',
      build: build,
      act: (bloc) async {
        bloc.add(const StudentImportStarted());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const StudentImportSubmitted())
          ..add(const StudentImportFileChosen('f1'));
      },
      verify: (bloc) {
        verifyNever(
          () => imports.start(
            institutionId: any(named: 'institutionId'),
            fileId: any(named: 'fileId'),
            academicYearId: any(named: 'academicYearId'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        );
        expect((bloc.state as StudentImportReady).canStart, isTrue);
      },
    );

    blocTest<StudentImportBloc, StudentImportState>(
      'takes the year the person chooses, and forgets a file that was removed',
      build: build,
      act: (bloc) async {
        bloc.add(const StudentImportStarted());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const StudentImportFileChosen('f1'))
          ..add(const StudentImportYearChosen('y0'))
          ..add(const StudentImportFileChosen(null));
      },
      skip: 2,
      expect: () => [
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', fileId: 'f1'),
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y0', fileId: 'f1'),
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y0'),
      ],
    );

    blocTest<StudentImportBloc, StudentImportState>(
      'shows the sample file once, and says when it could not be read',
      setUp: () {
        var asked = 0;
        when(() => imports.template()).thenAnswer((_) async {
          if (asked++ == 0) throw _down;
          return 'Name,RollNumber\n';
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const StudentImportStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudentImportSampleRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudentImportSampleRequested());
      },
      skip: 2,
      expect: () => [
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', sampleLoading: true),
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', sampleFailure: _down),
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', sampleLoading: true),
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', sample: 'Name,RollNumber\n'),
      ],
    );
  });

  group('starting', () {
    test('sends the file and the year, with an Idempotency-Key, and follows the import until it is settled', () async {
      startsAs('m1');
      final runs = [importRunning(), importRunning(processed: 4), importDone];
      when(() => imports.status('m1')).thenAnswer((_) async => runs.removeAt(0));
      final bloc = await filled();
      final seen = <StudentImportState>[];
      final sub = bloc.stream.listen(seen.add);
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportFinished);
      await sub.cancel();
      expect(seen, [
        const StudentImportReady(years: [currentYear, earlierYear], yearId: 'y1', fileId: 'f1', starting: true),
        const StudentImportRunning('m1'),
        StudentImportRunning('m1', importRunning()),
        StudentImportRunning('m1', importRunning(processed: 4)),
        const StudentImportFinished(importDone),
      ]);
      verify(
        () => imports.start(institutionId: 'i1', fileId: 'f1', academicYearId: 'y1', idempotencyKey: 'key-1'),
      ).called(1);
      // The server asked to be looked at every 2 seconds.
      expect(pauses, [const Duration(seconds: 2), const Duration(seconds: 2)]);
    });

    test('looks every 2 seconds for the first 30, then every 5', () async {
      startsAs('m1');
      var looks = 0;
      when(() => imports.status('m1')).thenAnswer((_) async => ++looks > 17 ? importDone : importRunning(processed: 1));
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportFinished);
      expect(pauses, [
        for (var i = 0; i < 15; i++) const Duration(seconds: 2),
        const Duration(seconds: 5),
        const Duration(seconds: 5),
      ]);
    });

    test('finishes with the reason when the worker read no row', () async {
      startsAs('m1');
      when(() => imports.status('m1')).thenAnswer((_) async => importRefused);
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      expect(
        await bloc.stream.firstWhere((state) => state is StudentImportFinished),
        const StudentImportFinished(importRefused),
      );
    });

    blocTest<StudentImportBloc, StudentImportState>(
      'keeps the form, with why, when the import is refused, and a second try is a new attempt (a new key)',
      setUp: () => when(
        () => imports.start(
          institutionId: any(named: 'institutionId'),
          fileId: any(named: 'fileId'),
          academicYearId: any(named: 'academicYearId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(_running),
      seed: () => _filled,
      build: build,
      act: (bloc) async {
        bloc.add(const StudentImportSubmitted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudentImportSubmitted());
      },
      expect: () => [
        _filled.copyWith(starting: true),
        _filled.copyWith(failure: () => _running),
        _filled.copyWith(starting: true),
        _filled.copyWith(failure: () => _running),
      ],
      verify: (_) => expect(
        verify(
          () => imports.start(
            institutionId: any(named: 'institutionId'),
            fileId: any(named: 'fileId'),
            academicYearId: any(named: 'academicYearId'),
            idempotencyKey: captureAny(named: 'idempotencyKey'),
          ),
        ).captured,
        ['key-1', 'key-2'],
      ),
    );

    blocTest<StudentImportBloc, StudentImportState>(
      'a changed year is a new attempt, with a new key',
      setUp: () => when(
        () => imports.start(
          institutionId: any(named: 'institutionId'),
          fileId: any(named: 'fileId'),
          academicYearId: any(named: 'academicYearId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenThrow(_running),
      seed: () => _filled,
      build: build,
      act: (bloc) async {
        bloc.add(const StudentImportSubmitted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudentImportYearChosen('y0'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const StudentImportSubmitted());
      },
      verify: (_) {
        verify(
          () => imports.start(institutionId: 'i1', fileId: 'f1', academicYearId: 'y1', idempotencyKey: 'key-1'),
        ).called(1);
        verify(
          () => imports.start(institutionId: 'i1', fileId: 'f1', academicYearId: 'y0', idempotencyKey: 'key-2'),
        ).called(1);
      },
    );

    // The server keeps no answer for these (no answer, 5xx, a key still being worked on, a refusal to retry later), so
    // a repeat must carry the same key to find an import that did start.
    for (final (name, failure) in <(String, ApiFailure)>[
      ('a 503', _down),
      ('an IDEMPOTENCY_IN_PROGRESS 409', _keyBusy),
      ('a 409 with a retry time', _busyLater),
    ]) {
      blocTest<StudentImportBloc, StudentImportState>(
        'a try after $name is the same attempt, with the same key',
        setUp: () => when(
          () => imports.start(
            institutionId: any(named: 'institutionId'),
            fileId: any(named: 'fileId'),
            academicYearId: any(named: 'academicYearId'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).thenThrow(failure),
        seed: () => _filled,
        build: build,
        act: (bloc) async {
          bloc.add(const StudentImportSubmitted());
          await Future<void>.delayed(Duration.zero);
          bloc.add(const StudentImportSubmitted());
        },
        verify: (_) => expect(
          verify(
            () => imports.start(
              institutionId: any(named: 'institutionId'),
              fileId: any(named: 'fileId'),
              academicYearId: any(named: 'academicYearId'),
              idempotencyKey: captureAny(named: 'idempotencyKey'),
            ),
          ).captured,
          ['key-1', 'key-1'],
        ),
      );
    }

    test('stops following when the screen goes', () async {
      startsAs('m1');
      final first = Completer<StudentImport>();
      var looks = 0;
      when(() => imports.status('m1')).thenAnswer((_) {
        looks++;
        return first.future;
      });
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportRunning);
      await bloc.close();
      first.complete(importRunning(processed: 1));
      await Future<void>.delayed(Duration.zero);
      expect(looks, 1);
      expect(pauses, isEmpty);
    });
  });

  group('when the connection is lost', () {
    test('keeps the last answer, and picks up again on Check again', () async {
      startsAs('m1');
      var looks = 0;
      when(() => imports.status('m1')).thenAnswer((_) async {
        looks++;
        if (looks == 2) throw _down;
        return looks == 1 ? importRunning(processed: 3) : importDone;
      });
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportLost);
      expect(bloc.state, StudentImportLost('m1', _down, importRunning(processed: 3)));
      bloc.add(const StudentImportChecked());
      expect(
        await bloc.stream.firstWhere((state) => state is StudentImportFinished),
        const StudentImportFinished(importDone),
      );
    });

    test('Check again does nothing while the import is being followed', () async {
      startsAs('m1');
      // The import never settles and the next look never comes, as when the worker is slow.
      pause = (_) => Completer<void>().future;
      when(() => imports.status('m1')).thenAnswer((_) async => importRunning(processed: 1));
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportRunning && state.run != null);
      bloc.add(const StudentImportChecked());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<StudentImportRunning>());
      await bloc.close();
    });
  });

  group('what a repeat or a missing choice does not do', () {
    test('does not start without a year, even with a file', () async {
      when(() => years.years('i1')).thenAnswer((_) async => [earlierYear]);
      final bloc = await filled();
      expect(bloc.state, isA<StudentImportReady>().having((ready) => ready.canStart, 'canStart', isFalse));
      bloc.add(const StudentImportSubmitted());
      await Future<void>.delayed(Duration.zero);
      verifyNever(
        () => imports.start(
          institutionId: any(named: 'institutionId'),
          fileId: any(named: 'fileId'),
          academicYearId: any(named: 'academicYearId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      );
      await bloc.close();
    });

    test('does not start a second import while the first is on its way', () async {
      final answer = Completer<String>();
      when(
        () => imports.start(
          institutionId: 'i1',
          fileId: 'f1',
          academicYearId: any(named: 'academicYearId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) => answer.future);
      final bloc = await filled();
      bloc
        ..add(const StudentImportSubmitted())
        ..add(const StudentImportSubmitted());
      await Future<void>.delayed(Duration.zero);
      verify(
        () => imports.start(
          institutionId: 'i1',
          fileId: 'f1',
          academicYearId: any(named: 'academicYearId'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      answer.complete('m1');
      when(() => imports.status('m1')).thenAnswer((_) async => importDone);
      await bloc.stream.firstWhere((state) => state is StudentImportFinished);
    });

    test('ignores a year or file chosen while the start is on its way, and keeps the key for the repeat', () async {
      final answer = Completer<String>();
      when(
        () => imports.start(
          institutionId: 'i1',
          fileId: 'f1',
          academicYearId: 'y1',
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) => answer.future);
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const StudentImportYearChosen('y0'))
        ..add(const StudentImportFileChosen('f2'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, _filled.copyWith(starting: true));

      answer.completeError(_down);
      await bloc.stream.firstWhere((state) => state is StudentImportReady && !state.starting);
      expect(bloc.state, _filled.copyWith(failure: () => _down));

      // The repeat is the same attempt, so it carries the same key and finds the first import.
      startsAs('m1');
      when(() => imports.status('m1')).thenAnswer((_) async => importDone);
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportFinished);
      verify(
        () => imports.start(
          institutionId: 'i1',
          fileId: 'f1',
          academicYearId: 'y1',
          idempotencyKey: 'key-1',
        ),
      ).called(2);
    });

    test('does not ask for the sample again while it is on its way', () async {
      final answer = Completer<String>();
      when(() => imports.template()).thenAnswer((_) => answer.future);
      final bloc = build()..add(const StudentImportStarted());
      await bloc.stream.firstWhere((state) => state is StudentImportReady);
      bloc
        ..add(const StudentImportSampleRequested())
        ..add(const StudentImportSampleRequested());
      await Future<void>.delayed(Duration.zero);
      verify(() => imports.template()).called(1);
      answer.complete('Name,RollNumber\n');
      await bloc.stream.firstWhere((state) => state is StudentImportReady && state.sample != null);
    });

    test('keeps the last answer through Check again, also when the next look is lost as well', () async {
      startsAs('m1');
      var looks = 0;
      when(() => imports.status('m1')).thenAnswer((_) async {
        looks++;
        if (looks == 1) return importRunning(processed: 3);
        throw _down;
      });
      final bloc = await filled();
      bloc.add(const StudentImportSubmitted());
      await bloc.stream.firstWhere((state) => state is StudentImportLost);
      final after = <StudentImportState>[];
      final seen = bloc.stream.listen(after.add);
      bloc.add(const StudentImportChecked());
      await bloc.stream.firstWhere((state) => state is StudentImportLost);
      await seen.cancel();
      expect(after, [
        StudentImportRunning('m1', importRunning(processed: 3)),
        StudentImportLost('m1', _down, importRunning(processed: 3)),
      ]);
    });
  });

  test('says how far an import is, once its rows are counted', () {
    expect(importRunning().progress, isNull);
    expect(importRunning(processed: 4).progress, 0.4);
    expect(
      const StudentImport(
        id: 'm',
        status: ImportStatus.done,
        totalRows: 0,
        processedRows: 0,
        importedRows: 0,
        skippedRows: 0,
        overCapacity: false,
      ).progress,
      1,
    );
    expect(ImportStatus.fromCode(5), isNull);
    expect(
      [
        for (final code in [1, 2, 3, 4]) ImportStatus.fromCode(code)!.isSettled,
      ],
      [false, false, true, true],
    );
  });
}
