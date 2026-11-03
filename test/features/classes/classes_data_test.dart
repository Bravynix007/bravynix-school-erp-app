import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/classes/data/class_models.dart';
import 'package:bravynix_school_erp/features/classes/data/classes_repository_impl.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/fake_http.dart';
import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({ClassesRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: ClassesRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read a class, with and without a stream', () {
      expect(ClassModels.schoolClass(classJson()), class1);
      expect(
        ClassModels.schoolClass(
          classJson(
            id: 'k9',
            predefined: puc1Ref,
            category: preUniversityCategory,
            streamName: 'PCMC',
            displayName: 'PUC 1st Year PCMC',
            code: null,
            sectionCount: 0,
            version: 1,
          ),
        ),
        pucClass,
      );
      expect(ClassModels.classes([classJson()]), [class1]);
    });

    test('refuse an answer they cannot read instead of showing a wrong class', () {
      expect(() => ClassModels.schoolClass('x'), throwsFormatException);
      expect(() => ClassModels.classes({'a': 1}), throwsFormatException);
      expect(() => ClassModels.schoolClass({...classJson(), 'version': null}), throwsA(isA<TypeError>()));
    });

    test('send only what is set to add a class, with the Institution', () {
      expect(ClassModels.createBody('i1', const NewClass(predefinedClassId: 'p1')), {
        'institutionId': 'i1',
        'predefinedClassId': 'p1',
      });
      expect(
        ClassModels.createBody(
          'i1',
          const NewClass(predefinedClassId: 'p9', streamName: 'PCMC'),
          displayName: 'PUC',
          code: 'P1',
        ),
        {'institutionId': 'i1', 'predefinedClassId': 'p9', 'streamName': 'PCMC', 'displayName': 'PUC', 'code': 'P1'},
      );
    });

    test('send the classes of a bulk add in the order asked', () {
      expect(
        ClassModels.bulkBody('i1', const [NewClass(predefinedClassId: 'p1'), NewClass(predefinedClassId: 'p2')]),
        {
          'institutionId': 'i1',
          'classes': [
            {'predefinedClassId': 'p1'},
            {'predefinedClassId': 'p2'},
          ],
        },
      );
    });

    test('send the name and the code, null to clear it, and the version to change a class', () {
      expect(ClassModels.updateBody(class1, displayName: 'One', code: 'X'), {
        'version': 3,
        'displayName': 'One',
        'code': 'X',
      });
      expect(ClassModels.updateBody(class1, displayName: 'One'), {'version': 3, 'displayName': 'One', 'code': null});
    });
  });

  group('repository', () {
    test('lists the classes of the Institution from CLS-01', () async {
      final (:repository, :adapter) = build(() => okReply([classJson()]));
      expect(await repository.classes('i1'), [class1]);
      expect(adapter.requests.single.uri.toString(), 'http://api.test/v1/classes?institutionId=i1');
    });

    test('adds a class with CLS-02', () async {
      final (:repository, :adapter) = build(() => okReply(classJson(), status: 201));
      expect(await repository.create('i1', const NewClass(predefinedClassId: 'p1'), code: 'ONE'), class1);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.paths, ['/v1/classes']);
      expect(adapter.requests.single.data, {'institutionId': 'i1', 'predefinedClassId': 'p1', 'code': 'ONE'});
    });

    test('adds several with CLS-03', () async {
      final (:repository, :adapter) = build(
        () => okReply([classJson(), classJson(id: 'k2', predefined: class2Ref, displayName: 'Class 2')], status: 201),
      );
      final added = await repository.createMany('i1', const [
        NewClass(predefinedClassId: 'p1'),
        NewClass(predefinedClassId: 'p2'),
      ]);
      expect(added.map((item) => item.id), ['k1', 'k2']);
      expect(adapter.paths, ['/v1/classes/bulk']);
      expect(adapter.requests.single.method, 'POST');
    });

    test('changes a class with CLS-04, sending the version it read', () async {
      final (:repository, :adapter) = build(() => okReply(classJson(version: 4)));
      await repository.update(class1, displayName: 'One');
      expect(adapter.paths, ['/v1/classes/k1']);
      expect(adapter.requests.single.method, 'PATCH');
      expect((adapter.requests.single.data as Map)['version'], 3);
    });

    test('deactivates a class with CLS-05, encoding the ID it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'a/b', 'status': 0}));
      await repository.deactivate('a/b');
      expect(adapter.paths, ['/v1/classes/a%2Fb']);
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('turns a refusal into an ApiFailure for the screen', () async {
      for (final (status, code) in [(409, 'DUPLICATE'), (422, 'CLASS_NOT_OFFERED'), (404, 'NOT_FOUND')]) {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        await expectLater(
          repository.deactivate('k1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });
  });

  group('ClassCatalogue', () {
    test('offers the predefined classes of the categories the Institution offers, under their categories', () async {
      final institutions = MockInstitutionsRepository();
      final masters = MockMastersRepository();
      when(() => institutions.institution('i1')).thenAnswer((_) async => institution);
      when(() => masters.entries(MasterType.classCategories)).thenAnswer(
        (_) async => [lowerPrimary, higherPrimary, seniorSecondary],
      );
      when(() => masters.entries(MasterType.predefinedClasses, parentId: 'c1')).thenAnswer(
        (_) async => const [
          MasterEntry(id: 'p1', name: 'Class 1', code: 'C1'),
          MasterEntry(id: 'p2', name: 'Class 2', code: 'C2'),
        ],
      );
      when(() => masters.entries(MasterType.predefinedClasses, parentId: 'c2')).thenAnswer(
        (_) async => const [MasterEntry(id: 'p4', name: 'Class 4', code: 'C4')],
      );
      final choices = await ClassCatalogue(institutions, masters).offered('i1');
      expect(choices.map((choice) => choice.predefinedClass.id), ['p1', 'p2', 'p4']);
      expect(choices.first.category, const NamedRef(id: 'c1', code: 'LOWER_PRIMARY', name: 'Lower Primary'));
      expect(choices.categories.map((category) => category.id), ['c1', 'c2']);
      expect(choices.inCategory(choices.categories.last).map((choice) => choice.predefinedClass.id), ['p4']);
      verifyNever(() => masters.entries(MasterType.predefinedClasses, parentId: 'c3'));
    });

    test('says which classes allow a stream: only those of Pre-University', () {
      expect(class1Choice.allowsStream, isFalse);
      expect(pucChoice.allowsStream, isTrue);
    });
  });
}
