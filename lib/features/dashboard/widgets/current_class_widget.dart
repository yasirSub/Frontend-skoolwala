import 'package:flutter/material.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'dart:async';

/// Widget showing current ongoing class with countdown to end
/// Only displays if teacher is present in school
class CurrentClassWidget extends StatefulWidget {
  const CurrentClassWidget({super.key});

  @override
  State<CurrentClassWidget> createState() => _CurrentClassWidgetState();
}

class _CurrentClassWidgetState extends State<CurrentClassWidget> {
  Map<String, dynamic>? _currentClassData;
  bool _isPresent = false;
  bool _isLoading = true;
  Timer? _updateTimer;
  Timer? _countdownTimer;
  DateTime? _classEndTime;
  int _minutesUntilEnd = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentClass();

    // Reload class data every 5 minutes
    _updateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadCurrentClass(),
    );

    // Update countdown EVERY SECOND for real-time display
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentClass() async {
    try {
      final authData = SessionManager.instance.getAuthBody();

      final response = await HttpClient().postJson(
        ApiConfig.getNextUpcomingClass,
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      if (mounted && response['status'] == 'success') {
        final isPresent = response['data']['is_present'] ?? false;
        final currentClass = response['data']['current_class'];

        DateTime? classEndTime;
        if (currentClass != null && currentClass['end_time'] != null) {
          try {
            final endTimeStr = currentClass['end_time'] as String;
            final timeParts = endTimeStr.split(':');
            if (timeParts.length >= 2) {
              final now = DateTime.now();
              final hour = int.tryParse(timeParts[0].trim()) ?? 0;
              final minute = int.tryParse(timeParts[1].trim()) ?? 0;

              classEndTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
              );
            }
          } catch (e) {
            print('Error parsing class end time: $e');
          }
        }

        setState(() {
          _isPresent = isPresent;
          _currentClassData = currentClass;
          _classEndTime = classEndTime;
          _isLoading = false;
        });

        _updateCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading current class: $e');
    }
  }

  void _updateCountdown() {
    if (_classEndTime == null || !_isPresent || _currentClassData == null) {
      return;
    }

    final now = DateTime.now();

    if (_classEndTime!.day != now.day ||
        _classEndTime!.month != now.month ||
        _classEndTime!.year != now.year) {
      if (mounted) {
        _loadCurrentClass();
      }
      return;
    }

    final difference = _classEndTime!.difference(now);
    final minutesUntil = difference.inMinutes;
    final secondsUntil = difference.inSeconds % 60;

    if (minutesUntil >= 0 && mounted) {
      setState(() {
        _minutesUntilEnd = minutesUntil;
      });
      print('⏱️ Class ends in: $_minutesUntilEnd min $secondsUntil sec');
    } else if (mounted) {
      // Class has ended, reload
      print('✅ Class has ended, reloading...');
      _loadCurrentClass();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Only show if teacher is present and has current class
    if (!_isPresent || _currentClassData == null || _minutesUntilEnd < 0) {
      return const SizedBox.shrink();
    }

    final className = _currentClassData!['class_section'] ?? 'Class';
    final timeDisplay = _currentClassData!['time_display'] ?? '';
    final roomNumber = _currentClassData!['room_number'] ?? 'TBA';
    final subjectName = _currentClassData!['subject_name'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade500, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ONGOING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_minutesUntilEnd min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subjectName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subjectName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      roomNumber,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
