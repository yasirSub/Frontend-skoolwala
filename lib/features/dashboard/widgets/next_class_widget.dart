import 'package:flutter/material.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'dart:async';

/// Widget showing next upcoming class countdown
/// Only displays if teacher is present in school
class NextClassWidget extends StatefulWidget {
  const NextClassWidget({super.key});

  @override
  State<NextClassWidget> createState() => _NextClassWidgetState();
}

class _NextClassWidgetState extends State<NextClassWidget> {
  Map<String, dynamic>? _nextClassData;
  bool _isPresent = false;
  bool _isLoading = true;
  Timer? _updateTimer;
  Timer? _countdownTimer;
  DateTime? _classStartTime;
  int _minutesUntil = 0;

  @override
  void initState() {
    super.initState();
    _loadNextClass();

    // Reload class data every 5 minutes (in case schedule changes)
    _updateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadNextClass(),
    );

    // Update countdown every 10 seconds for smooth updates
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNextClass() async {
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
        final nextClass = response['data']['next_class'];

        // Parse class start time for local countdown calculation
        DateTime? classStartTime;
        if (nextClass != null && nextClass['start_time'] != null) {
          try {
            final startTimeStr = nextClass['start_time'] as String;
            final timeParts = startTimeStr.split(':');
            if (timeParts.length >= 2) {
              final now = DateTime.now();
              final hour = int.tryParse(timeParts[0].trim()) ?? 0;
              final minute = int.tryParse(timeParts[1].trim()) ?? 0;

              // Create datetime for class start time today
              classStartTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
              );

              // If class time has already passed today, don't show it
              // API should only return future classes for today
              if (classStartTime.isBefore(
                now.subtract(const Duration(minutes: 1)),
              )) {
                print(
                  '⚠️ Class time has passed: ${classStartTime.toString()} vs now: ${now.toString()}',
                );
                // Don't set classStartTime, widget will hide
                classStartTime = null;
              } else {
                print(
                  '✅ Next class at: ${classStartTime.toString()}, Current time: ${now.toString()}',
                );
                print(
                  '   Minutes until: ${classStartTime.difference(now).inMinutes}',
                );
              }
            }
          } catch (e) {
            print('Error parsing class start time: $e');
          }
        }

        setState(() {
          _isPresent = isPresent;
          _nextClassData = nextClass;
          _classStartTime = classStartTime;
          _isLoading = false;
        });

        // Update countdown immediately
        _updateCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading next class: $e');
    }
  }

  void _updateCountdown() {
    if (_classStartTime == null || !_isPresent || _nextClassData == null) {
      return;
    }

    final now = DateTime.now();

    // Ensure we're comparing same day
    if (_classStartTime!.day != now.day ||
        _classStartTime!.month != now.month ||
        _classStartTime!.year != now.year) {
      // Different day, reload to get today's classes
      if (mounted) {
        _loadNextClass();
      }
      return;
    }

    final difference = _classStartTime!.difference(now);
    final minutesUntil = difference.inMinutes;

    // Show if class is coming in next 120 minutes (2 hours) or more
    // Hide only if class has started or passed
    if (minutesUntil >= 0 && mounted) {
      setState(() {
        _minutesUntil = minutesUntil;
      });
    } else if (mounted) {
      // Class has passed - hide widget and reload to get next class
      setState(() {
        _minutesUntil = -1; // Hide widget
      });

      // If class has passed, reload to get next class
      if (minutesUntil < 0) {
        print('🔄 Class has passed, reloading next class...');
        _loadNextClass();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Only show if:
    // 1. Teacher is present
    // 2. Has upcoming class
    // 3. Class is coming up (within next 2 hours)
    if (!_isPresent ||
        _nextClassData == null ||
        _minutesUntil < 0 ||
        _minutesUntil >= 120) {
      return const SizedBox.shrink();
    }

    final className = _nextClassData!['class_section'] ?? 'Class';
    final timeDisplay = _nextClassData!['time_display'] ?? '';
    final roomNumber = _nextClassData!['room_number'] ?? 'TBA';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.orange.shade500, Colors.orange.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
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
            child: const Icon(Icons.access_time, color: Colors.white, size: 24),
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
                        'UPCOMING',
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
                        '$_minutesUntil min',
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
                  'After $_minutesUntil ${_minutesUntil == 1 ? 'minute' : 'minutes'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  className,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
