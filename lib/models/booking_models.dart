// Booking-flow-specific shapes. Reuses ServiceCategory (models/catalog_models.dart)
// as a generic {id, label} shape for Brand/ProductType/Symptom Masters too —
// all Master entities return the same shape regardless of masterType.

class CustomerProductSummary {
  final String id;
  final String brandLabel;
  final String productTypeLabel;
  final String? modelNumber;

  CustomerProductSummary({required this.id, required this.brandLabel, required this.productTypeLabel, this.modelNumber});

  factory CustomerProductSummary.fromJson(Map<String, dynamic> json) {
    final brand = json['brandId'] as Map<String, dynamic>?;
    final productType = json['productTypeId'] as Map<String, dynamic>?;
    return CustomerProductSummary(
      id: json['_id'] as String,
      brandLabel: brand?['label'] as String? ?? 'Unknown brand',
      productTypeLabel: productType?['label'] as String? ?? 'Unknown type',
      modelNumber: json['modelNumber'] as String?,
    );
  }
}

class AddressDraft {
  final String? label;
  final String line1;
  final String? line2;
  final String? landmark;
  final String city;
  final String state;
  final String pinCode;

  AddressDraft({this.label, required this.line1, this.line2, this.landmark, required this.city, required this.state, required this.pinCode});

  Map<String, dynamic> toAddressSnapshotJson() => {
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'country': 'India',
      };

  Map<String, dynamic> toAddAddressJson() => {
        if (label != null && label!.isNotEmpty) 'label': label,
        'line1': line1,
        if (line2 != null && line2!.isNotEmpty) 'line2': line2,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'country': 'India',
      };
}

// Threaded forward through the booking wizard's screens (Product -> Address ->
// Issue -> Slot -> Review), one copyWith per step rather than a global
// Riverpod state — this flow is strictly linear, so navigation args are
// simpler to reason about than provider lifecycle.
class BookingDraft {
  final String serviceId;
  final String serviceName;
  final String pinCode;
  final String? customerProductId;
  final AddressDraft? address;
  // Plain symptom label strings, NOT Master _ids — serviceRequests.model.ts
  // stores `symptoms: string[]` as free descriptive text, not a Master
  // reference, even though the picker UI sources its options from the
  // SYMPTOM master list.
  final List<String> symptoms;
  final String? notes;
  final List<String> imageUrls;
  final DateTime? scheduledDate;
  final String? scheduledSlot;

  BookingDraft({
    required this.serviceId,
    required this.serviceName,
    required this.pinCode,
    this.customerProductId,
    this.address,
    this.symptoms = const [],
    this.notes,
    this.imageUrls = const [],
    this.scheduledDate,
    this.scheduledSlot,
  });

  BookingDraft copyWith({
    String? customerProductId,
    AddressDraft? address,
    List<String>? symptoms,
    String? notes,
    List<String>? imageUrls,
    DateTime? scheduledDate,
    String? scheduledSlot,
  }) {
    return BookingDraft(
      serviceId: serviceId,
      serviceName: serviceName,
      pinCode: pinCode,
      customerProductId: customerProductId ?? this.customerProductId,
      address: address ?? this.address,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledSlot: scheduledSlot ?? this.scheduledSlot,
    );
  }
}

// Real per-branch capacity-checked slots — GET /appointment-slots, per
// docs/manish/08-customer-app-functional-plan.md §2. `label` is what gets
// submitted/persisted as ServiceRequest.scheduledSlot (a free string on the
// backend, same convention as symptoms: label text, not a Master _id).
class AppointmentSlot {
  final String key;
  final String label;
  final String? startTime;
  final String? endTime;
  final int remaining;
  final bool available;

  AppointmentSlot({
    required this.key,
    required this.label,
    this.startTime,
    this.endTime,
    required this.remaining,
    required this.available,
  });

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      key: json['key'] as String,
      label: json['label'] as String,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      available: json['available'] as bool? ?? false,
    );
  }
}

class AppointmentSlotsResult {
  final bool dayClosed;
  final List<AppointmentSlot> slots;

  AppointmentSlotsResult({required this.dayClosed, required this.slots});

  factory AppointmentSlotsResult.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotsResult(
      dayClosed: json['dayClosed'] as bool? ?? false,
      slots: (json['slots'] as List? ?? [])
          .map((s) => AppointmentSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
