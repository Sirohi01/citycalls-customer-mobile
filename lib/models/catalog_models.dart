class ServiceCategory {
  final String id;
  final String label;

  ServiceCategory({required this.id, required this.label});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
        id: json['_id'] as String, label: json['label'] as String);
  }
}

class ServicePricing {
  final double basePrice;
  final double visitingCharge;
  final double inspectionCharge;

  ServicePricing(
      {required this.basePrice,
      required this.visitingCharge,
      required this.inspectionCharge});

  factory ServicePricing.fromJson(Map<String, dynamic> json) {
    return ServicePricing(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      visitingCharge: (json['visitingCharge'] as num?)?.toDouble() ?? 0,
      inspectionCharge: (json['inspectionCharge'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Service {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final ServicePricing pricing;
  final int expectedDurationMinutes;
  final int warrantyPeriodDays;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.pricing,
    required this.expectedDurationMinutes,
    required this.warrantyPeriodDays,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as String,
      pricing: ServicePricing.fromJson(
          json['pricing'] as Map<String, dynamic>? ?? {}),
      expectedDurationMinutes:
          (json['expectedDurationMinutes'] as num?)?.toInt() ?? 60,
      warrantyPeriodDays: (json['warrantyPeriodDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class CoverageResult {
  final bool serviceable;
  final String? reason;

  CoverageResult({required this.serviceable, this.reason});

  factory CoverageResult.fromJson(Map<String, dynamic> json) {
    return CoverageResult(
        serviceable: json['serviceable'] as bool,
        reason: json['reason'] as String?);
  }
}
