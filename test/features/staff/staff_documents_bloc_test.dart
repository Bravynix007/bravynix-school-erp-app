import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_documents_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/documents.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockDocumentsRepository documents;
  late MockFilesRepository files;
  late MockFileOpening opening;

  final link = Uri.parse('https://store.test/get/token');
  const refused = ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'x');

  setUpAll(() => registerFallbackValue(Uri()));
  setUp(() {
    documents = MockDocumentsRepository();
    files = MockFilesRepository();
    opening = MockFileOpening();
    when(() => documents.staffDocuments('f1')).thenAnswer((_) async => [degreeCertificate]);
    when(() => files.downloadLink('fl2')).thenAnswer((_) async => link);
    when(() => opening.open(link)).thenAnswer((_) async => true);
  });

  StaffDocumentsBloc build() => StaffDocumentsBloc(documents, files, opening, staffMemberId: 'f1');

  Future<StaffDocumentsBloc> opened() async {
    final bloc = build();
    addTearDown(bloc.close);
    bloc.add(const StaffDocumentsStarted());
    await bloc.stream.firstWhere((state) => state is StaffDocumentsReady);
    return bloc;
  }

  StaffDocumentsReady ready(StaffDocumentsBloc bloc) => bloc.state as StaffDocumentsReady;

  Future<void> waitFor(StaffDocumentsBloc bloc, bool Function(StaffDocumentsReady) test) =>
      bloc.stream.firstWhere((state) => state is StaffDocumentsReady && test(state));

  /// A title and an uploaded file, ready to attach.
  void fill(StaffDocumentsBloc bloc, {String title = '  Appointment letter '}) => bloc
    ..add(StaffDocumentsTitleChanged(title))
    ..add(const StaffDocumentsFileChosen('fl1'));

  void attaches(Future<Document> Function() answer) => when(
    () => documents.attachToStaff(
      'f1',
      title: any(named: 'title'),
      fileId: any(named: 'fileId'),
    ),
  ).thenAnswer((_) => answer());

  group('starting', () {
    blocTest<StaffDocumentsBloc, StaffDocumentsState>(
      'reads the documents of the staff member',
      build: build,
      act: (bloc) => bloc.add(const StaffDocumentsStarted()),
      expect: () => [
        const StaffDocumentsLoading(),
        StaffDocumentsReady(documents: [degreeCertificate]),
      ],
    );

    blocTest<StaffDocumentsBloc, StaffDocumentsState>(
      'says why they could not be read, and reads again on Try again',
      setUp: () => when(() => documents.staffDocuments('f1')).thenThrow(const ApiFailure.network()),
      build: build,
      act: (bloc) async {
        bloc.add(const StaffDocumentsStarted());
        await pumpEventQueue();
        when(() => documents.staffDocuments('f1')).thenAnswer((_) async => []);
        bloc.add(const StaffDocumentsStarted());
      },
      expect: () => [
        const StaffDocumentsLoading(),
        const StaffDocumentsFailed(ApiFailure.network()),
        const StaffDocumentsLoading(),
        const StaffDocumentsReady(documents: []),
      ],
    );
  });

  group('the document being added', () {
    test('can be attached once it has a title that is not blank and a file that was uploaded', () async {
      final bloc = await opened();
      expect(ready(bloc).canAttach, isFalse);
      bloc
        ..add(const StaffDocumentsTitleChanged('   '))
        ..add(const StaffDocumentsFileChosen('fl1'));
      await pumpEventQueue();
      expect(ready(bloc).canAttach, isFalse);
      bloc.add(const StaffDocumentsTitleChanged('Letter'));
      await pumpEventQueue();
      expect(ready(bloc).canAttach, isTrue);
      bloc.add(const StaffDocumentsFileChosen(null));
      await pumpEventQueue();
      expect(ready(bloc).canAttach, isFalse);
    });

    test('lets go of the last refusal once the file is taken away or another is chosen', () async {
      attaches(() async => throw refused);
      final bloc = await opened();
      fill(bloc);
      bloc.add(const StaffDocumentsAttached());
      await waitFor(bloc, (state) => state.failure != null);
      bloc.add(const StaffDocumentsFileChosen(null));
      await pumpEventQueue();
      expect(ready(bloc).failure, isNull);
    });

    test('is not heard before the documents are read', () async {
      final bloc = build()..add(const StaffDocumentsTitleChanged('Letter'));
      addTearDown(bloc.close);
      await pumpEventQueue();
      expect(bloc.state, const StaffDocumentsLoading());
    });
  });

  group('attaching', () {
    test('sends the title without its spaces and the file, and puts the document first', () async {
      attaches(() async => appointmentLetter);
      final bloc = await opened();
      fill(bloc);
      bloc.add(const StaffDocumentsAttached());
      await waitFor(bloc, (state) => state.done != null);
      verify(() => documents.attachToStaff('f1', title: 'Appointment letter', fileId: 'fl1')).called(1);
      expect(ready(bloc).documents, [appointmentLetter, degreeCertificate]);
      expect(ready(bloc).done, StaffDocumentChange(appointmentLetter, removed: false));
    });

    test('empties the title and the file once it is attached, so the next one starts from nothing', () async {
      attaches(() async => appointmentLetter);
      final bloc = await opened();
      fill(bloc);
      bloc.add(const StaffDocumentsAttached());
      await waitFor(bloc, (state) => state.done != null);
      expect(ready(bloc).title, isEmpty);
      expect(ready(bloc).fileId, isNull);
      expect(ready(bloc).attaching, isFalse);
    });

    test('shows that it is on its way, and sends nothing twice', () async {
      final held = Completer<Document>();
      attaches(() => held.future);
      final bloc = await opened();
      fill(bloc);
      bloc
        ..add(const StaffDocumentsAttached())
        ..add(const StaffDocumentsAttached());
      await waitFor(bloc, (state) => state.attaching);
      expect(ready(bloc).canAttach, isFalse);
      held.complete(appointmentLetter);
      await waitFor(bloc, (state) => !state.attaching);
      verify(
        () => documents.attachToStaff(
          'f1',
          title: any(named: 'title'),
          fileId: any(named: 'fileId'),
        ),
      ).called(1);
    });

    test('sends nothing without a title or a file', () async {
      final bloc = await opened();
      bloc
        ..add(const StaffDocumentsTitleChanged('Letter'))
        ..add(const StaffDocumentsAttached());
      await pumpEventQueue();
      verifyNever(
        () => documents.attachToStaff(
          any(),
          title: any(named: 'title'),
          fileId: any(named: 'fileId'),
        ),
      );
    });

    for (final (status, code) in [(409, 'DUPLICATE'), (400, 'INVALID_VALUE'), (404, 'NOT_FOUND')]) {
      test('keeps the title and the file, with the failure, when $code refuses it', () async {
        final failure = ApiFailure(statusCode: status, code: code, message: 'x');
        attaches(() async => throw failure);
        final bloc = await opened();
        fill(bloc);
        bloc.add(const StaffDocumentsAttached());
        await waitFor(bloc, (state) => state.failure != null);
        expect(ready(bloc).failure, failure);
        expect(ready(bloc).title, '  Appointment letter ');
        expect(ready(bloc).fileId, 'fl1');
        expect(ready(bloc).attaching, isFalse);
        expect(ready(bloc).documents, [degreeCertificate]);
      });
    }

    test('clears the last refusal when it is sent again, so a success leaves none', () async {
      var sent = 0;
      attaches(() async {
        if (sent++ == 0) throw refused;
        return appointmentLetter;
      });
      final bloc = await opened();
      fill(bloc);
      bloc.add(const StaffDocumentsAttached());
      await waitFor(bloc, (state) => state.failure != null);
      bloc.add(const StaffDocumentsAttached());
      await waitFor(bloc, (state) => state.done != null);
      expect(ready(bloc).failure, isNull);
    });
  });

  group('removing', () {
    test('deactivates the document and takes it off the list', () async {
      when(() => documents.deactivate('o2')).thenAnswer((_) async {});
      final bloc = await opened();
      bloc.add(const StaffDocumentsRemoved('o2'));
      await waitFor(bloc, (state) => state.done != null);
      expect(ready(bloc).documents, isEmpty);
      expect(ready(bloc).removing, isNull);
      expect(ready(bloc).done, StaffDocumentChange(degreeCertificate, removed: true));
    });

    test('shows which one is on its way, and does nothing for one that is not there', () async {
      final held = Completer<void>();
      when(() => documents.deactivate('o2')).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc
        ..add(const StaffDocumentsRemoved('zz'))
        ..add(const StaffDocumentsRemoved('o2'));
      await waitFor(bloc, (state) => state.removing == 'o2');
      held.complete();
      await waitFor(bloc, (state) => state.removing == null);
      verifyNever(() => documents.deactivate('zz'));
    });

    test('keeps the document when it is refused, and says why', () async {
      const failure = ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x');
      when(() => documents.deactivate('o2')).thenThrow(failure);
      final bloc = await opened();
      bloc.add(const StaffDocumentsRemoved('o2'));
      await waitFor(bloc, (state) => state.failure != null);
      expect(ready(bloc).documents, [degreeCertificate]);
      expect(ready(bloc).removing, isNull);
    });

    test('takes the document off the list when it is already gone, and says so', () async {
      when(
        () => documents.deactivate('o2'),
      ).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'));
      final bloc = await opened();
      bloc.add(const StaffDocumentsRemoved('o2'));
      await waitFor(bloc, (state) => state.failure != null);
      expect(ready(bloc).documents, isEmpty);
    });
  });

  group('opening', () {
    test('asks for the link of the file and hands it to the phone', () async {
      final bloc = await opened();
      bloc.add(const StaffDocumentsOpened('o2'));
      await waitFor(bloc, (state) => state.opening == 'o2');
      await waitFor(bloc, (state) => state.opening == null);
      verify(() => files.downloadLink('fl2')).called(1);
      verify(() => opening.open(link)).called(1);
      expect(ready(bloc).phoneRefused, isFalse);
      expect(ready(bloc).failure, isNull);
    });

    test('says so when the phone has nothing to open it with', () async {
      when(() => opening.open(link)).thenAnswer((_) async => false);
      final bloc = await opened();
      bloc.add(const StaffDocumentsOpened('o2'));
      await waitFor(bloc, (state) => state.phoneRefused);
      expect(ready(bloc).opening, isNull);
    });

    test('says why when the link is refused, and does not open anything', () async {
      const failure = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');
      when(() => files.downloadLink('fl2')).thenThrow(failure);
      final bloc = await opened();
      bloc.add(const StaffDocumentsOpened('o2'));
      await waitFor(bloc, (state) => state.failure == failure);
      expect(ready(bloc).opening, isNull);
      verifyNever(() => opening.open(any()));
    });

    test('lets go of an earlier refusal when it starts again, and ignores one that is not on the list', () async {
      when(() => opening.open(link)).thenAnswer((_) async => false);
      final bloc = await opened();
      bloc.add(const StaffDocumentsOpened('o2'));
      await waitFor(bloc, (state) => state.phoneRefused);
      when(() => opening.open(link)).thenAnswer((_) async => true);
      bloc
        ..add(const StaffDocumentsOpened('zz'))
        ..add(const StaffDocumentsOpened('o2'));
      await waitFor(bloc, (state) => state.opening == 'o2');
      expect(ready(bloc).phoneRefused, isFalse);
      await waitFor(bloc, (state) => state.opening == null);
      verify(() => files.downloadLink('fl2')).called(2);
    });

    test('is not done while something else is on its way', () async {
      final held = Completer<void>();
      when(() => documents.deactivate('o2')).thenAnswer((_) => held.future);
      final bloc = await opened();
      bloc
        ..add(const StaffDocumentsRemoved('o2'))
        ..add(const StaffDocumentsOpened('o2'));
      await waitFor(bloc, (state) => state.removing != null);
      held.complete();
      await pumpEventQueue();
      verifyNever(() => files.downloadLink(any()));
    });
  });
}
