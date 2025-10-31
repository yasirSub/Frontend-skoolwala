import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:skoolwala/shared/services/http_client.dart';

class LocationService {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 LocationService: Location services enabled: $serviceEnabled');
      return serviceEnabled;
    } catch (e) {
      print('❌ LocationService: Error checking location services - $e');
      return false;
    }
  }

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('📍 LocationService: Location permissions denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('📍 LocationService: Location permissions permanently denied');
        return false;
      }

      print('📍 LocationService: Location permission granted');
      return true;
    } catch (e) {
      print('❌ LocationService: Error requesting location permission - $e');
      return false;
    }
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      print('📍 LocationService: Has location permission: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('❌ LocationService: Error checking location permission - $e');
      return false;
    }
  }

  /// Get current location
  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ LocationService: Location services are disabled');
        return null;
      }

      // Check permissions
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        bool granted = await requestLocationPermission();
        if (!granted) {
          print('❌ LocationService: Location permission denied');
          return null;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
        // ignore: deprecated_member_use
        timeLimit: Duration(seconds: 10),
      );

      final location = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'heading': position.heading,
      };

      print(
        '📍 LocationService: Current location - ${location['latitude']}, ${location['longitude']} (accuracy: ${location['accuracy']}m)',
      );
      return location;
    } catch (e) {
      print('❌ LocationService: Error getting current location - $e');
      return null;
    }
  }

  /// Calculate distance between two points (in meters) - simple implementation
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Simple Haversine formula for distance calculation
    const double earthRadius = 6371000; // Earth's radius in meters

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Helper method to convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Check if current location is within school radius
  static Future<bool> isWithinSchoolRadius({
    required double schoolLat,
    required double schoolLon,
    double maxDistanceMeters = 100.0,
  }) async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return false;
      }

      final distance = calculateDistance(
        position['latitude']!,
        position['longitude']!,
        schoolLat,
        schoolLon,
      );

      print(
        '📍 LocationService: Distance from school: ${distance.toStringAsFixed(2)}m',
      );
      return distance <= maxDistanceMeters;
    } catch (e) {
      print('❌ LocationService: Error checking school radius - $e');
      return false;
    }
  }

  /// Get location data as JSON
  static Future<Map<String, dynamic>?> getLocationData() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return null;
      }

      return {
        'latitude': position['latitude'],
        'longitude': position['longitude'],
        'accuracy': position['accuracy'],
        'altitude': position['altitude'],
        'speed': position['speed'],
        'timestamp': position['timestamp'],
        'heading': position['heading'],
      };
    } catch (e) {
      print('❌ LocationService: Error getting location data - $e');
      return null;
    }
  }

  /// Verify location with backend API
  static Future<Map<String, dynamic>> verifyLocationWithAPI({
    required String staffId,
    required String branchId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // If coordinates not provided, get current location
      if (latitude == null || longitude == null) {
        final location = await getCurrentLocation();
        if (location == null) {
          return {
            'verified': false,
            'message': 'Unable to get current location',
            'error': 'LOCATION_UNAVAILABLE',
          };
        }
        latitude = location['latitude'];
        longitude = location['longitude'];
      }

      // Import the API service
      final apiService = await _getApiService();

      // Call the location verification API
      final response = await apiService.postJson(
        'location-attendance/verify',
        body: {
          'staff_id': staffId,
          'branch_id': branchId,
          'user_latitude': latitude,
          'user_longitude': longitude,
        },
      );

      if (response['status'] == 'success') {
        return {
          'verified': response['verified'] ?? false,
          'message': response['message'] ?? '',
          'data': response['data'] ?? {},
        };
      } else {
        return {
          'verified': false,
          'message': response['message'] ?? 'Location verification failed',
          'error': 'API_ERROR',
        };
      }
    } catch (e) {
      print('❌ LocationService: Error verifying location with API - $e');
      return {
        'verified': false,
        'message': 'Location verification failed: $e',
        'error': 'NETWORK_ERROR',
      };
    }
  }

  /// Get allowed locations for a branch
  static Future<List<Map<String, dynamic>>> getBranchLocations(
    String branchId,
  ) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get(
        'location-attendance/locations/$branchId',
      );

      if (response['status'] == 'success') {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      } else {
        print(
          '❌ LocationService: Error fetching branch locations - ${response['message']}',
        );
        return [];
      }
    } catch (e) {
      print('❌ LocationService: Error getting branch locations - $e');
      return [];
    }
  }

  /// Get location-based attendance settings for a branch
  static Future<Map<String, dynamic>?> getBranchLocationSettings(
    String branchId,
  ) async {
    try {
      final apiService = await _getApiService();
      final response = await apiService.get(
        'location-attendance/settings/$branchId',
      );

      if (response['status'] == 'success') {
        return response['data'];
      } else {
        print(
          '❌ LocationService: Error fetching branch settings - ${response['message']}',
        );
        return null;
      }
    } catch (e) {
      print('❌ LocationService: Error getting branch settings - $e');
      return null;
    }
  }

  /// Check if location verification is required for attendance
  static Future<bool> isLocationVerificationRequired(String branchId) async {
    try {
      final settings = await getBranchLocationSettings(branchId);
      return settings?['location_verification_enabled'] == 1;
    } catch (e) {
      print(
        '❌ LocationService: Error checking if location verification is required - $e',
      );
      return false;
    }
  }

  /// Helper method to get API service instance
  static Future<dynamic> _getApiService() async {
    // Use HttpClient directly to avoid circular imports
    return HttpClient();
  }
}
