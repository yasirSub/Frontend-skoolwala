import 'package:geolocator/geolocator.dart';

class LocationWorkflow {
  const LocationWorkflow._();

  static Future<Position?> tryResolvePosition() async {
    // Try last known first
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) return lastKnown;

    // Try medium accuracy quick attempt
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 3),
        ),
      );
    } catch (_) {}

    // Fallback: high accuracy longer timeout
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {}

    return null;
  }
}
