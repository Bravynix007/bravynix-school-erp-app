import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_import_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_import_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/files.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/students.dart';

class _MockImportBloc extends MockBloc<StudentImportEvent, StudentImportState> implements StudentImportBloc;

class _MockUploadBloc extends MockBloc<FileUploadEvent, FileUploadState> implements FileUploadBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

const List<AcademicYear> _years = [currentYear, earlierYear];
const _form = StudentImportReady(years: _years, yearId: 'y1');
const _filled = StudentImportReady(years: _years, yearId: 'y1', fileId: 'f1');

void main() {
  late _MockImportBloc bloc;
  late _MockUploadBloc upload;
  late FakeFilePicking picking;

  setUpAll(() {
    registerFallbackValue(const StudentImportStarted());
    registerFallbackValue(const FileUploadCleared());
  });
  setUp(() {
    bloc = _MockImportBloc();
    upload = _MockUploadBloc();
    picking = FakeFilePicking();
    when(() => upload.state).thenReturn(const FileUploadIdle());
  });

  Widget screen() => MultiBlocProvider(
    providers: [
      BlocProvider<StudentImportBloc>.value(value: bloc),
      BlocProvider<FileUploadBloc>.value(value: upload),
    ],
    child: StudentImportView(picking: picking),
  );

  Future<void> pump(
    WidgetTester tester,
    StudentImportState state, {
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(screen(), textScale: textScale, size: size);
  }

  Finder startButton() => find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton));

  group('before the form is ready', () {
    testWidgets('shows a placeholder while the years load', (tester) async {
      await pump(tester, const StudentImportLoading());
      expect(find.text('Import students'), findsOneWidget);
      expect(find.byKey(const Key('import.failed')), findsNothing);
    });

    testWidgets('says why the years could not be read, and starts again on Try again', (tester) async {
      await pump(tester, StudentImportFailed(_failure(503, 'UNAVAILABLE')));
      expect(find.byKey(const Key('import.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StudentImportStarted())).called(1);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, StudentImportFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('import.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('the form', () {
    testWidgets('names the columns, takes a CSV file and shows the current year', (tester) async {
      await pump(tester, _form);
      expect(
        find.text('Name,RollNumber,Class,Section,GuardianName,GuardianPhone,GuardianEmail'),
        findsOneWidget,
      );
      expect(find.text('A CSV file, up to 5 MB.'), findsOneWidget);
      expect(find.text('2026-2027'), findsOneWidget);
    });

    testWidgets('cannot start until a file went up', (tester) async {
      await pump(tester, _form);
      expect(tester.widget<FilledButton>(startButton()).onPressed, isNull);
    });

    testWidgets('starts the import once a file went up', (tester) async {
      await pump(tester, _filled);
      await tester.tap(startButton());
      verify(() => bloc.add(const StudentImportSubmitted())).called(1);
    });

    testWidgets('waits while the import is being started', (tester) async {
      await pump(tester, _filled.copyWith(starting: true));
      expect(tester.widget<FilledButton>(startButton()).onPressed, isNull);
    });

    testWidgets('asks for the sample file', (tester) async {
      await pump(tester, _form);
      await tester.tap(find.byKey(const Key('import.showSample')));
      verify(() => bloc.add(const StudentImportSampleRequested())).called(1);
    });

    testWidgets('shows the sample file in place of the button once it is read', (tester) async {
      await pump(tester, _form.copyWith(sample: 'Name,RollNumber\r\nAsha Rao,14'));
      expect(find.byKey(const Key('import.showSample')), findsNothing);
      expect(find.byKey(const Key('import.sample')), findsOneWidget);
    });

    testWidgets('says when the sample could not be read, and keeps the button', (tester) async {
      await pump(tester, _form.copyWith(sampleFailure: () => _failure(503, 'UNAVAILABLE')));
      expect(find.byKey(const Key('import.sampleError')), findsOneWidget);
      expect(find.byKey(const Key('import.showSample')), findsOneWidget);
    });

    testWidgets('chooses another year', (tester) async {
      await pump(tester, _form);
      await tester.tap(find.byKey(const Key('import.year')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025-2026').last);
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StudentImportYearChosen('y0'))).called(1);
    });

    for (final (status, code, words) in [
      (
        409,
        'IMPORT_ALREADY_RUNNING',
        'Another import of this school is still running. Try again when it has finished.',
      ),
      (422, 'FILE_NOT_READY', 'The file is not ready. Choose it again.'),
      (422, 'YEAR_NOT_ACTIVE', 'This academic year is not active.'),
      (404, 'NOT_FOUND', 'The file or the academic year could not be found.'),
    ]) {
      testWidgets('says why an import was refused with $code', (tester) async {
        await pump(tester, _filled.copyWith(failure: () => _failure(status, code)));
        expect(find.descendant(of: find.byKey(const Key('import.error')), matching: find.text(words)), findsOneWidget);
      });
    }

    testWidgets('hands the file that went up to the import, and lets it go when the file is removed', (tester) async {
      whenListen(
        upload,
        Stream.fromIterable([
          FileUploadDone(csvFile, const UploadedFile(id: 'f1', contentType: 'text/csv', sizeBytes: 60)),
          const FileUploadIdle(),
        ]),
        initialState: const FileUploadIdle(),
      );
      await pump(tester, _form);
      await tester.pump();
      verifyInOrder([
        () => bloc.add(const StudentImportFileChosen('f1')),
        () => bloc.add(const StudentImportFileChosen(null)),
      ]);
    });

    testWidgets('picks a CSV file from the phone', (tester) async {
      picking.result = csvFile;
      await pump(tester, _form);
      await tester.tap(find.byKey(const Key('document.pick')));
      await tester.pumpAndSettle();
      expect([picking.csvs, picking.documents], [1, 0]);
      verify(() => upload.add(FileUploadStarted(csvFile))).called(1);
    });
  });

  group('while the import goes', () {
    testWidgets('says it is waiting before the rows are counted', (tester) async {
      await pump(tester, const StudentImportRunning('m1'));
      expect(find.text('Waiting for the import to start.'), findsOneWidget);
      expect(find.byType(AppProgressBar), findsNothing);
    });

    testWidgets('says how many rows are done, with a bar', (tester) async {
      await pump(tester, StudentImportRunning('m1', importRunning(processed: 4)));
      expect(find.text('4 of 10 rows done'), findsOneWidget);
      expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value, 0.4);
      expect(find.textContaining('You can leave this screen'), findsOneWidget);
    });

    testWidgets('offers Check again when the connection was lost, and keeps the last count', (tester) async {
      await pump(tester, StudentImportLost('m1', const ApiFailure.network(), importRunning(processed: 4)));
      expect(find.text('4 of 10 rows done'), findsOneWidget);
      expect(find.byKey(const Key('import.lost')), findsOneWidget);
      await tester.tap(find.text('Check again'));
      verify(() => bloc.add(const StudentImportChecked())).called(1);
    });
  });

  group('when it is done', () {
    testWidgets('says how many students came in, how many rows were skipped, and which', (tester) async {
      await pump(tester, const StudentImportFinished(importDone));
      expect(find.text('Import finished'), findsOneWidget);
      expect(find.text('8 students imported, 2 rows skipped'), findsOneWidget);
      expect(find.text('Row 4: The roll number is already taken.'), findsOneWidget);
      expect(find.text('Row 9: The class was not found.'), findsOneWidget);
      expect(find.byKey(const Key('import.more')), findsNothing);
    });

    testWidgets('warns when a section is now over its capacity', (tester) async {
      await pump(tester, const StudentImportFinished(importDone));
      expect(find.byKey(const Key('import.overCapacity')), findsOneWidget);
    });

    testWidgets('has no warning and no list when every row came in', (tester) async {
      await pump(
        tester,
        const StudentImportFinished(
          StudentImport(
            id: 'm',
            status: ImportStatus.done,
            totalRows: 1,
            processedRows: 1,
            importedRows: 1,
            skippedRows: 0,
            overCapacity: false,
          ),
        ),
      );
      expect(find.byKey(const Key('import.overCapacity')), findsNothing);
      expect(find.text('1 student imported, 0 rows skipped'), findsOneWidget);
      expect(find.text('Rows that were skipped'), findsNothing);
    });

    testWidgets('says when only the first skipped rows are listed', (tester) async {
      await pump(
        tester,
        const StudentImportFinished(
          StudentImport(
            id: 'm',
            status: ImportStatus.done,
            totalRows: 1500,
            processedRows: 1500,
            importedRows: 0,
            skippedRows: 1500,
            overCapacity: false,
            rowErrors: [ImportRowError(row: 2, message: 'The class was not found.')],
          ),
        ),
      );
      expect(find.text('Showing the first 1 of 1500 skipped rows.'), findsOneWidget);
    });

    for (final (code, words) in [
      ('CSV_HEADER_INVALID', 'The first row of the file is not the columns above. Fix it and choose the file again.'),
      (
        'CSV_TOO_LARGE',
        'The file has more than 5,000 students. Split it into parts and import them one after the other.',
      ),
      ('CSV_UNREADABLE', 'The file could not be read. Save it as a CSV file in UTF-8 and choose it again.'),
      (
        'IMPORT_FAILED',
        'The import stopped because of a problem on our side. Check the students list, then try again.',
      ),
    ]) {
      testWidgets('says why an import that read no row could not run, with $code', (tester) async {
        await pump(
          tester,
          StudentImportFinished(
            StudentImport(
              id: 'm',
              status: ImportStatus.failed,
              processedRows: 0,
              importedRows: 0,
              skippedRows: 0,
              overCapacity: false,
              errorCode: code,
            ),
          ),
        );
        expect(find.text('The import could not run'), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.textContaining('imported'), findsNothing);
      });
    }

    /// Opens the screen from a list, taps what [close] finds, and answers what the list gets back.
    Future<bool?> closedBy(WidgetTester tester, StudentImportState state, Finder Function() close) async {
      when(() => bloc.state).thenReturn(state);
      bool? result;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await context.push<bool>('/import'),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(path: '/import', builder: (_, _) => screen()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(close());
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('closes with true from Done, so the list reads again', (tester) async {
      expect(await closedBy(tester, const StudentImportFinished(importDone), () => find.text('Done')), isTrue);
    });

    testWidgets('closes with true from the back arrow while the import goes, as it carries on', (tester) async {
      expect(await closedBy(tester, const StudentImportRunning('m1'), () => find.byTooltip('Back')), isTrue);
    });

    testWidgets('closes with false from the back arrow of the form, as nothing was started', (tester) async {
      expect(await closedBy(tester, _form, () => find.byTooltip('Back')), isFalse);
    });
  });

  group('at a large text scale on a small phone', () {
    for (final (name, state) in <(String, StudentImportState)>[
      ('the form', _filled.copyWith(failure: () => _failure(409, 'IMPORT_ALREADY_RUNNING'), sample: 'Name,RollNumber')),
      ('the progress', StudentImportLost('m1', const ApiFailure.network(), importRunning(processed: 4))),
      ('the result', const StudentImportFinished(importDone)),
    ]) {
      testWidgets('$name reads whole', (tester) async {
        await pump(tester, state, textScale: 2, size: const Size(320, 3000));
        expect(tester.takeException(), isNull);
        // The column names are one word, and wider than any box at this size.
        expect(clippedParagraphs(tester, unbreakable: 196), isEmpty);
        expect(find.byType(InlineMessage), state is StudentImportFinished ? findsOneWidget : findsWidgets);
      });
    }
  });
}
