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
  final String? branchId;

  CoverageResult({required this.serviceable, this.reason, this.branchId});

  factory CoverageResult.fromJson(Map<String, dynamic> json) {
    return CoverageResult(
        serviceable: json['serviceable'] as bool,
        reason: json['reason'] as String?,
        branchId: json['branchId'] as String?);
  }
}

// One slide of the home-screen top banner, managed in admin → Customer App →
// Home Banner (citycalls-api src/modules/customer-app/home-banners).
class HomeBanner {
  final String id;
  final String tagLine;
  final String titleLine1;
  final String titleLine2;
  final String description;
  final String buttonText;
  final String imageUrl;
  final String? altText;

  HomeBanner({
    required this.id,
    required this.tagLine,
    required this.titleLine1,
    required this.titleLine2,
    required this.description,
    required this.buttonText,
    required this.imageUrl,
    this.altText,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json, String imageUrl) {
    return HomeBanner(
      id: json['_id'] as String,
      tagLine: json['tagLine'] as String? ?? '',
      titleLine1: json['titleLine1'] as String? ?? '',
      titleLine2: json['titleLine2'] as String? ?? '',
      description: json['description'] as String? ?? '',
      buttonText: json['buttonText'] as String? ?? 'Book a Service',
      imageUrl: imageUrl,
      altText: json['altText'] as String?,
    );
  }
}
