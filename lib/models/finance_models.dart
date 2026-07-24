// Mirrors citycalls-api's Estimate/Invoice/PaymentReceipt shapes.

class LineItem {
  final String description;
  final double qty;
  final double unitPrice;
  final double lineTotal;

  LineItem({required this.description, required this.qty, required this.unitPrice, required this.lineTotal});

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      description: json['description'] as String,
      qty: (json['qty'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Estimate {
  final String id;
  final String number;
  final String status;
  final List<LineItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String createdAt;

  Estimate({
    required this.id,
    required this.number,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.createdAt,
  });

  factory Estimate.fromJson(Map<String, dynamic> json) {
    return Estimate(
      id: json['_id'] as String,
      number: json['number'] as String,
      status: json['status'] as String,
      items: (json['items'] as List? ?? []).map((i) => LineItem.fromJson(i as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String,
    );
  }
}

class Invoice {
  final String id;
  final String number;
  final String status;
  final double total;
  final double amountPaid;
  final String createdAt;

  Invoice({required this.id, required this.number, required this.status, required this.total, required this.amountPaid, required this.createdAt});

  double get outstanding => total - amountPaid;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['_id'] as String,
      number: json['number'] as String,
      status: json['status'] as String,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String,
    );
  }
}

class PaymentReceipt {
  final String id;
  final String number;
  final double amount;
  final String method;
  final String? reference;
  final String createdAt;

  PaymentReceipt({required this.id, required this.number, required this.amount, required this.method, this.reference, required this.createdAt});

  factory PaymentReceipt.fromJson(Map<String, dynamic> json) {
    return PaymentReceipt(
      id: json['_id'] as String,
      number: json['number'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: json['method'] as String,
      reference: json['reference'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

const kPaymentMethods = ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE'];
