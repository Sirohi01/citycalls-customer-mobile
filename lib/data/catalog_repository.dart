import 'api_client.dart';
import '../models/catalog_models.dart';

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
class CatalogRepository {
  final ApiClient _client;
  CatalogRepository(this._client);

  Future<List<ServiceCategory>> listCategories() async {
    final res = await _client.dio.get('/masters/SERVICE_CATEGORY', queryParameters: {'active': true, 'limit': 100});
    return (res.data['data'] as List).map((c) => ServiceCategory.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<Service>> listServices({String? categoryId}) async {
    final res = await _client.dio.get('/services', queryParameters: {
      'active': true,
      'limit': 100,
      if (categoryId != null) 'categoryId': categoryId,
    });
    return (res.data['data'] as List).map((s) => Service.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<Service> getService(String id) async {
    final res = await _client.dio.get('/services/$id');
    return Service.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<CoverageResult> checkCoverage(String serviceId, String pinCode) async {
    final res = await _client.dio.get('/services/$serviceId/coverage', queryParameters: {'pinCode': pinCode});
    return CoverageResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
