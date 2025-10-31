import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/services/api_service.dart';

class LocationModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final int radius;
  final int? branchId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.radius,
    this.branchId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'] ?? '',
      radius: json['radius'] ?? 100,
      branchId: json['branch_id'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'radius': radius,
      'branch_id': branchId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class LocationCheckResult {
  final bool isWithinLocation;
  final List<MatchedLocation> matchedLocations;
  final CurrentPosition currentPosition;

  LocationCheckResult({
    required this.isWithinLocation,
    required this.matchedLocations,
    required this.currentPosition,
  });

  factory LocationCheckResult.fromJson(Map<String, dynamic> json) {
    return LocationCheckResult(
      isWithinLocation: json['is_within_location'] ?? false,
      matchedLocations:
          (json['matched_locations'] as List<dynamic>?)
              ?.map((item) => MatchedLocation.fromJson(item))
              .toList() ??
          [],
      currentPosition: CurrentPosition.fromJson(json['current_position']),
    );
  }
}

class MatchedLocation {
  final int id;
  final String name;
  final String address;
  final int radius;
  final double distance;

  MatchedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.radius,
    required this.distance,
  });

  factory MatchedLocation.fromJson(Map<String, dynamic> json) {
    return MatchedLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'] ?? '',
      radius: json['radius'],
      distance: double.parse(json['distance'].toString()),
    );
  }
}

class CurrentPosition {
  final double latitude;
  final double longitude;

  CurrentPosition({required this.latitude, required this.longitude});

  factory CurrentPosition.fromJson(Map<String, dynamic> json) {
    return CurrentPosition(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}

class LocationService {
  static String get _baseUrl => ApiService.apiBaseUrl;

  /// Add a new location
  static Future<Map<String, dynamic>> addLocation({
    required String name,
    required double latitude,
    required double longitude,
    String address = '',
    int radius = 100,
    int? branchId,
    bool isActive = true,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/location/add');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'radius': radius,
          'branch_id': branchId,
          'is_active': isActive ? 1 : 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add location');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get all locations
  static Future<List<LocationModel>> getLocations({
    int? branchId,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (branchId != null) queryParams['branch_id'] = branchId.toString();
      if (isActive != null) queryParams['is_active'] = isActive ? '1' : '0';

      final url = Uri.parse(
        '$_baseUrl/api/location/list',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List<dynamic>)
              .map((item) => LocationModel.fromJson(item))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get locations');
        }
      } else {
        throw Exception('Failed to get locations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update a location
  static Future<Map<String, dynamic>> updateLocation({
    required int id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    int? radius,
    int? branchId,
    bool? isActive,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/location/update/$id');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (address != null) updateData['address'] = address;
      if (radius != null) updateData['radius'] = radius;
      if (branchId != null) updateData['branch_id'] = branchId;
      if (isActive != null) updateData['is_active'] = isActive ? 1 : 0;

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Delete a location
  static Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/api/location/delete/$id');

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete location');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if current location is within any registered location
  static Future<LocationCheckResult> checkLocation({
    required double latitude,
    required double longitude,
    int? branchId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/location/check');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'branch_id': branchId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return LocationCheckResult.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to check location');
        }
      } else {
        throw Exception('Failed to check location');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get location by ID
  static Future<LocationModel> getLocationById(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/api/location/get/$id');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return LocationModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Location not found');
        }
      } else {
        throw Exception('Failed to get location');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get locations within radius
  static Future<List<LocationModel>> getLocationsWithinRadius({
    required double latitude,
    required double longitude,
    int radius = 1000,
    int? branchId,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      };
      if (branchId != null) queryParams['branch_id'] = branchId.toString();

      final url = Uri.parse(
        '$_baseUrl/api/location/within-radius',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List<dynamic>)
              .map((item) => LocationModel.fromJson(item))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get locations');
        }
      } else {
        throw Exception('Failed to get locations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
