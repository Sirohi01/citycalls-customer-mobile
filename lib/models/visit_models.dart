// Mirrors citycalls-api's ServiceVisit shape (field-execution/serviceVisits.model.ts).
// One Service Request can span several visits (ON_HOLD / PARTS_PENDING
// re-entering WORK_IN_PROGRESS on a later day), each its own document — hence
// `visitNumber` rather than a single embedded object on the request.

class VisitPart {
  final String name;
  final double qty;
  final double unitPrice;

  VisitPart({required this.name, required this.qty, required this.unitPrice});

  double get lineTotal => qty * unitPrice;

  factory VisitPart.fromJson(Map<String, dynamic> json) {
    return VisitPart(
      name: json['name'] as String? ?? 'Part',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VisitInspection {
  final String? defectFound;
  final List<String> symptoms;
  final String? solutionType;

  VisitInspection({this.defectFound, this.symptoms = const [], this.solutionType});

  bool get isEmpty => defectFound == null && symptoms.isEmpty && solutionType == null;

  factory VisitInspection.fromJson(Map<String, dynamic>? json) {
    if (json == null) return VisitInspection();
    return VisitInspection(
      defectFound: json['defectFound'] as String?,
      symptoms: (json['symptoms'] as List? ?? []).map((s) => s.toString()).toList(),
      solutionType: json['solutionType'] as String?,
    );
  }
}

class ServiceVisit {
  final String id;
  final int visitNumber;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final VisitInspection inspection;
  final List<VisitPart> parts;
  final double? labourCharge;
  final List<String> beforeImages;
  final List<String> afterImages;
  final String? workNotes;
  final DateTime? nextVisitDate;
  // Only the proof TYPE is modelled. `completionProof.value` is a hashed OTP
  // server-side (serviceVisits.service.ts) and is never meaningful to show.
  final String? completionProofType;
  final String? completionProofUrl;

  ServiceVisit({
    required this.id,
    required this.visitNumber,
    this.startedAt,
    this.arrivedAt,
    this.completedAt,
    required this.inspection,
    this.parts = const [],
    this.labourCharge,
    this.beforeImages = const [],
    this.afterImages = const [],
    this.workNotes,
    this.nextVisitDate,
    this.completionProofType,
    this.completionProofUrl,
  });

  bool get isCompleted => completedAt != null;

  double get partsTotal => parts.fold(0, (sum, p) => sum + p.lineTotal);

  // True when the visit carries nothing a customer would want to read — a
  // technician who checked in but hasn't recorded a diagnosis yet. The screen
  // still lists it (so the visit count is honest) but shows an "in progress"
  // note instead of a set of empty sections.
  bool get hasDetails =>
      !inspection.isEmpty ||
      parts.isNotEmpty ||
      (workNotes != null && workNotes!.isNotEmpty) ||
      beforeImages.isNotEmpty ||
      afterImages.isNotEmpty;

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  factory ServiceVisit.fromJson(Map<String, dynamic> json) {
    final proof = json['completionProof'] as Map<String, dynamic>?;
    return ServiceVisit(
      id: json['_id'] as String,
      visitNumber: (json['visitNumber'] as num?)?.toInt() ?? 1,
      startedAt: _date(json['startedAt']),
      arrivedAt: _date(json['arrivedAt']),
      completedAt: _date(json['completedAt']),
      inspection: VisitInspection.fromJson(json['inspection'] as Map<String, dynamic>?),
      parts: (json['parts'] as List? ?? [])
          .map((p) => VisitPart.fromJson(p as Map<String, dynamic>))
          .toList(),
      labourCharge: (json['labourCharge'] as num?)?.toDouble(),
      beforeImages: (json['beforeImages'] as List? ?? []).map((i) => i.toString()).toList(),
      afterImages: (json['afterImages'] as List? ?? []).map((i) => i.toString()).toList(),
      workNotes: json['workNotes'] as String?,
      nextVisitDate: _date(json['nextVisitDate']),
      completionProofType: proof?['type'] as String?,
      completionProofUrl: proof?['url'] as String?,
    );
  }
}
