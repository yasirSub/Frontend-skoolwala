// ignore_for_file: unused_import, unused_field

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced local storage for face data and embeddings
/// Handles both temporary storage and secure embedding storage
class LocalFaceStorage {
  static const String _fileName = 'face_data.json';
  static const String _embeddingsKey = 'face_embeddings';

  /// Save face data locally
  static Future<void> saveFaceData({
    required String faceData,
    required String action,
    required String status,
    DateTime? timestamp,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      final faceRecord = {
        'face_data': faceData,
        'action': action,
        'status': status,
        'timestamp':
            timestamp?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'processed': false, // Mark as not sent to API yet
      };

      // Read existing data
      List<Map<String, dynamic>> existingData = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        existingData = List<Map<String, dynamic>>.from(json.decode(content));
      }

      // Add new record
      existingData.add(faceRecord);

      // Save back to file
      await file.writeAsString(json.encode(existingData));

      print('💾 Face data saved locally: ${faceRecord['timestamp']}');
    } catch (e) {
      print('❌ Failed to save face data locally: $e');
    }
  }

  /// Get all stored face data
  static Future<List<Map<String, dynamic>>> getAllFaceData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(json.decode(content));
    } catch (e) {
      print('❌ Failed to read face data: $e');
      return [];
    }
  }

  /// Get unprocessed face data (not sent to API yet)
  static Future<List<Map<String, dynamic>>> getUnprocessedFaceData() async {
    final allData = await getAllFaceData();
    return allData.where((record) => record['processed'] == false).toList();
  }

  /// Mark face data as processed (sent to API)
  static Future<void> markAsProcessed(String timestamp) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (!await file.exists()) {
        return;
      }

      final content = await file.readAsString();
      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(
        json.decode(content),
      );

      // Find and mark the record as processed
      for (int i = 0; i < data.length; i++) {
        if (data[i]['timestamp'] == timestamp) {
          data[i]['processed'] = true;
          break;
        }
      }

      // Save back to file
      await file.writeAsString(json.encode(data));
      print('✅ Face data marked as processed: $timestamp');
    } catch (e) {
      print('❌ Failed to mark face data as processed: $e');
    }
  }

  /// Clear all face data (use with caution)
  static Future<void> clearAllFaceData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        await file.delete();
        print('🗑️ All face data cleared');
      }
    } catch (e) {
      print('❌ Failed to clear face data: $e');
    }
  }

  /// Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    final allData = await getAllFaceData();
    final unprocessedData = await getUnprocessedFaceData();

    return {
      'total_records': allData.length,
      'unprocessed_records': unprocessedData.length,
      'processed_records': allData.length - unprocessedData.length,
      'latest_record': allData.isNotEmpty ? allData.last['timestamp'] : null,
    };
  }
}
