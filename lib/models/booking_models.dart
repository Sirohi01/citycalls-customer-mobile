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

const kTimeSlots = ['Morning (9 AM - 12 PM)', 'Afternoon (12 PM - 4 PM)', 'Evening (4 PM - 8 PM)'];
