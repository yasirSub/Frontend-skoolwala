import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/models/teacher.dart';

/// Working Timer Card Widget
/// Displays elapsed time since check-in with optional checkout
class WorkingTimerCard extends StatefulWidget {
  final Teacher? teacher;
  final GlobalKey<WorkingTimerCardState>? key;

  const WorkingTimerCard({this.key, required this.teacher}) : super(key: key);

  @override
  State<WorkingTimerCard> createState() => WorkingTimerCardState();
}

class WorkingTimerCardState extends State<WorkingTimerCard> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _checkInTime;
  bool _isCheckedIn = false;
  bool _isLoading = true;
  bool _isExpanded = false;

  // Method to refresh timer data
  void refreshTimer() {
    print('🕐 Timer Debug - Manual refresh called');
    setState(() {
      _isLoading = true;
    });
    _loadTodayStatus();
  }

  @override
  void initState() {
    super.initState();
    _loadTodayStatus();
  }

  @override
  void didUpdateWidget(WorkingTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teacher?.id != widget.teacher?.id) {
      _loadTodayStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayStatus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodayStatus() async {
    if (widget.teacher == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final baseUrl = ApiConfig.getBaseUrl();
      final url = Uri.parse(
        '$baseUrl/getTeacherSelfAttendanceStats?staff_id=${widget.teacher!.id}&filter_type=month&filter_value=${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final todayStatus = data['data']['today_status'];

          setState(() {
            _isCheckedIn = todayStatus['status'] == 'P' &&
                todayStatus['check_in_time'] != null;
            if (_isCheckedIn) {
              _checkInTime = _parseTime(todayStatus['check_in_time']);
              _startTimer();
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading today status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseTime(String? timeString) {
    if (timeString == null) return null;

    try {
      final now = DateTime.now();

      if (timeString.contains('AM') || timeString.contains('PM')) {
        final parts = timeString.split(' ');
        final timePart = parts[0];
        final period = parts[1];

        final timeParts = timePart.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;

          if (period == 'PM' && hour != 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }

          return DateTime(now.year, now.month, now.day, hour, minute, second);
        }
      } else {
        final timeParts = timeString.split(':');
        if (timeParts.length >= 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;
          return DateTime(now.year, now.month, now.day, hour, minute, second);
        }
      }
    } catch (e) {
      // Error parsing time
    }
    return null;
  }

  void _startTimer() {
    if (_checkInTime == null) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final now = DateTime.now();
        final elapsed = now.difference(_checkInTime!);
        setState(() {
          _elapsedTime = elapsed;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${totalMinutes}:${seconds.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_isCheckedIn) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.15),
            Colors.green.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Working Timer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Checked in at ${_checkInTime?.hour.toString().padLeft(2, '0')}:${_checkInTime?.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_filled, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_elapsedTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, color: Colors.green[700], size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Working since ${_checkInTime?.hour.toString().padLeft(2, '0')}:${_checkInTime?.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _checkOut() async {
    if (widget.teacher == null) return;

    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.lowest,
              timeLimit: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Location error during checkout: $e');
      }

      final checkoutData = {
        'staff_id': widget.teacher!.id,
        'validated_face': true,
        'attendance_type': 'check_out',
        'user_latitude': position?.latitude,
        'user_longitude': position?.longitude,
      };

      final baseUrl = ApiConfig.getBaseUrl();
      final url = Uri.parse('$baseUrl/attendanceForTeacher');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(checkoutData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Checked out successfully at ${data['time']}'),
              backgroundColor: Colors.green,
            ),
          );

          _timer?.cancel();
          setState(() {
            _isCheckedIn = false;
            _isExpanded = false;
            _elapsedTime = Duration.zero;
            _checkInTime = null;
          });

          await _loadTodayStatus();
        } else {
          throw Exception(data['message'] ?? 'Checkout failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Checkout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

