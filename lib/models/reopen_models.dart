// Mirrors citycalls-api's ReopenRecord shape (follow-up/reopenRecords.model.ts).
// A customer-initiated reopen starts PENDING and needs staff approval, so the
// customer needs somewhere to see whether theirs was approved or rejected —
// GET /service-requests/:id/reopen-history is the OWN-scoped way to read it
// (the /reopen-requests list endpoint is happyCalls-permission gated and a
// CUSTOMER role has no such permission, per the API's scripts/seed.ts).

const _reopenStatusLabels = {
  'PENDING': 'Awaiting review',
  'APPROVED': 'Approved',
  'REJECTED': 'Rejected',
};

String reopenStatusLabel(String status) => _reopenStatusLabels[status] ?? status;

class ReopenRecord {
  final String id;
  final String reason;
  final String status;
  final int reopenCount;
  final bool withinPolicyWindow;
  final bool warrantyApplied;
  final DateTime? reopenedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? reopenedByName;
  final String? newServiceRequestId;

  ReopenRecord({
    required this.id,
    required this.reason,
    required this.status,
    required this.reopenCount,
    required this.withinPolicyWindow,
    required this.warrantyApplied,
    this.reopenedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.reopenedByName,
    this.newServiceRequestId,
  });

  factory ReopenRecord.fromJson(Map<String, dynamic> json) {
    final by = json['reopenedBy'];
    final newSr = json['newServiceRequestId'];
    return ReopenRecord(
      id: json['_id'] as String,
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      reopenCount: (json['reopenCount'] as num?)?.toInt() ?? 1,
      withinPolicyWindow: json['withinPolicyWindow'] as bool? ?? false,
      warrantyApplied: json['warrantyApplied'] as bool? ?? false,
      reopenedAt: DateTime.tryParse(json['reopenedAt']?.toString() ?? '')?.toLocal(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? '')?.toLocal(),
      rejectionReason: json['rejectionReason'] as String?,
      reopenedByName: by is Map<String, dynamic> ? by['name'] as String? : null,
      newServiceRequestId: newSr is Map<String, dynamic> ? newSr['_id'] as String? : newSr as String?,
    );
  }
}
