import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_progress.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/presentation/bloc/file_upload_bloc.dart';
import 'package:bravynix_school_erp/features/files/presentation/view/photo_upload_field.dart';
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
  setUpAll(() => registerFallbackValue(FileUploadStarted(photo)));
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
            child: PhotoUploadField(
              picking: picking ?? FakeFilePicking(),
              imageLabel: 'Photo of Kavya',
              onChanged: changes.add,
            ),
          ),
        ),
      ),
      textScale: textScale,
      size: const Size(400, 800),
    );
  }

  testWidgets('an empty field offers to add a photo', (tester) async {
    await pump(tester, const FileUploadIdle());
    expect(find.text('Add photo'), findsOneWidget);
    expect(find.text('Change photo'), findsNothing);
    expect(find.byType(InlineMessage), findsNothing);
  });

  testWidgets('asks where the photo comes from, then hands the chosen photo to the bloc', (tester) async {
    final picking = FakeFilePicking(result: photo);
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    await tester.tap(find.byKey(const Key('photo.gallery')));
    await tester.pumpAndSettle();
    expect(picking.asked, [PhotoSource.gallery]);
    verify(() => bloc.add(FileUploadStarted(photo))).called(1);
  });

  testWidgets('takes a photo with the camera when that is chosen', (tester) async {
    final picking = FakeFilePicking(result: photo);
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.camera')));
    await tester.pumpAndSettle();
    expect(picking.asked, [PhotoSource.camera]);
  });

  testWidgets('does nothing when the sheet is closed, or when the person backs out of the camera', (tester) async {
    final picking = FakeFilePicking();
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(picking.asked, isEmpty);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.camera')));
    await tester.pumpAndSettle();
    expect(picking.asked, [PhotoSource.camera]);
    verifyNever(() => bloc.add(any()));
    expect(find.byType(InlineMessage), findsNothing);
  });

  testWidgets('says why the phone would not open the camera, the gallery or the files, until the next try', (
    tester,
  ) async {
    for (final (source, text) in [
      (PhotoSource.camera, "Couldn't open the camera. Allow it in Settings and try again."),
      (PhotoSource.gallery, "Couldn't open your photos. Allow it in Settings and try again."),
      (null, "Couldn't open your files. Try again."),
    ]) {
      final picking = FakeFilePicking(failure: FilePickFailure(source));
      await pump(tester, const FileUploadIdle(), picking: picking);
      await tester.tap(find.text('Add photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(source == PhotoSource.gallery ? 'photo.gallery' : 'photo.camera')));
      await tester.pumpAndSettle();
      if (source != null) expect(find.text(text), findsOneWidget);
    }
    // A pick that works clears the message.
    final picking = FakeFilePicking(failure: const FilePickFailure(PhotoSource.camera));
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.camera')));
    await tester.pumpAndSettle();
    expect(find.byType(InlineMessage), findsOneWidget);
    picking
      ..failure = null
      ..result = photo;
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.camera')));
    await tester.pumpAndSettle();
    expect(find.byType(InlineMessage), findsNothing);
  });

  testWidgets('shows the photo and its progress while it goes, and does not let it be changed meanwhile', (
    tester,
  ) async {
    await pump(tester, FileUploadSending(photo, sent: 0.4));
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).value, 0.4);
    expect(tester.widget<AppProgressBar>(find.byType(AppProgressBar)).semanticLabel, 'Uploading photo');
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Change photo')).onPressed, isNull);
    expect(find.text('Remove photo'), findsNothing);
  });

  testWidgets('shows a sent photo with Change and Remove, and Remove empties the field', (tester) async {
    await pump(tester, FileUploadDone(photo, uploadedPhoto));
    expect(find.text('Change photo'), findsOneWidget);
    await tester.tap(find.text('Remove photo'));
    verify(() => bloc.add(const FileUploadCleared())).called(1);
  });

  testWidgets('says what went wrong and sends the same photo again on Try again', (tester) async {
    await pump(tester, FileUploadFailed(photo, failure: const ApiFailure.network()));
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const FileUploadRetried())).called(1);
  });

  testWidgets('says in the words of the code why the server refused a photo that would be refused again', (
    tester,
  ) async {
    await pump(
      tester,
      FileUploadFailed(
        photo,
        failure: const ApiFailure(statusCode: 413, code: 'FILE_TOO_LARGE', message: 'server words'),
      ),
    );
    expect(find.text('This file is larger than 5 MB. Choose a smaller one.'), findsOneWidget);
    expect(find.text('server words'), findsNothing);
    // Sending the same file again would be refused the same way: no Try again, no preview, and Add photo replaces it.
    expect(find.text('Try again'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('does not start an upload for a photo picked after the screen went', (tester) async {
    final picking = _SlowPicking();
    await pump(tester, const FileUploadIdle(), picking: picking);
    await tester.tap(find.text('Add photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo.gallery')));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    picking.pick.complete(photo);
    await tester.pump();
    verifyNever(() => bloc.add(any()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a photo the app refused shows on the tile why, with no way to send it again', (tester) async {
    await pump(tester, FileUploadFailed(pdf, problem: FileProblem.typeNotAllowed));
    expect(find.text("This kind of file can't be used here. Choose a different one."), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Add photo'), findsOneWidget);
  });

  testWidgets('tells the form the file ID when the photo is sent, and null when it is replaced or removed', (
    tester,
  ) async {
    await pump(
      tester,
      const FileUploadIdle(),
      later: Stream.fromIterable([
        FileUploadSending(photo),
        FileUploadDone(photo, uploadedPhoto),
        FileUploadSending(photo),
        const FileUploadIdle(),
      ]),
    );
    await tester.pump();
    expect(changes, ['f1', null]);
  });

  testWidgets('fits at the largest text size on a narrow phone', (tester) async {
    for (final state in [
      FileUploadSending(photo, sent: 0.5),
      FileUploadDone(photo, uploadedPhoto),
      FileUploadFailed(photo, failure: const ApiFailure.network()),
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
  Future<ChosenFile?> photo(PhotoSource source) => pick.future;
}
