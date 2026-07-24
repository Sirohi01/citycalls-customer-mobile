import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/realtime_models.dart';
import '../providers/realtime_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Tracking" — Live Map.
// Backed by citycalls-api's technician.location-updated socket event
// (src/realtime/index.ts) via serviceRequestRealtimeProvider. Note: as of
// 2026-07-24 nothing on the technician/vendor side actually calls
// POST /service-requests/:id/location-ping yet, so this renders correctly
// but will show the "not available yet" empty state until that's built —
// not a bug in this screen, a gap in the vendor app (out of scope here).
class LiveMapSection extends ConsumerStatefulWidget {
  final String requestId;
  const LiveMapSection({super.key, required this.requestId});

  @override
  ConsumerState<LiveMapSection> createState() => _LiveMapSectionState();
}

class _LiveMapSectionState extends ConsumerState<LiveMapSection> {
  // Tracked separately from the raw stream's latest value — the same
  // stream also carries status-changed/assigned events, and a StreamProvider
  // only exposes whichever event arrived most recently. Without this, a
  // status-changed event arriving after a location update would make the
  // map forget the last known position.
  ServiceRequestRealtimeEvent? _lastLocation;

  @override
  Widget build(BuildContext context) {
    ref.listen(serviceRequestRealtimeProvider(widget.requestId), (previous, next) {
      final event = next.valueOrNull;
      if (event != null && event.type == RealtimeEventType.locationUpdated && event.lat != null && event.lng != null) {
        setState(() => _lastLocation = event);
      }
    });

    final loc = _lastLocation;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.neutral200)),
      child: loc == null ? _emptyState() : _map(loc),
    );
  }

  Widget _emptyState() {
    return Container(
      height: 160,
      color: AppColors.neutral100,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off_outlined, color: AppColors.neutral500, size: 28),
          const SizedBox(height: 8),
          const Text('Technician location not available yet', style: TextStyle(color: AppColors.neutral500, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _map(ServiceRequestRealtimeEvent loc) {
    final point = LatLng(loc.lat!, loc.lng!);
    return SizedBox(
      height: 200,
      child: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: 15),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.citycalls.customer',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
                width: 42,
                height: 42,
                child: Container(
                  decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
