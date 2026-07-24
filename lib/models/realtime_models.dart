// Mirrors the three service-request-scoped events citycalls-api's
// src/realtime/index.ts emits (service-request.status-changed, .assigned,
// technician.location-updated) — one shared event type so a single Stream
// can carry all three to whichever screen/widget cares about a given kind.
enum RealtimeEventType { statusChanged, assigned, locationUpdated }

class ServiceRequestRealtimeEvent {
  final RealtimeEventType type;
  final String? fromStatus;
  final String? toStatus;
  final double? lat;
  final double? lng;
  final DateTime? at;

  ServiceRequestRealtimeEvent._({
    required this.type,
    this.fromStatus,
    this.toStatus,
    this.lat,
    this.lng,
    this.at,
  });

  factory ServiceRequestRealtimeEvent.statusChanged(Map<String, dynamic> json) {
    return ServiceRequestRealtimeEvent._(
      type: RealtimeEventType.statusChanged,
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String?,
    );
  }

  factory ServiceRequestRealtimeEvent.assigned(Map<String, dynamic> json) {
    return ServiceRequestRealtimeEvent._(type: RealtimeEventType.assigned);
  }

  factory ServiceRequestRealtimeEvent.locationUpdated(Map<String, dynamic> json) {
    final geo = json['geo'] as Map<String, dynamic>?;
    return ServiceRequestRealtimeEvent._(
      type: RealtimeEventType.locationUpdated,
      lat: (geo?['lat'] as num?)?.toDouble(),
      lng: (geo?['lng'] as num?)?.toDouble(),
      at: json['at'] != null ? DateTime.tryParse(json['at'] as String) : null,
    );
  }
}
