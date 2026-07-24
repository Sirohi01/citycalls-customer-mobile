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

  // channel: 'whatsapp' | 'email' | 'sms'; state: 'GRANTED' | 'REVOKED'.
  // Audit-logged server-side (docs/17-security-and-audit.md §8), so `reason`
  // is required by the backend even though it's a simple toggle in the UI.
  Future<void> updateConsent(String customerId, String channel, String state) async {
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
    await _client.dio.patch('/customers/$customerId/addresses/$addressId', data: {
      if (label != null && label.isNotEmpty) 'label': label,
      'line1': line1,
      if (line2 != null && line2.isNotEmpty) 'line2': line2,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      'city': city,
      'state': state,
      'pinCode': pinCode,
    });
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
