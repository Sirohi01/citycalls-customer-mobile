import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/catalog_repository.dart';
import '../models/catalog_models.dart';
import '../models/media_models.dart';
import 'auth_providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

final serviceCategoriesProvider =
    FutureProvider<List<ServiceCategory>>((ref) async {
  return ref.watch(catalogRepositoryProvider).listCategories();
});
final servicesByCategoryProvider =
    FutureProvider.family<List<Service>, String?>((ref, categoryId) async {
  return ref
      .watch(catalogRepositoryProvider)
      .listServices(categoryId: categoryId);
});

final serviceDetailProvider =
    FutureProvider.family<Service, String>((ref, serviceId) async {
  return ref.watch(catalogRepositoryProvider).getService(serviceId);
});

final serviceMediaProvider =
    FutureProvider.family<List<MediaFile>, String>((ref, serviceId) async {
  return ref.watch(catalogRepositoryProvider).getServiceMedia(serviceId);
});
