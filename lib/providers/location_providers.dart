import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../data/permission_queue.dart';

enum LocationAccess { granted, serviceOff, denied, deniedForever }

// Asks for location permission (the OS prompt shows right away on first use,
// even while the GPS switch is off) and reports what the app can do next, so
// callers can send the user to the right settings page instead of failing
// silently.
Future<LocationAccess> ensureLocationAccess() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await PermissionQueue.run(Geolocator.requestPermission);
  }
  if (permission == LocationPermission.deniedForever) {
    return LocationAccess.deniedForever;
  }
  if (permission == LocationPermission.denied) return LocationAccess.denied;
  if (!await Geolocator.isLocationServiceEnabled()) {
    return LocationAccess.serviceOff;
  }
  return LocationAccess.granted;
}

// Where the customer is standing right now, resolved to an address.
class CurrentPlace {
  /// "Area, City" — the short text shown in the top bar.
  final String label;
  final String? line1;
  final String? line2;
  final String city;
  final String state;
  final String pinCode;
  final double latitude;
  final double longitude;

  const CurrentPlace({
    required this.label,
    this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
  });

  // Geocoders don't always return a postal code; without a valid one the
  // place can't be used for the PIN-based availability check.
  bool get hasPin => RegExp(r'^\d{6}$').hasMatch(pinCode);
}

// Null when location is off, permission is denied, or the lookup fails —
// callers fall back to the customer's saved default address.
final currentPlaceProvider = FutureProvider<CurrentPlace?>((ref) async {
  try {
    if (await ensureLocationAccess() != LocationAccess.granted) return null;

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // A cold GPS can miss the window indoors; the last fix is still good
      // enough to name the area.
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      position = last;
    }

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude)
            .timeout(const Duration(seconds: 8));
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;

    String? clean(String? s) {
      final t = s?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    final labelParts = [p.subLocality, p.locality, p.administrativeArea]
        .map(clean)
        .whereType<String>()
        .toSet()
        .toList();
    if (labelParts.isEmpty) return null;

    final lineParts =
        [p.name, p.street].map(clean).whereType<String>().toSet().toList();
    final areaParts =
        [p.subLocality, p.locality].map(clean).whereType<String>().toSet();
    final pin = RegExp(r'\d{6}').firstMatch(p.postalCode ?? '')?.group(0) ?? '';

    return CurrentPlace(
      label: labelParts.take(2).join(', '),
      line1: lineParts.isEmpty ? null : lineParts.join(', '),
      line2: areaParts.isEmpty ? null : areaParts.join(', '),
      city: clean(p.locality) ?? clean(p.subAdministrativeArea) ?? '',
      state: clean(p.administrativeArea) ?? '',
      pinCode: pin,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  } catch (_) {
    return null;
  }
});

// Human-readable current location ("Area, City") for the top bar.
final currentLocationProvider = FutureProvider<String?>((ref) async {
  return (await ref.watch(currentPlaceProvider.future))?.label;
});
