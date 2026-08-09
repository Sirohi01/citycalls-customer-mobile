import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../models/finance_models.dart';
import 'auth_providers.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(apiClientProvider));
});

final estimateForRequestProvider = FutureProvider.family<Estimate?, String>((ref, serviceRequestId) async {
  return ref.watch(financeRepositoryProvider).getEstimateForRequest(serviceRequestId);
});

final proformaForRequestProvider = FutureProvider.family<ProformaInvoice?, String>((ref, serviceRequestId) async {
  return ref.watch(financeRepositoryProvider).getProformaForRequest(serviceRequestId);
});

final invoiceForRequestProvider = FutureProvider.family<Invoice?, String>((ref, serviceRequestId) async {
  return ref.watch(financeRepositoryProvider).getInvoiceForRequest(serviceRequestId);
});

final paymentsForInvoiceProvider = FutureProvider.family<List<PaymentReceipt>, String>((ref, invoiceId) async {
  return ref.watch(financeRepositoryProvider).listPayments(invoiceId);
});
