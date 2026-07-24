// Mirrors citycalls-api's File shape (files.model.ts) — reused as-is for
// Catalog Service media (CATALOG_IMAGE/VIDEO categories), same generic
// entity-attachment system admin-web's MediaGallery.tsx uploads into.
class MediaFile {
  final String id;
  final String category;
  final String provider;
  final String url;

  MediaFile({required this.id, required this.category, required this.provider, required this.url});

  bool get isVideo => category == 'VIDEO';

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['_id'] as String,
      category: json['category'] as String,
      provider: json['provider'] as String,
      url: json['url'] as String,
    );
  }
}
