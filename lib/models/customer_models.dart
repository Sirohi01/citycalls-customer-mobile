class CustomerAddress {
  final String id;
  final String? label;
  final String? line1;
  final String? line2;
  final String? landmark;
  final String city;
  final String state;
  final String pinCode;
  final bool isDefault;

  CustomerAddress({
    required this.id,
    this.label,
    this.line1,
    this.line2,
    this.landmark,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.isDefault,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['_id'] as String,
      label: json['label'] as String?,
      line1: json['line1'] as String?,
      line2: json['line2'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      pinCode: json['pinCode'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final List<CustomerAddress> addresses;
  final Map<String, String> consent;

  Customer({
    required this.id,
    required this.name,
    this.email,
    required this.addresses,
    required this.consent,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      addresses: (json['addresses'] as List? ?? [])
          .map((a) => CustomerAddress.fromJson(a as Map<String, dynamic>))
          .toList(),
      consent: Map<String, String>.from(json['consent'] as Map? ?? {}),
    );
  }
  bool get needsProfileSetup => name == 'Customer';
}
