import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/geo_models.dart';

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
class GeoRepository {
  final ApiClient _client;
  GeoRepository(this._client);

  // Returns null rather than throwing when the PIN isn't recognised — this is
  // called opportunistically as the user types an address, where "we couldn't
  // resolve it" is an ordinary outcome, not an error worth interrupting them
  // over. They can still type city/state by hand.
  Future<PincodeArea?> lookupPincode(String pinCode) async {
    try {
      final res = await _client.dio.get('/geo/pincode/$pinCode');
      return PincodeArea.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }
}
