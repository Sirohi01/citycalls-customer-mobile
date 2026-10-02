import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import '../models/customer_models.dart';

class CustomerRepository {
  final ApiClient _client;
  CustomerRepository(this._client);
  Future<Customer> getMyProfile() async {
    final res = await _client.dio.get('/customers/me');
    return Customer.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<Customer> updateProfile(String customerId,
      {required String name, String? email}) async {
    final res = await _client.dio.patch('/customers/$customerId', data: {
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    return Customer.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // --- Profile photo ---
  // The Customer document has no photo field, so the photo lives in the
  // generic Files store as a PROFILE_IMAGE attached to this customer
  // (entityType CUSTOMER). The newest one is the current photo.
  static const _photoEntity = 'CUSTOMER';
  static const _photoCategory = 'PROFILE_IMAGE';

  Future<List<Map<String, dynamic>>> _listPhotos(String customerId) async {
    final res = await _client.dio.get('/files', queryParameters: {
      'entityType': _photoEntity,
      'entityId': customerId,
      'category': _photoCategory,
    });
    return (res.data['data'] as List).cast<Map<String, dynamic>>();
  }

  /// Current profile photo URL, or null if the customer hasn't set one.
  Future<String?> getProfilePhotoUrl(String customerId) async {
    final photos = await _listPhotos(customerId); // newest first
    if (photos.isEmpty) return null;
    return _client.resolveUrl(photos.first['url'] as String);
  }

  /// Uploads [image] as the new profile photo, then removes older ones.
  /// Uses Cloudinary when the backend has it enabled, otherwise the API's
  /// own direct-upload endpoint (files.service.ts requestSignedUpload).
  Future<void> uploadProfilePhoto(String customerId, XFile image) async {
    final bytes = await image.readAsBytes();
    final mimeType = _imageMimeType(image.name);
    final target = {
      'category': _photoCategory,
      'entityType': _photoEntity,
      'entityId': customerId,
    };

    final signed =
        (await _client.dio.post('/files/signed-upload', data: target))
            .data['data'] as Map<String, dynamic>;

    if (signed['mode'] == 'CLOUDINARY') {
      final upload = await Dio().post(
        'https://api.cloudinary.com/v1_1/${signed['cloudName']}/image/upload',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes,
              filename: image.name, contentType: DioMediaType.parse(mimeType)),
          'api_key': signed['apiKey'],
          'timestamp': signed['timestamp'],
          'signature': signed['signature'],
          'folder': signed['folder'],
        }),
      );
      await _client.dio.post('/files/confirm', data: {
        ...target,
        'publicId': upload.data['public_id'],
        'url': upload.data['secure_url'],
        'mimeType': mimeType,
        'sizeBytes': bytes.length,
      });
    } else {
      await _client.dio.post('/files/upload',
          data: FormData.fromMap({
            ...target,
            'file': MultipartFile.fromBytes(bytes,
                filename: image.name,
                contentType: DioMediaType.parse(mimeType)),
          }));
    }

    // Keep only the newest photo. Best-effort: a leftover old file just sits
    // unused, the newest one is still what's shown.
    final photos = await _listPhotos(customerId);
    for (final old in photos.skip(1)) {
      try {
        await _client.dio.delete('/files/${old['_id']}');
      } catch (_) {}
    }
  }

  Future<void> removeProfilePhoto(String customerId) async {
    for (final photo in await _listPhotos(customerId)) {
      await _client.dio.delete('/files/${photo['_id']}');
    }
  }

  // The backend only accepts jpeg/png/webp for PROFILE_IMAGE. image_picker
  // re-encodes to JPEG when a quality is set, so anything else is sent as that.
  String _imageMimeType(String name) {
    final ext = name.toLowerCase().split('.').last;
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  // channel: 'whatsapp' | 'email' | 'sms'; state: 'GRANTED' | 'REVOKED'.
  // Audit-logged server-side (docs/17-security-and-audit.md §8), so `reason`
  // is required by the backend even though it's a simple toggle in the UI.
  Future<void> updateConsent(
      String customerId, String channel, String state) async {
    await _client.dio.patch('/customers/$customerId/consent', data: {
      'channel': channel,
      'state': state,
      'reason': 'Updated by customer in-app',
    });
  }

  Future<void> addAddress(
    String customerId, {
    String? label,
    required String line1,
    String? line2,
    String? landmark,
    required String city,
    required String state,
    required String pinCode,
  }) async {
    await _client.dio.post('/customers/$customerId/addresses', data: {
      if (label != null && label.isNotEmpty) 'label': label,
      'line1': line1,
      if (line2 != null && line2.isNotEmpty) 'line2': line2,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      'city': city,
      'state': state,
      'pinCode': pinCode,
    });
  }

  Future<void> updateAddress(
    String customerId,
    String addressId, {
    String? label,
    required String line1,
    String? line2,
    String? landmark,
    required String city,
    required String state,
    required String pinCode,
  }) async {
    await _client.dio
        .patch('/customers/$customerId/addresses/$addressId', data: {
      if (label != null && label.isNotEmpty) 'label': label,
      'line1': line1,
      if (line2 != null && line2.isNotEmpty) 'line2': line2,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      'city': city,
      'state': state,
      'pinCode': pinCode,
    });
  }

  // The address sub-document schema carries isDefault, but the backend
  // doesn't unset the previous default when a new one is set, so both steps
  // happen here — otherwise the customer ends up with two "default"
  // addresses and whichever one sorts first silently wins.
  Future<void> setDefaultAddress(String customerId, String addressId,
      {String? previousDefaultId}) async {
    if (previousDefaultId != null && previousDefaultId != addressId) {
      await _client.dio.patch(
        '/customers/$customerId/addresses/$previousDefaultId',
        data: {'isDefault': false},
      );
    }
    await _client.dio.patch(
      '/customers/$customerId/addresses/$addressId',
      data: {'isDefault': true},
    );
  }

  Future<void> deleteAddress(String customerId, String addressId) async {
    await _client.dio.delete('/customers/$customerId/addresses/$addressId');
  }

  // "me"-scoped (not /customers/:id) — the backend resolves the caller's own
  // Customer record from the JWT itself, so no customerId is needed here.
  Future<void> registerFcmToken(String token) async {
    await _client.dio.post('/customers/me/fcm-token', data: {'token': token});
  }

  Future<void> unregisterFcmToken(String token) async {
    await _client.dio.delete('/customers/me/fcm-token', data: {'token': token});
  }
}
