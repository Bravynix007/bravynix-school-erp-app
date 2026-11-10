import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/l10n/app_language.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/institution_choice_store.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/academic_years/data/academic_years_repository_impl.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/auth/data/auth_repository_impl.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/blocks/data/blocks_repository_impl.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/classes/data/classes_repository_impl.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/files/data/device_file_picking.dart';
import 'package:bravynix_school_erp/features/files/data/files_repository_impl.dart';
import 'package:bravynix_school_erp/features/files/data/object_uploader.dart';
import 'package:bravynix_school_erp/features/files/domain/file_picking.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/institutions/data/institutions_repository_impl.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/data/masters_repository_impl.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/platform_dues/data/platform_dues_repository_impl.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';
import 'package:bravynix_school_erp/features/sections/data/sections_repository_impl.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/subjects/data/subjects_repository_impl.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

/// The service locator. Only the composition root (this file, the router and
/// page `BlocProvider`s) reads it; blocs and repositories get their
/// dependencies through constructors, so tests pass fakes directly.
final GetIt getIt = GetIt.instance;

/// Registers app-wide services. Tests override [device], [tokens],
/// [installMarker] or [httpAdapter] to run without a phone or a network.
Future<void> configureDependencies(
  AppConfig config, {
  AppDevice? device,
  TokenStorage? tokens,
  InstallMarker? installMarker,
  HttpClientAdapter? httpAdapter,
}) async {
  await getIt.reset();
  final language = AppLanguage();
  final events = ApiEvents();
  final appDevice = device ?? await AppDevice.load();
  final tokenStorage = tokens ?? SecureTokenStorage();
  // Used when the splash restores the session, after runApp (re-review R-A2).
  final marker = installMarker ?? PreferencesInstallMarker();

  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<AppLanguage>(language)
    ..registerSingleton<ApiEvents>(events, dispose: (events) => events.dispose())
    ..registerSingleton<AppDevice>(appDevice)
    ..registerSingleton<TokenStorage>(tokenStorage)
    ..registerLazySingleton<ApiClient>(
      () => createApiClient(
        config: config,
        device: appDevice,
        tokens: tokenStorage,
        events: events,
        language: () => language.value,
        adapter: httpAdapter,
      ),
    )
    ..registerLazySingleton<AcademicYearsRepository>(() => AcademicYearsRepositoryImpl(api: getIt()))
    ..registerLazySingleton<ClassesRepository>(() => ClassesRepositoryImpl(api: getIt()))
    ..registerLazySingleton(() => ClassCatalogue(getIt(), getIt()))
    ..registerLazySingleton<SectionsRepository>(() => SectionsRepositoryImpl(api: getIt()))
    ..registerLazySingleton<SubjectsRepository>(() => SubjectsRepositoryImpl(api: getIt()))
    ..registerLazySingleton<FilesRepository>(
      () => FilesRepositoryImpl(
        api: getIt(),
        uploader: ObjectUploader(ObjectUploader.createDio(adapter: httpAdapter)),
      ),
    )
    ..registerLazySingleton<FilePicking>(DeviceFilePicking.new)
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        api: getIt(),
        tokens: tokenStorage,
        installMarker: marker,
        device: appDevice,
        events: events,
      ),
    )
    ..registerLazySingleton<BlocksRepository>(() => BlocksRepositoryImpl(api: getIt()))
    ..registerLazySingleton<InstitutionsRepository>(() => InstitutionsRepositoryImpl(api: getIt()))
    ..registerLazySingleton<InstitutionChoiceStore>(PreferencesInstitutionChoiceStore.new)
    ..registerLazySingleton<MastersRepository>(() => MastersRepositoryImpl(api: getIt()))
    ..registerLazySingleton<PlatformDuesRepository>(() => PlatformDuesRepositoryImpl(api: getIt()));
}
