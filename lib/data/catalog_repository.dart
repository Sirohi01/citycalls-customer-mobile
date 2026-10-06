import 'api_client.dart';
import '../models/catalog_models.dart';
import '../models/media_models.dart';

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

  // Same generic Files entity-attachment system admin-web's MediaGallery.tsx
  // uploads into (entityType: 'SERVICE') — no service-specific media endpoint
  // exists or is needed.
  Future<List<MediaFile>> getServiceMedia(String serviceId) async {
    final res = await _client.dio.get('/files', queryParameters: {'entityType': 'SERVICE', 'entityId': serviceId});
    return (res.data['data'] as List).map((f) => MediaFile.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<List<MediaFile>> getMasterMedia(String masterId) async {
    final res = await _client.dio.get('/files', queryParameters: {'entityType': 'MASTER', 'entityId': masterId});
    return (res.data['data'] as List).map((f) => MediaFile.fromJson(f as Map<String, dynamic>)).toList();
  }

  // Public (no login needed) — only active banners that have an image, in
  // admin order.
  Future<List<HomeBanner>> listHomeBanners() async {
    final res = await _client.dio.get('/public/customer-app/home-banners');
    return (res.data['data'] as List)
        .cast<Map<String, dynamic>>()
        .map((b) => HomeBanner.fromJson(b, _bannerImageUrl(b['image'] as String)))
        .toList();
  }

  // Cloudinary originals are ~1600px PNGs; ask for a phone-sized, auto-format
  // copy instead. Local uploads are served as-is.
  String _bannerImageUrl(String url) {
    final resolved = _client.resolveUrl(url);
    if (!resolved.contains('res.cloudinary.com')) return resolved;
    return resolved.replaceFirst('/image/upload/', '/image/upload/w_1000,f_auto,q_auto/');
  }

  String resolveMediaUrl(MediaFile file) => file.provider == 'LOCAL' ? '${_client.apiOrigin}${file.url}' : file.url;
}
