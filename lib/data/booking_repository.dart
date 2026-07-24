import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/booking_models.dart';
import '../models/catalog_models.dart';

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
// Backs the Booking flow (docs/rohit/05-customer-app-screen-list.md's
// "Booking" flow) — product/address selection, issue image upload, and the
// final POST /service-requests submit.
class BookingRepository {
  final ApiClient _client;
  BookingRepository(this._client);

  Future<List<CustomerProductSummary>> listProducts(String customerId) async {
    final res = await _client.dio.get('/customers/$customerId/products');
    return (res.data['data'] as List).map((p) => CustomerProductSummary.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<void> addProduct(String customerId, {required String brandId, required String productTypeId, String? modelNumber}) async {
    await _client.dio.post('/customers/$customerId/products', data: {
      'brandId': brandId,
      'productTypeId': productTypeId,
      if (modelNumber != null && modelNumber.isNotEmpty) 'modelNumber': modelNumber,
    });
  }

  Future<List<ServiceCategory>> listMasters(String masterType) async {
    final res = await _client.dio.get('/masters/$masterType', queryParameters: {'active': true, 'limit': 100});
    return (res.data['data'] as List).map((m) => ServiceCategory.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<void> addAddress(String customerId, AddressDraft address) async {
    await _client.dio.post('/customers/$customerId/addresses', data: address.toAddAddressJson());
  }

  // Uploaded against entityType 'CUSTOMER' since the ServiceRequest doesn't
  // exist yet at this point in the flow — the resulting URL is what actually
  // gets submitted as part of createServiceRequestSchema's `images: string[]`,
  // this isn't a permanent association to the customer entity.
  Future<String> uploadIssueImage(String customerId, File file) async {
    final signedRes = await _client.dio.post('/files/signed-upload', data: {
      'category': 'ISSUE_IMAGE',
      'entityType': 'CUSTOMER',
      'entityId': customerId,
    });
    final signed = signedRes.data['data'] as Map<String, dynamic>;

    if (signed['mode'] == 'CLOUDINARY') {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'timestamp': signed['timestamp'].toString(),
        'signature': signed['signature'],
        'api_key': signed['apiKey'],
        'folder': signed['folder'],
      });
      // Deliberately a bare Dio(), not _client.dio — Cloudinary must not
      // receive our API's Authorization/Bearer header.
      final cloudinaryRes = await Dio().post('https://api.cloudinary.com/v1_1/${signed['cloudName']}/auto/upload', data: form);
      final confirmRes = await _client.dio.post('/files/confirm', data: {
        'category': 'ISSUE_IMAGE',
        'entityType': 'CUSTOMER',
        'entityId': customerId,
        'publicId': cloudinaryRes.data['public_id'],
        'url': cloudinaryRes.data['secure_url'],
        'mimeType': 'image/jpeg',
        'sizeBytes': await file.length(),
      });
      return confirmRes.data['data']['url'] as String;
    }

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'category': 'ISSUE_IMAGE',
      'entityType': 'CUSTOMER',
      'entityId': customerId,
    });
    final res = await _client.dio.post('/files/upload', data: form);
    return res.data['data']['url'] as String;
  }

  Future<Map<String, dynamic>> createServiceRequest(BookingDraft draft, String customerId) async {
    final res = await _client.dio.post('/service-requests', data: {
      'customerId': customerId,
      if (draft.customerProductId != null) 'customerProductId': draft.customerProductId,
      'addressSnapshot': draft.address!.toAddressSnapshotJson(),
      'serviceId': draft.serviceId,
      'symptoms': draft.symptoms,
      if (draft.notes != null && draft.notes!.isNotEmpty) 'notes': draft.notes,
      'images': draft.imageUrls,
      'source': 'CUSTOMER_APP',
      if (draft.scheduledDate != null) 'scheduledDate': draft.scheduledDate!.toIso8601String(),
      if (draft.scheduledSlot != null) 'scheduledSlot': draft.scheduledSlot,
    });
    return res.data['data'] as Map<String, dynamic>;
  }
}
