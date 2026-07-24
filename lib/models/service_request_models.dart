// Mirrors citycalls-api's ServiceRequest shape (serviceRequests.model.ts).
// The list endpoint doesn't populate the service name (only customer/assignee) —
// so `serviceName` is nullable and only ever set from the detail endpoint.

// Internal statuses cover org-assignment mechanics (which branch/team/vendor
// picked it up) that mean nothing to a customer — collapsed to customer-
// friendly phrasing here rather than showing the raw enum. Keep in sync with
// citycalls-api's SERVICE_REQUEST_STATUSES (serviceRequests.model.ts).
const _customerStatusLabels = {
  'NEW': 'Request Received',
  'NEEDS_MANUAL_BRANCH_ASSIGNMENT': 'Request Received',
  'ASSIGNED_TO_BRANCH': 'Technician Assigned',
  'ASSIGNED_TO_SUB_BRANCH': 'Technician Assigned',
  'ASSIGNED_TO_TEAM': 'Technician Assigned',
  'ASSIGNED_TO_EMPLOYEE': 'Technician Assigned',
  'ASSIGNED_TO_VENDOR': 'Technician Assigned',
  'OUTSOURCED': 'Technician Assigned',
  'REASSIGNMENT_REQUIRED': 'Technician Assigned',
  'ACCEPTED': 'Technician Assigned',
  'APPOINTMENT_SCHEDULED': 'Appointment Scheduled',
  'RESCHEDULED': 'Rescheduled',
  'CUSTOMER_UNAVAILABLE': 'Reschedule Needed',
  'TECHNICIAN_EN_ROUTE': 'Technician On The Way',
  'TECHNICIAN_ARRIVED': 'Technician Arrived',
  'INSPECTION_STARTED': 'Inspection In Progress',
  'INSPECTION_COMPLETED': 'Inspection Completed',
  'ESTIMATE_PENDING': 'Preparing Estimate',
  'ESTIMATE_SHARED': 'Estimate Ready',
  'AWAITING_CUSTOMER_APPROVAL': 'Awaiting Your Approval',
  'ESTIMATE_APPROVED': 'Estimate Approved',
  'ESTIMATE_REJECTED': 'Estimate Rejected',
  'PARTS_PENDING': 'Waiting For Parts',
  'WORK_STARTED': 'Work Started',
  'WORK_IN_PROGRESS': 'Work In Progress',
  'ON_HOLD': 'On Hold',
  'SERVICE_COMPLETED': 'Service Completed',
  'CUSTOMER_CONFIRMATION_PENDING': 'Awaiting Your Confirmation',
  'PAYMENT_PENDING': 'Payment Pending',
  'PARTIALLY_PAID': 'Partially Paid',
  'PAID': 'Paid',
  'FOLLOW_UP_PENDING': 'Service Completed',
  'HAPPY_CALL_PENDING': 'Service Completed',
  'CLOSED': 'Closed',
  'REOPENED': 'Reopened',
  'CANCELLED': 'Cancelled',
};

String customerStatusLabel(String status) =>
    _customerStatusLabels[status] ?? status.replaceAll('_', ' ');

// Mirrors scripts/seed.ts's PRE_PAID_STATUSES exactly — every status the
// backend's status-transition engine actually allows a CANCELLED transition
// from. Showing "Cancel Request" for any other status (e.g. PARTIALLY_PAID,
// PAID, FOLLOW_UP_PENDING, CLOSED, REOPENED) would let the customer tap a
// button that's guaranteed to fail server-side with a transition error.
const _cancellableStatuses = {
  'NEW', 'NEEDS_MANUAL_BRANCH_ASSIGNMENT', 'ASSIGNED_TO_BRANCH', 'ASSIGNED_TO_SUB_BRANCH', 'ASSIGNED_TO_TEAM',
  'ASSIGNED_TO_EMPLOYEE', 'ASSIGNED_TO_VENDOR', 'OUTSOURCED', 'REASSIGNMENT_REQUIRED', 'ACCEPTED',
  'APPOINTMENT_SCHEDULED', 'RESCHEDULED', 'CUSTOMER_UNAVAILABLE', 'TECHNICIAN_EN_ROUTE', 'TECHNICIAN_ARRIVED',
  'INSPECTION_STARTED', 'INSPECTION_COMPLETED', 'ESTIMATE_PENDING', 'ESTIMATE_SHARED', 'AWAITING_CUSTOMER_APPROVAL',
  'ESTIMATE_APPROVED', 'PARTS_PENDING', 'WORK_STARTED', 'WORK_IN_PROGRESS', 'ON_HOLD', 'SERVICE_COMPLETED',
  'CUSTOMER_CONFIRMATION_PENDING', 'PAYMENT_PENDING',
};
bool isCancellableStatus(String status) => _cancellableStatuses.contains(status);

class ServiceRequestSummary {
  final String id;
  final String number;
  final String status;
  final String priority;
  final String createdAt;
  final String? serviceName;

  ServiceRequestSummary({
    required this.id,
    required this.number,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.serviceName,
  });

  bool get isActive => status != 'CLOSED' && status != 'CANCELLED';

  factory ServiceRequestSummary.fromJson(Map<String, dynamic> json) {
    return ServiceRequestSummary(
      id: json['_id'] as String,
      number: json['number'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'NORMAL',
      createdAt: json['createdAt'] as String,
      serviceName:
          (json['service'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}

class ServiceRequestAssignee {
  final String type;
  final String? name;
  ServiceRequestAssignee({required this.type, this.name});

  factory ServiceRequestAssignee.fromJson(Map<String, dynamic> json) {
    return ServiceRequestAssignee(type: json['type'] as String, name: json['name'] as String?);
  }
}

class ServiceRequestDetail {
  final String id;
  final String number;
  final String status;
  final String priority;
  final String createdAt;
  final String? completedAt;
  final String? cancelReason;
  final String? serviceName;
  final List<String> symptoms;
  final String? notes;
  final String addressLine;
  final ServiceRequestAssignee? assignee;

  ServiceRequestDetail({
    required this.id,
    required this.number,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.completedAt,
    this.cancelReason,
    this.serviceName,
    required this.symptoms,
    this.notes,
    required this.addressLine,
    this.assignee,
  });

  bool get isActive => status != 'CLOSED' && status != 'CANCELLED';

  factory ServiceRequestDetail.fromJson(Map<String, dynamic> json) {
    final address = json['addressSnapshot'] as Map<String, dynamic>?;
    final addressParts = [address?['line1'], address?['line2'], address?['city'], address?['state'], address?['pinCode']]
        .where((s) => s != null && (s as String).isNotEmpty)
        .join(', ');
    final assigneeJson = json['assignee'] as Map<String, dynamic>?;
    return ServiceRequestDetail(
      id: json['_id'] as String,
      number: json['number'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'NORMAL',
      createdAt: json['createdAt'] as String,
      completedAt: json['completedAt'] as String?,
      cancelReason: json['cancelReason'] as String?,
      serviceName: (json['service'] as Map<String, dynamic>?)?['name'] as String?,
      symptoms: (json['symptoms'] as List? ?? []).cast<String>(),
      notes: json['notes'] as String?,
      addressLine: addressParts,
      assignee: assigneeJson == null ? null : ServiceRequestAssignee.fromJson(assigneeJson),
    );
  }
}

class AssignmentHistoryEntry {
  final String id;
  final String action;
  final String? toAssigneeType;
  final String method;
  final String? reason;
  final String timestamp;
  final String? actorName;

  AssignmentHistoryEntry({
    required this.id,
    required this.action,
    this.toAssigneeType,
    required this.method,
    this.reason,
    required this.timestamp,
    this.actorName,
  });

  factory AssignmentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AssignmentHistoryEntry(
      id: json['_id'] as String,
      action: json['action'] as String,
      toAssigneeType: json['toAssigneeType'] as String?,
      method: json['method'] as String,
      reason: json['reason'] as String?,
      timestamp: json['timestamp'] as String,
      actorName: (json['actorId'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
