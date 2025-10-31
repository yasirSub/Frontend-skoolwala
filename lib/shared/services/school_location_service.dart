import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/services/api_service.dart';

class SchoolLocationModel {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;
  final int radius;
  final int schoolId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SchoolLocationModel({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.radius,
    required this.schoolId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SchoolLocationModel.fromJson(Map<String, dynamic> json) {
    return SchoolLocationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      name: json['name'] ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      address: json['address'] ?? '',
      radius: json['radius'] is int
          ? json['radius']
          : int.tryParse(json['radius'].toString()) ?? 100,
      schoolId: json['school_id'] is int
          ? json['school_id']
          : int.tryParse(json['school_id'].toString()) ?? 1,
      isActive:
          json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == '1',
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
      'school_id': schoolId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SchoolLocationCheckResult {
  final bool isWithinLocation;
  final List<MatchedSchoolLocation> matchedLocations;
  final CurrentPosition currentPosition;

  SchoolLocationCheckResult({
    required this.isWithinLocation,
    required this.matchedLocations,
    required this.currentPosition,
  });

  factory SchoolLocationCheckResult.fromJson(Map<String, dynamic> json) {
    return SchoolLocationCheckResult(
      isWithinLocation: json['is_within_location'] ?? false,
      matchedLocations:
          (json['matched_locations'] as List<dynamic>?)
              ?.map((item) => MatchedSchoolLocation.fromJson(item))
              .toList() ??
          [],
      currentPosition: CurrentPosition.fromJson(json['current_position']),
    );
  }
}

class MatchedSchoolLocation {
  final int id;
  final String name;
  final String address;
  final int radius;
  final double distance;

  MatchedSchoolLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.radius,
    required this.distance,
  });

  factory MatchedSchoolLocation.fromJson(Map<String, dynamic> json) {
    return MatchedSchoolLocation(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      radius: json['radius'] is int
          ? json['radius']
          : int.tryParse(json['radius'].toString()) ?? 100,
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

class SchoolLocationService {
  static String get _baseUrl => ApiService.apiBaseUrl;
  static const bool _debugLogs = false; // disable verbose logs

  /// Set/Add a school location
  static Future<Map<String, dynamic>> setLocation({
    required String name,
    required double latitude,
    required double longitude,
    String address = '',
    int radius = 100,
    int schoolId = 1,
    bool isActive = true,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/school-location/set');
      final requestBody = {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'radius': radius,
        'school_id': schoolId,
        'is_active': isActive ? 1 : 0,
      };

      if (_debugLogs) {
        print('🌐 API Call: POST $url');
        print('📤 Request Body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (_debugLogs) {
        print('📥 Response Status: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (_debugLogs) print('✅ API Success: ${data['status']} - ${data['message']}');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        if (_debugLogs) print('❌ API Error: ${errorData['message']}');
        throw Exception(
          errorData['message'] ?? 'Failed to set school location',
        );
      }
    } catch (e) {
      print('❌ Network Error: $e');
      throw Exception('Network error: $e');
    }
  }

  /// Get all school locations
  static Future<List<SchoolLocationModel>> getSchoolLocations({
    int schoolId = 1,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{'school_id': schoolId.toString()};
      if (isActive != null) queryParams['is_active'] = isActive ? '1' : '0';

      final url = Uri.parse(
        '$_baseUrl/school-location/list',
      ).replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List<dynamic>)
              .map((item) => SchoolLocationModel.fromJson(item))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to get school locations');
        }
      } else {
        throw Exception('Failed to get school locations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if current location is within any school location
  static Future<SchoolLocationCheckResult> checkLocation({
    required double latitude,
    required double longitude,
    int schoolId = 1,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/school-location/check');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'school_id': schoolId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return SchoolLocationCheckResult.fromJson(data['data']);
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

  /// Delete a school location
  static Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final url = Uri.parse('$_baseUrl/school-location/delete/$id');

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to delete school location',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
