import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/academic_years/data/academic_year_models.dart';
import 'package:bravynix_school_erp/features/academic_years/data/academic_years_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/academic_years.dart';
import '../../helpers/fake_http.dart';

void main() {
  const config = AppConfig(flavor: Flavor.dev, apiBaseUrl: 'http://api.test/v1');
  const device = AppDevice(platform: DevicePlatform.android, appVersion: '1.4.2');

  ({AcademicYearsRepositoryImpl repository, FakeHttpAdapter adapter}) build(FakeReply Function() reply) {
    final adapter = FakeHttpAdapter((_) async => reply());
    final api = createApiClient(
      config: config,
      device: device,
      tokens: InMemoryTokenStorage(const AuthTokens(accessToken: 'a1', refreshToken: 'r1')),
      events: ApiEvents(),
      language: () => 'en',
      adapter: adapter,
    );
    return (repository: AcademicYearsRepositoryImpl(api: api), adapter: adapter);
  }

  group('models', () {
    test('read a year and a list, ignoring the fields they do not show', () {
      expect(AcademicYearModels.year(yearJson()), currentYear);
      expect(
        AcademicYearModels.years([
          yearJson(),
          yearJson(
            id: 'y0',
            isCurrent: false,
            version: 4,
            name: '2025-2026',
            startDate: '2025-06-01',
            endDate: '2026-03-31',
          ),
        ]),
        [currentYear, earlierYear],
      );
    });

    test('refuse an answer they cannot read instead of showing a wrong year', () {
      expect(() => AcademicYearModels.year('x'), throwsFormatException);
      expect(() => AcademicYearModels.years({'a': 1}), throwsFormatException);
      expect(() => AcademicYearModels.year({...yearJson(), 'version': null}), throwsA(isA<TypeError>()));
    });

    test('send the Institution and the three fields to add, and the version with them to change', () {
      expect(AcademicYearModels.createBody('i1', name: 'n', startDate: '2026-06-01', endDate: '2027-03-31'), {
        'institutionId': 'i1',
        'name': 'n',
        'startDate': '2026-06-01',
        'endDate': '2027-03-31',
      });
      expect(AcademicYearModels.updateBody(currentYear, name: 'n', startDate: '2026-06-02', endDate: '2027-04-01'), {
        'version': 2,
        'name': 'n',
        'startDate': '2026-06-02',
        'endDate': '2027-04-01',
      });
    });
  });

  group('repository', () {
    test('lists the years of the Institution from AY-01', () async {
      final (:repository, :adapter) = build(() => okReply([yearJson()]));
      expect(await repository.years('i1'), [currentYear]);
      expect(adapter.requests.single.uri.toString(), 'http://api.test/v1/academic-years?institutionId=i1');
    });

    test('adds a year with AY-02', () async {
      final (:repository, :adapter) = build(() => okReply(yearJson(), status: 201));
      expect(
        await repository.create('i1', name: '2026-2027', startDate: '2026-06-01', endDate: '2027-03-31'),
        currentYear,
      );
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {
        'institutionId': 'i1',
        'name': '2026-2027',
        'startDate': '2026-06-01',
        'endDate': '2027-03-31',
      });
    });

    test('changes a year with AY-03, sending the version it read', () async {
      final (:repository, :adapter) = build(() => okReply(yearJson(version: 3)));
      await repository.update(currentYear, name: 'X', startDate: '2026-06-01', endDate: '2027-03-31');
      expect(adapter.paths, ['/v1/academic-years/y1']);
      expect(adapter.requests.single.method, 'PATCH');
      expect((adapter.requests.single.data as Map)['version'], 2);
    });

    test('makes a year current with AY-04, sending the version it read', () async {
      final (:repository, :adapter) = build(() => okReply(yearJson()));
      await repository.makeCurrent(earlierYear);
      expect(adapter.paths, ['/v1/academic-years/y0/make-current']);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'version': 4});
    });

    test('deactivates a year with AY-05, encoding the ID it puts in the path', () async {
      final (:repository, :adapter) = build(() => okReply({'id': 'a/b', 'status': 0}));
      await repository.deactivate('a/b');
      expect(adapter.paths, ['/v1/academic-years/a%2Fb']);
      expect(adapter.requests.single.method, 'DELETE');
    });

    test('turns a refusal into an ApiFailure for the screen', () async {
      for (final (status, code) in [(409, 'CURRENT_YEAR_LOCKED'), (409, 'YEAR_OVERLAP'), (404, 'NOT_FOUND')]) {
        final (:repository, adapter: _) = build(() => errorReply(status, code));
        await expectLater(
          repository.deactivate('y1'),
          throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', code)),
        );
      }
    });
  });
}
