import 'package:bravynix_school_erp/app/config/app_config.dart';
import 'package:bravynix_school_erp/core/device/app_device.dart';
import 'package:bravynix_school_erp/core/l10n/app_language.dart';
import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/core/network/api_events.dart';
import 'package:bravynix_school_erp/core/network/dio_factory.dart';
import 'package:bravynix_school_erp/core/storage/install_marker.dart';
import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/data/auth_repository_impl.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
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
  await clearTokensOnFirstStart(marker: installMarker ?? PreferencesInstallMarker(), tokens: tokenStorage);

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
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(api: getIt(), tokens: tokenStorage, device: appDevice, events: events),
    );
}
