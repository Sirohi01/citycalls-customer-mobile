// Mirrors citycalls-api's AreaCheckResult (geo/geo.service.ts), returned by
// GET /geo/pincode/:pincode. That route is authMiddleware-only — no module
// permission gate — so a CUSTOMER role can call it.
class PincodeArea {
  final bool serviceable;
  final String? branchId;
  final String? branchName;
  final String? city;
  final String? state;
  final String? district;

  PincodeArea({
    required this.serviceable,
    this.branchId,
    this.branchName,
    this.city,
    this.state,
    this.district,
  });

  // The backend fills `state` from the covering Branch and leaves `city` unset
  // in the common case, so fall back to the district (which the PIN-code
  // adapter does resolve) rather than showing an empty city field.
  String? get resolvedCity => (city != null && city!.isNotEmpty) ? city : district;

  factory PincodeArea.fromJson(Map<String, dynamic> json) {
    return PincodeArea(
      serviceable: json['serviceable'] as bool? ?? false,
      branchId: json['branchId'] as String?,
      branchName: json['branchName'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
    );
  }
}
