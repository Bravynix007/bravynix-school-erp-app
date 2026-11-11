import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/document_upload_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/files.dart';
import '../../helpers/pump_app.dart';

class _MockUploadBloc extends MockBloc<FileUploadEvent, FileUploadState> implements FileUploadBloc;

void main() {
  late _MockUploadBloc bloc;
  late List<String?> changes;
  setUpAll(() => registerFallbackValue(FileUploadStarted(pdf)));
  setUp(() {
    bloc = _MockUploadBloc();
    changes = [];
  });

  Future<void> pump(
    WidgetTester tester,
    FileUploadState state, {
    FilePicking? picking,
    Stream<FileUploadState>? later,
    double textScale = 1,
  }) {
    if (later == null) {
      when(() => bloc.state).thenReturn(state);
    } else {
      whenListen(bloc, later, initialState: state);
    }
    return tester.pumpAppScaled(
      Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<FileUploadBloc>.value(
            value: bloc,
            child: DocumentUploadField(picking: picking ?? FakeFilePicking(), onChanged: changes.add),
          ),
        ),
      ),
      textScale: textScale,
      size: const Size(400, 800),
    );
  }

  AppButton button(WidgetTester tester, String key) => tester.widget<AppButton>(find.byKey(Key(key)));

  testWidgets('an empty field says what it takes and offers to choose a file', (tester) async {
    await pump(tester, const FileUploadIdle());
    expect(find.text('PDF, JPG, PNG or WebP, up to 5 MB.'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.byKey(const Key('document.remove')), findsNothing);
    expect(find.byType(InlineMessage), findsNothing);
  });

  testWidgets('hands the file the phone gives to the bloc', (tester) async {
    final picking = FakeFilePicking(result: pdf);
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.byKey(const Key('document.pick')));
    await tester.pumpAndSettle();
    expect(picking.documents, 1);
    verify(() => bloc.add(FileUploadStarted(pdf))).called(1);
  });

  testWidgets('does nothing when the person backs out of the file browser', (tester) async {
    final picking = FakeFilePicking();
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.byKey(const Key('document.pick')));
    await tester.pumpAndSettle();
    expect(picking.documents, 1);
    verifyNever(() => bloc.add(any()));
    expect(find.byType(InlineMessage), findsNothing);
  });

  testWidgets('says why the phone would not open its files, until the next try', (tester) async {
    final picking = FakeFilePicking(failure: const FilePickFailure(null));
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.byKey(const Key('document.pick')));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't open your files. Try again."), findsOneWidget);
    picking
      ..failure = null
      ..result = pdf;
    await tester.tap(find.byKey(const Key('document.pick')));
    await tester.pumpAndSettle();
    expect(find.byType(InlineMessage), findsNothing);
  });

  testWidgets('shows the file with its size and its progress while it goes, and does not let it be changed', (
    tester,
  ) async {
    await pump(tester, FileUploadSending(pdf, sent: 0.4));
    expect(find.text('letter.pdf · 908 B'), findsOneWidget);
    expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value, 0.4);
    expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).semanticLabel, 'Uploading file');
    expect(button(tester, 'document.pick').onPressed, isNull);
    expect(button(tester, 'document.remove').onPressed, isNull);
  });

  testWidgets('shows a sent file with Change and Remove, and Remove empties the field', (tester) async {
    await pump(tester, FileUploadDone(pdf, uploadedPdf));
    expect(find.text('Change file'), findsOneWidget);
    expect(find.byType(AppProgressBar), findsNothing);
    await tester.tap(find.byKey(const Key('document.remove')));
    verify(() => bloc.add(const FileUploadCleared())).called(1);
  });

  testWidgets('says what went wrong and sends the same file again on Try again', (tester) async {
    await pump(tester, FileUploadFailed(pdf, failure: const ApiFailure.network()));
    expect(find.text('letter.pdf · 908 B'), findsOneWidget);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const FileUploadRetried())).called(1);
  });

  testWidgets(
    'says in the words of the code why a file that would be refused again was, with no way to send it again',
    (
      tester,
    ) async {
      await pump(
        tester,
        FileUploadFailed(
          pdf,
          failure: const ApiFailure(statusCode: 413, code: 'FILE_TOO_LARGE', message: 'server words'),
        ),
      );
      expect(find.text('This file is larger than 5 MB. Choose a smaller one.'), findsOneWidget);
      expect(find.text('server words'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.byKey(const Key('document.chosen')), findsNothing);
      expect(find.text('Choose a file'), findsOneWidget);
    },
  );

  testWidgets('a file the app refused shows why, with no way to send it again', (tester) async {
    await pump(tester, FileUploadFailed(pdf, problem: FileProblem.typeNotAllowed));
    expect(find.byKey(const Key('document.refused')), findsOneWidget);
    expect(find.text("This kind of file can't be used here. Choose a different one."), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('does not start an upload for a file picked after the screen went', (tester) async {
    final picking = _SlowPicking();
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.byKey(const Key('document.pick')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    picking.pick.complete(pdf);
    await tester.pump();
    verifyNever(() => bloc.add(any()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tells the form the file ID when the file is sent, and null when it is replaced or removed', (
    tester,
  ) async {
    await pump(
      tester,
      const FileUploadIdle(),
      later: Stream.fromIterable([
        FileUploadSending(pdf),
        FileUploadDone(pdf, uploadedPdf),
        FileUploadSending(pdf),
        const FileUploadIdle(),
      ]),
    );
    await tester.pump();
    expect(changes, ['f9', null]);
  });

  testWidgets('fits at the largest text size on a narrow phone', (tester) async {
    for (final state in [
      const FileUploadIdle(),
      FileUploadSending(pdf, sent: 0.5),
      FileUploadDone(pdf, uploadedPdf),
      FileUploadFailed(pdf, failure: const ApiFailure.network()),
      FileUploadFailed(pdf, problem: FileProblem.tooLarge),
    ]) {
      await pump(tester, state, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester), isEmpty);
    }
  });
}

/// A picker that answers when the test says, so the screen can go first.
class _SlowPicking extends FakeFilePicking {
  final pick = Completer<ChosenFile?>();

  @override
  Future<ChosenFile?> document() => pick.future;
}
