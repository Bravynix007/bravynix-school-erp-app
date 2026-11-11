import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_documents_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_documents_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/documents.dart';
import '../../helpers/files.dart';
import '../../helpers/pump_app.dart';

class _MockDocumentsBloc extends MockBloc<StaffDocumentsEvent, StaffDocumentsState> implements StaffDocumentsBloc;

class _MockUploadBloc extends MockBloc<FileUploadEvent, FileUploadState> implements FileUploadBloc;

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late _MockDocumentsBloc bloc;
  late _MockUploadBloc upload;

  setUpAll(() {
    registerFallbackValue(const StaffDocumentsStarted());
    registerFallbackValue(const FileUploadCleared());
  });
  setUp(() {
    bloc = _MockDocumentsBloc();
    upload = _MockUploadBloc();
    when(() => upload.state).thenReturn(const FileUploadIdle());
  });

  final ready = StaffDocumentsReady(documents: [appointmentLetter, degreeCertificate]);

  Future<void> pump(
    WidgetTester tester,
    StaffDocumentsState state, {
    Stream<StaffDocumentsState>? later,
    double textScale = 1,
    Size size = const Size(400, 1800),
  }) {
    if (later == null) {
      when(() => bloc.state).thenReturn(state);
    } else {
      whenListen(bloc, later, initialState: state);
    }
    return tester.pumpAppScaled(
      MultiBlocProvider(
        providers: [
          BlocProvider<StaffDocumentsBloc>.value(value: bloc),
          BlocProvider<FileUploadBloc>.value(value: upload),
        ],
        child: Scaffold(body: StaffDocumentsView(picking: FakeFilePicking())),
      ),
      textScale: textScale,
      size: size,
    );
  }

  /// Pumps again with another state: the bloc builder reads its state once, so the tree is emptied first.
  Future<void> pumpAgain(WidgetTester tester, StaffDocumentsState state) async {
    await tester.pumpWidget(const SizedBox());
    await pump(tester, state);
  }

  AppButton button(WidgetTester tester, String key) => tester.widget<AppButton>(find.byKey(Key(key)));

  group('the list', () {
    testWidgets('shows each document with its file, its size and the day it was added', (tester) async {
      await pump(tester, ready);
      for (final text in [
        'Appointment letter',
        'letter.pdf · 912 B',
        'Added 10-11-2026',
        'B.Ed certificate',
        'bed.jpg · 1.2 MB',
        'Added 09-11-2026',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byKey(const Key('staffDocuments.none')), findsNothing);
    });

    testWidgets('names the day in India, where a late evening in UTC is already the next day', (tester) async {
      final late = StaffDocumentsReady(
        documents: [
          Document(
            id: 'o1',
            title: 'Appointment letter',
            file: appointmentLetter.file,
            createdAt: DateTime.utc(2026, 11, 10, 20),
          ),
        ],
      );
      await pump(tester, late);
      expect(find.text('Added 11-11-2026'), findsOneWidget);
    });

    testWidgets('says there are none', (tester) async {
      await pump(tester, const StaffDocumentsReady(documents: []));
      expect(find.byKey(const Key('staffDocuments.none')), findsOneWidget);
      expect(find.text('No documents yet.'), findsOneWidget);
    });

    testWidgets('opens a document, and asks first before it removes one', (tester) async {
      await pump(tester, ready);
      await tester.tap(find.byKey(const Key('staffDocuments.open.o1')));
      verify(() => bloc.add(const StaffDocumentsOpened('o1'))).called(1);
      await tester.tap(find.byKey(const Key('staffDocuments.remove.o1')));
      await tester.pumpAndSettle();
      expect(find.text('Remove Appointment letter?'), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(find.descendant(of: find.byType(AlertDialog), matching: find.byType(AppButton)).last)
            .variant,
        AppButtonVariant.danger,
      );
      verifyNever(() => bloc.add(const StaffDocumentsRemoved('o1')));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const StaffDocumentsRemoved('o1')));
      await tester.tap(find.byKey(const Key('staffDocuments.remove.o1')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      verify(() => bloc.add(const StaffDocumentsRemoved('o1'))).called(1);
    });

    testWidgets('shows which document is on its way, and holds the buttons meanwhile', (tester) async {
      await pump(tester, StaffDocumentsReady(documents: [appointmentLetter, degreeCertificate], opening: 'o1'));
      expect(button(tester, 'staffDocuments.open.o1').loading, isTrue);
      expect(button(tester, 'staffDocuments.open.o2').loading, isFalse);
      for (final key in ['staffDocuments.open.o1', 'staffDocuments.open.o2', 'staffDocuments.remove.o1']) {
        expect(button(tester, key).onPressed, isNull, reason: key);
      }
      await pumpAgain(tester, StaffDocumentsReady(documents: [appointmentLetter], removing: 'o1'));
      expect(button(tester, 'staffDocuments.remove.o1').loading, isTrue);
    });
  });

  group('adding', () {
    testWidgets('keeps Add document for a title and a file', (tester) async {
      await pump(tester, ready);
      expect(button(tester, 'staffDocuments.attach').onPressed, isNull);
      await pumpAgain(tester, const StaffDocumentsReady(documents: [], title: 'Letter', fileId: 'fl1'));
      expect(button(tester, 'staffDocuments.attach').onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('staffDocuments.attach')));
      verify(() => bloc.add(const StaffDocumentsAttached())).called(1);
    });

    testWidgets('tells the bloc the title as it is typed, and the file once it is uploaded or taken away', (
      tester,
    ) async {
      whenListen(
        upload,
        Stream.fromIterable([FileUploadDone(pdf, uploadedPdf), const FileUploadIdle()]),
        initialState: const FileUploadIdle(),
      );
      await pump(tester, ready);
      await tester.enterText(find.byKey(const Key('staffDocuments.title')), 'Letter');
      verify(() => bloc.add(const StaffDocumentsTitleChanged('Letter'))).called(1);
      await tester.pump();
      verify(() => bloc.add(const StaffDocumentsFileChosen('f9'))).called(1);
      verify(() => bloc.add(const StaffDocumentsFileChosen(null))).called(1);
    });

    testWidgets('starts the title from the one the bloc kept, which another tab may have left half written', (
      tester,
    ) async {
      await pump(tester, const StaffDocumentsReady(documents: [], title: 'Half writ'));
      expect(find.text('Half writ'), findsOneWidget);
    });

    testWidgets('shows progress and holds the title while it goes', (tester) async {
      await pump(tester, const StaffDocumentsReady(documents: [], title: 'Letter', fileId: 'fl1', attaching: true));
      expect(button(tester, 'staffDocuments.attach').loading, isTrue);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('empties the title and the upload once the document is added, and says so', (tester) async {
      const adding = StaffDocumentsReady(documents: [], title: 'Appointment letter', fileId: 'fl1', attaching: true);
      await pump(
        tester,
        adding,
        later: Stream.value(
          StaffDocumentsReady(
            documents: [appointmentLetter],
            done: StaffDocumentChange(appointmentLetter, removed: false),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Appointment letter added'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
      verify(() => upload.add(const FileUploadCleared())).called(1);
    });

    testWidgets('says a removal is done, and leaves the upload alone', (tester) async {
      await pump(
        tester,
        ready,
        later: Stream.value(
          StaffDocumentsReady(
            documents: [degreeCertificate],
            done: StaffDocumentChange(appointmentLetter, removed: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Appointment letter removed'), findsOneWidget);
      verifyNever(() => upload.add(any()));
    });
  });

  group('what was refused', () {
    for (final (failure, words) in [
      (_failure(409, 'DUPLICATE'), 'This file is attached already.'),
      (_failure(400, 'INVALID_VALUE'), 'This file cannot be attached. Remove it and choose it again.'),
      (
        _failure(404, 'NOT_FOUND'),
        'The document, the file or the staff member could not be found. It may have been removed.',
      ),
      (_failure(403, 'FORBIDDEN'), "You don't have access to this."),
      (const ApiFailure.network(), "Can't reach the server. Check your connection and try again."),
    ]) {
      testWidgets('says ${failure.code} above the form', (tester) async {
        await pump(tester, StaffDocumentsReady(documents: [appointmentLetter], failure: failure));
        expect(find.byKey(const Key('staffDocuments.error')), findsOneWidget);
        expect(find.text(words), findsOneWidget);
        expect(find.text('server words'), findsNothing);
      });
    }

    testWidgets('says the phone could not open the file', (tester) async {
      await pump(tester, StaffDocumentsReady(documents: [appointmentLetter], phoneRefused: true));
      expect(find.text('This phone could not open the file.'), findsOneWidget);
    });
  });

  group('before the list is ready', () {
    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const StaffDocumentsLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.byKey(const Key('staffDocuments.attach')), findsNothing);
    });

    testWidgets('says why it could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StaffDocumentsFailed(ApiFailure.network()));
      expect(find.byKey(const Key('staffDocuments.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StaffDocumentsStarted())).called(1);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      StaffDocumentsReady(
        documents: [appointmentLetter, degreeCertificate],
        title: 'Appointment letter',
        fileId: 'fl1',
        failure: _failure(409, 'DUPLICATE'),
        phoneRefused: true,
      ),
      textScale: 2,
      size: const Size(320, 4000),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
