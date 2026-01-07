import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/models/teacher.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';

/// Working Timer Card Widget
/// Displays elapsed time since check-in with optional checkout
class WorkingTimerCard extends StatefulWidget {
  final Teacher? teacher;
  @override
  final GlobalKey<WorkingTimerCardState>? key;

  const WorkingTimerCard({this.key, required this.teacher}) : super(key: key);

  @override
  State<WorkingTimerCard> createState() => WorkingTimerCardState();
}

class WorkingTimerCardState extends State<WorkingTimerCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _checkInTime;
  bool _isCheckedIn = false;
  bool _isLoading = true;
  bool _isExpanded = false;

  // Animation controller for click animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

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
    _animationController.dispose();
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
            _isCheckedIn =
                todayStatus['status'] == 'P' &&
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        ),
      );
    }

    if (!_isCheckedIn) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            print('🕐 Timer Debug - Clock clicked, starting animation');
            // Animate on click
            _animationController.forward().then((_) {
              _animationController.reverse();
            });

            // Refresh timer data on click
            refreshTimer();
          },
          behavior: HitTestBehavior.opaque,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.25),
                    AppTheme.darkPurple.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Status indicator dot
                  _PulsingDot(color: Colors.green),
                  const SizedBox(width: 12),
                  // Timer display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WORKING TIME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(_elapsedTime),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Check-in time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'CHECKED IN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '${_checkInTime?.hour.toString().padLeft(2, '0')}:${_checkInTime?.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkOut() async {
    if (widget.teacher == null) return;

    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.lowest,
            timeLimit: Duration(seconds: 3),
          ),
        );
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

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  _PulsingDotState createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
