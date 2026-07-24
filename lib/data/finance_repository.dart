import 'api_client.dart';
import '../models/finance_models.dart';

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
// Backs the "Estimates & Payments" flow (docs/rohit/05-customer-app-screen-list.md).
class FinanceRepository {
  final ApiClient _client;
  FinanceRepository(this._client);

  Future<Estimate?> getEstimateForRequest(String serviceRequestId) async {
    final res = await _client.dio.get('/estimates', queryParameters: {'serviceRequestId': serviceRequestId, 'limit': 1});
    final items = res.data['data'] as List;
    return items.isEmpty ? null : Estimate.fromJson(items.first as Map<String, dynamic>);
  }

  Future<void> approveEstimate(String id) async {
    await _client.dio.patch('/estimates/$id/approve');
  }

  Future<void> rejectEstimate(String id) async {
    await _client.dio.patch('/estimates/$id/reject');
  }

  Future<Invoice?> getInvoiceForRequest(String serviceRequestId) async {
    final res = await _client.dio.get('/invoices', queryParameters: {'serviceRequestId': serviceRequestId, 'limit': 1});
    final items = res.data['data'] as List;
    return items.isEmpty ? null : Invoice.fromJson(items.first as Map<String, dynamic>);
  }

  Future<List<PaymentReceipt>> listPayments(String invoiceId) async {
    final res = await _client.dio.get('/invoices/$invoiceId/payments');
    return (res.data['data'] as List).map((p) => PaymentReceipt.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<void> recordPayment(String invoiceId, {required double amount, required String method, String? reference}) async {
    await _client.dio.post('/invoices/$invoiceId/payments', data: {
      'amount': amount,
      'method': method,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
    });
  }
}
