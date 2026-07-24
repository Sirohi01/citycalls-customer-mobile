import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_client.dart';

// One shared Socket.IO connection per app session, lazily connected on first
// use (not at app boot) — most screens never need it, so there's no reason
// to hold a live socket open from launch. Mirrors citycalls-api's
// src/realtime/index.ts: JWT handshake auth, `service-request:{id}` rooms
// joined/left explicitly per-screen rather than auto-joined at connection.
class SocketService {
  final ApiClient _client;
  io.Socket? _socket;

  SocketService(this._client);

  Future<io.Socket> _ensureConnected() async {
    // Deliberately keyed on "does a socket object exist" rather than
    // "is it currently connected" — the handshake is async, so a second
    // caller landing here microseconds after the first (e.g. join + three
    // on*Updated registrations firing back to back) would otherwise see
    // `connected == false` and spin up a second competing socket before the
    // first one finishes connecting. socket.io-client handles reconnects on
    // its own once a socket object exists.
    final existing = _socket;
    if (existing != null) return existing;

    final token = await _client.readAccessToken();
    final socket = io.io(
      _client.apiOrigin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;
    socket.connect();
    return socket;
  }

  // Called on logout — a stale socket would otherwise keep running under the
  // previous account's JWT for the rest of this app process's lifetime,
  // since SocketService itself is a long-lived singleton Provider.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  Future<void> joinServiceRequest(String serviceRequestId) async {
    final socket = await _ensureConnected();
    socket.emit('service-request:join', serviceRequestId);
  }

  void leaveServiceRequest(String serviceRequestId) {
    _socket?.emit('service-request:leave', serviceRequestId);
  }

  Future<void> onStatusChanged(void Function(dynamic) handler) async {
    final socket = await _ensureConnected();
    socket.on('service-request.status-changed', handler);
  }

  Future<void> onAssigned(void Function(dynamic) handler) async {
    final socket = await _ensureConnected();
    socket.on('service-request.assigned', handler);
  }

  Future<void> onLocationUpdated(void Function(dynamic) handler) async {
    final socket = await _ensureConnected();
    socket.on('technician.location-updated', handler);
  }

  void offStatusChanged(void Function(dynamic) handler) => _socket?.off('service-request.status-changed', handler);
  void offAssigned(void Function(dynamic) handler) => _socket?.off('service-request.assigned', handler);
  void offLocationUpdated(void Function(dynamic) handler) => _socket?.off('technician.location-updated', handler);
}
