import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// Human-readable current location ("Area, City"), or null when location is
// off, permission is denied, or the lookup fails — callers fall back to the
// customer's saved default address.
final currentLocationProvider = FutureProvider<String?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;

    final parts = [
      p.subLocality,
      p.locality,
      p.administrativeArea,
    ].where((s) => s != null && s.isNotEmpty).cast<String>().toSet().toList();
    if (parts.isEmpty) return null;
    return parts.take(2).join(', ');
  } catch (_) {
    return null;
  }
});
