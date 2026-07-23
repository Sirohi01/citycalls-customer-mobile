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
}
