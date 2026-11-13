import 'api_client.dart';
import '../models/finance_models.dart';

// One repository class per module, per docs/12-frontend-data-contracts.md §3.
// Backs the "Estimates & Payments" flow (docs/rohit/05-customer-app-screen-list.md).
class FinanceRepository {
  final ApiClient _client;
  FinanceRepository(this._client);

  Future<Estimate?> getEstimateForRequest(String serviceRequestId) async {
    final actionable = await _client.dio.get('/estimates', queryParameters: {'serviceRequestId': serviceRequestId, 'status': 'SHARED', 'limit': 100});
    final pending = actionable.data['data'] as List;
    if (pending.isNotEmpty) return Estimate.fromJson(pending.first as Map<String, dynamic>);
    final res = await _client.dio.get('/estimates',
        queryParameters: {'serviceRequestId': serviceRequestId, 'limit': 1});
    final items = res.data['data'] as List;
    return items.isEmpty
        ? null
        : Estimate.fromJson(items.first as Map<String, dynamic>);
  }

  Future<void> approveEstimate(String id) async {
    await _client.dio.patch('/estimates/$id/approve');
  }

  Future<void> rejectEstimate(String id) async {
    await _client.dio.patch('/estimates/$id/reject');
  }

  Future<ProformaInvoice?> getProformaForRequest(
      String serviceRequestId) async {
    final res = await _client.dio.get('/proforma-invoices',
        queryParameters: {'serviceRequestId': serviceRequestId, 'limit': 1});
    final items = res.data['data'] as List;
    return items.isEmpty
        ? null
        : ProformaInvoice.fromJson(items.first as Map<String, dynamic>);
  }

  Future<void> acceptProforma(String id) async {
    await _client.dio.patch('/proforma-invoices/$id/accept');
  }

  Future<Invoice?> getInvoiceForRequest(String serviceRequestId) async {
    final res = await _client.dio.get('/invoices',
        queryParameters: {'serviceRequestId': serviceRequestId, 'limit': 1});
    final items = res.data['data'] as List;
    return items.isEmpty
        ? null
        : Invoice.fromJson(items.first as Map<String, dynamic>);
  }

  Future<List<PaymentReceipt>> listPayments(String invoiceId) async {
    final res = await _client.dio.get('/invoices/$invoiceId/payments');
    return (res.data['data'] as List)
        .map((p) => PaymentReceipt.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createCheckout(String invoiceId) async {
    final res = await _client.dio.post('/invoices/$invoiceId/checkout');
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }
  Future<Map<String, dynamic>> confirmCheckout(String invoiceId, {required String orderId, required String paymentId, required String signature}) async {
    final res = await _client.dio.post('/invoices/$invoiceId/checkout/confirm', data: {'orderId': orderId, 'paymentId': paymentId, 'signature': signature});
    return Map<String, dynamic>.from(res.data['data'] as Map);
  }
  Future<void> refreshCheckout(String invoiceId) async { await _client.dio.post('/invoices/$invoiceId/checkout/refresh'); }
  Future<String> documentUrl(String type, String id) async {
    final res = await _client.dio.get('/financial-documents/$type/$id/download');
    return _client.resolveUrl(res.data['data']['url'] as String);
  }

  // Returns credits and debits merged into one list — a customer reads an
  // adjustment as a single "this changed your bill" event, not as two
  // separate ledgers the way the backend stores them.
  Future<List<InvoiceNote>> listInvoiceNotes(String invoiceId) async {
    final res = await _client.dio.get('/invoices/$invoiceId/notes');
    final data = res.data['data'] as Map<String, dynamic>;
    final credits = (data['creditNotes'] as List? ?? []).map(
        (n) => InvoiceNote.fromJson(n as Map<String, dynamic>, isCredit: true));
    final debits = (data['debitNotes'] as List? ?? []).map((n) =>
        InvoiceNote.fromJson(n as Map<String, dynamic>, isCredit: false));
    return [...credits, ...debits];
  }
}
