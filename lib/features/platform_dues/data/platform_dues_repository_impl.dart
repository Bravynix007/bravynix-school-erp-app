import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/platform_dues/data/platform_due_models.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_due.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';

class PlatformDuesRepositoryImpl implements PlatformDuesRepository {
  const new({required this._api});

  final ApiClient _api;

  @override
  Future<PlatformDues> dues() => _api.data('platform-dues', parse: PlatformDueModels.dues);

  @override
  Future<PlatformDue> due(String id) =>
      _api.data('platform-dues/${Uri.encodeComponent(id)}', parse: PlatformDueModels.due);
}
