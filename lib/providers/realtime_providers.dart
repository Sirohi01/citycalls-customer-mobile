import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/socket_service.dart';
import '../models/realtime_models.dart';
import 'auth_providers.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(ref.watch(apiClientProvider));
});

// Joins `service-request:{id}`'s room for as long as something is watching
// this provider (a Service Request Detail screen, a Live Map section) and
// leaves it on dispose — per-request rooms aren't auto-joined at the socket
// connection level (see citycalls-api's realtime/index.ts), so this is the
// one place that does it, shared by every listener of a given requestId.
final serviceRequestRealtimeProvider = StreamProvider.family<ServiceRequestRealtimeEvent, String>((ref, requestId) {
  final socket = ref.watch(socketServiceProvider);
  final controller = StreamController<ServiceRequestRealtimeEvent>.broadcast();

  void onStatus(dynamic data) => controller.add(ServiceRequestRealtimeEvent.statusChanged(Map<String, dynamic>.from(data as Map)));
  void onAssigned(dynamic data) => controller.add(ServiceRequestRealtimeEvent.assigned(Map<String, dynamic>.from(data as Map)));
  void onLocation(dynamic data) => controller.add(ServiceRequestRealtimeEvent.locationUpdated(Map<String, dynamic>.from(data as Map)));

  socket.joinServiceRequest(requestId);
  socket.onStatusChanged(onStatus);
  socket.onAssigned(onAssigned);
  socket.onLocationUpdated(onLocation);

  ref.onDispose(() {
    socket.offStatusChanged(onStatus);
    socket.offAssigned(onAssigned);
    socket.offLocationUpdated(onLocation);
    socket.leaveServiceRequest(requestId);
    controller.close();
  });

  return controller.stream;
});
