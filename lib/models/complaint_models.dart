const _complaintStatusLabels = {
  'OPEN': 'Open',
  'IN_PROGRESS': 'In Progress',
  'RESOLVED': 'Resolved',
  'CLOSED': 'Closed',
};

String complaintStatusLabel(String status) => _complaintStatusLabels[status] ?? status;

class ComplaintSummary {
  final String id;
  final String subject;
  final String description;
  final String status;
  final String? serviceRequestNumber;
  final String? response;
  final String createdAt;

  ComplaintSummary({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    this.serviceRequestNumber,
    this.response,
    required this.createdAt,
  });

  factory ComplaintSummary.fromJson(Map<String, dynamic> json) {
    final sr = json['serviceRequestId'];
    return ComplaintSummary(
      id: json['_id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      serviceRequestNumber: sr is Map<String, dynamic> ? sr['number'] as String? : null,
      response: json['response'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}
