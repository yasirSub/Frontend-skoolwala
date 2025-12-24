import 'package:flutter/material.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/features/teacher/screens/teacher_schedule_screen.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/animations/loading_animations.dart';
import 'dart:async';

/// Single widget showing either current ongoing class or next upcoming class
/// Automatically switches based on what's available
/// Shows current class if ongoing, otherwise shows next class
class SingleClassWidget extends StatefulWidget {
  const SingleClassWidget({super.key});

  @override
  State<SingleClassWidget> createState() => _SingleClassWidgetState();
}

class _SingleClassWidgetState extends State<SingleClassWidget> {
  Map<String, dynamic>? _displayedClass;
  bool _isCurrentClass =
      false; // true if showing current, false if showing next
  bool _isLoading = true;
  Timer? _updateTimer;
  Timer? _countdownTimer;
  DateTime? _countdownEndTime; // When to end the countdown (class end or start)
  DateTime? _lastApiTime; // Store the database time from API
  DateTime? _apiTimeReceivedAt; // When the API time was received

  /// Get current synced time based on server time and elapsed local time
  DateTime get _currentSyncTime {
    if (_lastApiTime == null || _apiTimeReceivedAt == null) {
      return DateTime.now();
    }
    final elapsed = DateTime.now().difference(_apiTimeReceivedAt!);
    return _lastApiTime!.add(elapsed);
  }

  // For swipe functionality
  List<Map<String, dynamic>> _allClasses = [];
  int _currentClassIndex = 0;
  late PageController _pageController;
  int?
  _lastPriorityClassId; // Track the ID of the priority class to detect changes
  bool _hasInitialLoad = false; // Track if we've done the initial load/jump

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadClassData();

    // Reload class data every 1 minute for faster updates when classes end
    _updateTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadClassData(),
    );

    // Update countdown every second for real-time display
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadClassData() async {
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
        final currentClass = response['data']['current_class'];
        final nextClass = response['data']['next_class'];

        // Get all classes for today if available
        List<Map<String, dynamic>> allClasses = [];
        if (response['data']['all_classes'] is List) {
          allClasses = List<Map<String, dynamic>>.from(
            response['data']['all_classes'] ?? [],
          );
        } else {
          // Fallback: build list from current and next classes
          if (currentClass != null) allClasses.add(currentClass);
          if (nextClass != null) allClasses.add(nextClass);
        }

        // Sort classes by start_time (chronological order)
        allClasses.sort((a, b) {
          final aStartTime = a['start_time'] as String?;
          final bStartTime = b['start_time'] as String?;
          if (aStartTime == null || bStartTime == null) return 0;

          final aParts = aStartTime.split(':');
          final bParts = bStartTime.split(':');
          final aHour = int.tryParse(aParts[0]) ?? 0;
          final aMin = int.tryParse(aParts[1]) ?? 0;
          final bHour = int.tryParse(bParts[0]) ?? 0;
          final bMin = int.tryParse(bParts[1]) ?? 0;

          if (aHour != bHour) return aHour.compareTo(bHour);
          return aMin.compareTo(bMin);
        });

        // Store the API response time to use for countdown calculations
        final debugInfo = response['data']['debug'] ?? {};
        DateTime? apiTime;
        if (debugInfo['current_time'] != null) {
          try {
            final timeStr = debugInfo['current_time'] as String;
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              final now = DateTime.now();
              final hour = int.tryParse(timeParts[0].trim()) ?? 0;
              final minute = int.tryParse(timeParts[1].trim()) ?? 0;
              final second = timeParts.length >= 3
                  ? int.tryParse(timeParts[2].trim()) ?? 0
                  : 0;
              apiTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
                second,
              );
            }
          } catch (e) {
            print('Error parsing API time: $e');
          }
        }
        // Decide which class to display based on priority
        // Priority: ONGOING > UPCOMING > COMPLETED
        Map<String, dynamic>? displayClass;
        bool isCurrent = false;
        DateTime? countdownTime;

        // Use API time if available, otherwise use device time
        final currentTime = apiTime ?? DateTime.now();

        // Find ONGOING class (highest priority) - check all classes
        Map<String, dynamic>? ongoingClass;
        for (final classData in allClasses) {
          final startTimeStr = classData['start_time'] as String?;
          final endTimeStr = classData['end_time'] as String?;
          if (startTimeStr != null && endTimeStr != null) {
            final classStartTime = _parseTimeToDateTime(startTimeStr);
            final classEndTime = _parseTimeToDateTime(endTimeStr);
            if (classStartTime != null && classEndTime != null) {
              final hasStarted = !currentTime.isBefore(classStartTime);
              final hasEnded = currentTime.isAfter(classEndTime);

              if (hasStarted && !hasEnded) {
                ongoingClass = classData;
                break;
              }
            }
          }
        }

        // Find UPCOMING class (second priority)
        Map<String, dynamic>? upcomingClass;
        if (ongoingClass == null) {
          for (final classData in allClasses) {
            final startTimeStr = classData['start_time'] as String?;
            if (startTimeStr != null) {
              final classStartTime = _parseTimeToDateTime(startTimeStr);
              if (classStartTime != null &&
                  currentTime.isBefore(classStartTime)) {
                upcomingClass = classData;
                break;
              }
            }
          }
        }

        // Find COMPLETED class (third priority - most recent one)
        Map<String, dynamic>? completedClass;
        if (ongoingClass == null && upcomingClass == null) {
          for (int i = allClasses.length - 1; i >= 0; i--) {
            final classData = allClasses[i];
            final endTimeStr = classData['end_time'] as String?;
            if (endTimeStr != null) {
              final classEndTime = _parseTimeToDateTime(endTimeStr);
              if (classEndTime != null && currentTime.isAfter(classEndTime)) {
                completedClass = classData;
                break;
              }
            }
          }
        }

        // Set display class based on priority
        if (ongoingClass != null) {
          displayClass = ongoingClass;
          isCurrent = true;
          if (ongoingClass['end_time'] != null) {
            countdownTime = _parseTimeToDateTime(ongoingClass['end_time']);
          }
        } else if (upcomingClass != null) {
          displayClass = upcomingClass;
          isCurrent = false;
          if (upcomingClass['start_time'] != null) {
            countdownTime = _parseTimeToDateTime(upcomingClass['start_time']);
          }
        } else if (completedClass != null) {
          displayClass = completedClass;
          isCurrent = false;
          if (completedClass['end_time'] != null) {
            countdownTime = _parseTimeToDateTime(completedClass['end_time']);
          }
        }

        // Find the index of the display class in allClasses
        int displayClassIndex = 0;
        if (displayClass != null) {
          for (int i = 0; i < allClasses.length; i++) {
            if (allClasses[i]['id'] == displayClass['id']) {
              displayClassIndex = i;
              break;
            }
          }
        }

        // Determine if we should jump to the priority class
        // Jump if:
        // 1. It's the first load
        // 2. The priority class has changed (e.g. previous class ended, new one started)
        bool shouldJump = false;
        final currentPriorityClassId = displayClass?['id'];

        if (!_hasInitialLoad) {
          shouldJump = true;
          _hasInitialLoad = true;
          _lastPriorityClassId = currentPriorityClassId;
        } else if (currentPriorityClassId != _lastPriorityClassId) {
          shouldJump = true;
          _lastPriorityClassId = currentPriorityClassId;
        }

        setState(() {
          _lastApiTime = apiTime;
          _apiTimeReceivedAt = DateTime.now();
          _allClasses = allClasses;
          _isLoading = false;

          if (shouldJump) {
            // If jumping, update everything to match the priority class
            _displayedClass = displayClass;
            _isCurrentClass = isCurrent;
            _countdownEndTime = countdownTime;
            _currentClassIndex = displayClassIndex;
          } else {
            // If NOT jumping (user might be swiping), keep current index
            // But update _displayedClass to match the updated data for the CURRENT index
            if (_currentClassIndex < allClasses.length) {
              _displayedClass = allClasses[_currentClassIndex];

              // Re-calculate countdown/status for the currently viewed class
              final startTime = _displayedClass!['start_time'] as String?;
              final endTime = _displayedClass!['end_time'] as String?;

              if (startTime != null) {
                final classStartTime = _parseTimeToDateTime(startTime);
                final classEndTime = endTime != null
                    ? _parseTimeToDateTime(endTime)
                    : null;

                final now = _currentSyncTime;
                final hasStarted =
                    classStartTime != null && !now.isBefore(classStartTime);
                final hasEnded =
                    classEndTime != null && now.isAfter(classEndTime);

                _isCurrentClass = hasStarted && !hasEnded;

                if (_isCurrentClass && classEndTime != null) {
                  _countdownEndTime = classEndTime;
                } else if (!hasStarted && classStartTime != null) {
                  _countdownEndTime = classStartTime;
                } else {
                  _countdownEndTime = null;
                }
              }
            } else {
              // Fallback if index is out of bounds (e.g. list shrank)
              _currentClassIndex = 0;
              if (allClasses.isNotEmpty) {
                _displayedClass = allClasses[0];
              }
            }
          }
        });

        // Only jump if we determined we should
        if (shouldJump) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(displayClassIndex);
            }
          });
        }

        _updateCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading class data: $e');
    }
  }

  DateTime? _parseTimeToDateTime(String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        final now = DateTime.now();
        final hour = int.tryParse(timeParts[0].trim()) ?? 0;
        final minute = int.tryParse(timeParts[1].trim()) ?? 0;
        final second = timeParts.length >= 3
            ? int.tryParse(timeParts[2].trim()) ?? 0
            : 0;

        return DateTime(now.year, now.month, now.day, hour, minute, second);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  void _updateCountdown() {
    if (_countdownEndTime == null || _displayedClass == null) {
      return;
    }

    // Use the synced time to prevent freezing
    final now = _currentSyncTime;

    // Check if it's a different day
    if (_countdownEndTime!.day != now.day ||
        _countdownEndTime!.month != now.month ||
        _countdownEndTime!.year != now.year) {
      if (mounted) {
        _loadClassData();
      }
      return;
    }

    final difference = _countdownEndTime!.difference(now);
    final totalSeconds = difference.inSeconds;

    // Only reload if significantly past the time (more than 5 minutes past)
    if (totalSeconds < -300 && mounted) {
      _loadClassData();
      return;
    }

    if (totalSeconds >= -300 && mounted) {
      setState(() {
        // Just trigger rebuild to update the live countdowns in PageView
      });
    }
  }

  void _nextClass() {
    if (_currentClassIndex < _allClasses.length - 1) {
      setState(() {
        _currentClassIndex++;
        _displayedClass = _allClasses[_currentClassIndex];
        _updateCountdown();
      });
    }
  }

  void _previousClass() {
    if (_currentClassIndex > 0) {
      setState(() {
        _currentClassIndex--;
        _displayedClass = _allClasses[_currentClassIndex];
        _updateCountdown();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LoadingAnimations.shimmer(
          baseColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.18),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      );
    }

    // Only show if there's a class to display
    if (_displayedClass == null || _allClasses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with "Today's Class" and Page indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S CLASS",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  '${_currentClassIndex + 1}/${_allClasses.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        // PageView for smooth swipe gesture like image gallery
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentClassIndex = index;
                _displayedClass = _allClasses[index];
                // Update countdown for new class
                final startTime = _displayedClass!['start_time'] as String?;
                final endTime = _displayedClass!['end_time'] as String?;

                if (startTime != null) {
                  final classStartTime = _parseTimeToDateTime(startTime);
                  final classEndTime = endTime != null
                      ? _parseTimeToDateTime(endTime)
                      : null;

                  // Check if this is the current class
                  final now = _currentSyncTime;
                  final hasStarted =
                      classStartTime != null && !now.isBefore(classStartTime);
                  final hasEnded =
                      classEndTime != null && now.isAfter(classEndTime);

                  _isCurrentClass = hasStarted && !hasEnded;

                  if (_isCurrentClass && classEndTime != null) {
                    _countdownEndTime = classEndTime;
                  } else if (!hasStarted && classStartTime != null) {
                    _countdownEndTime = classStartTime;
                  } else {
                    _countdownEndTime = null;
                  }

                  _updateCountdown();
                }
              });
            },
            itemCount: _allClasses.length,
            itemBuilder: (context, index) {
              final classData = _allClasses[index];
              final className = classData['class_section'] ?? 'Class';
              final timeDisplay = classData['time_display'] ?? '';
              final roomNumber = classData['room_number'] ?? 'TBA';
              final subjectName = classData['subject_name'] ?? '';
              final startTime = classData['start_time'] as String?;
              final endTime = classData['end_time'] as String?;

              // Determine class state: UPCOMING, ONGOING, or ENDED
              final now = _currentSyncTime;
              DateTime? classStartTime;
              DateTime? classEndTime;

              if (startTime != null) {
                classStartTime = _parseTimeToDateTime(startTime);
              }
              if (endTime != null) {
                classEndTime = _parseTimeToDateTime(endTime);
              }

              String stateText = 'UPCOMING';
              Color stateColor = AppTheme.warningOrange;
              String displayTime = '';
              bool isCurrentClass = false;

              // Determine state
              if (classEndTime != null && now.isAfter(classEndTime)) {
                // CLASS HAS ENDED
                stateText = 'COMPLETED';
                stateColor = AppTheme.infoBlue;
                // Calculate duration
                if (classStartTime != null) {
                  final duration = classEndTime.difference(classStartTime);
                  final durationHours = duration.inHours;
                  final durationMins = duration.inMinutes.remainder(60);
                  if (durationHours > 0) {
                    displayTime = '${durationHours}h ${durationMins}m';
                  } else {
                    displayTime = '${durationMins}m';
                  }
                }
              } else if (classStartTime != null &&
                  !now.isBefore(classStartTime) &&
                  (classEndTime == null || now.isBefore(classEndTime))) {
                // CLASS IS ONGOING - Calculate live countdown
                stateText = 'ONGOING';
                stateColor = AppTheme.successGreen;
                isCurrentClass = true;

                // Calculate remaining time for this class
                if (classEndTime != null) {
                  final difference = classEndTime.difference(now);
                  final totalSeconds = difference.inSeconds;
                  final minutes = (totalSeconds >= 0 ? totalSeconds ~/ 60 : 0);
                  final seconds = (totalSeconds >= 0 ? totalSeconds % 60 : 0);
                  displayTime =
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                }
              } else {
                // CLASS IS UPCOMING - Calculate live countdown
                stateText = 'UPCOMING';
                stateColor = Colors.orange;

                // Calculate remaining time until class starts
                if (classStartTime != null) {
                  final difference = classStartTime.difference(now);
                  final totalSeconds = difference.inSeconds;
                  final hours = (totalSeconds >= 0 ? totalSeconds ~/ 3600 : 0);
                  final minutes = (totalSeconds >= 0
                      ? (totalSeconds % 3600) ~/ 60
                      : 0);
                  final seconds = (totalSeconds >= 0 ? totalSeconds % 60 : 0);

                  if (hours > 0) {
                    displayTime =
                        '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                  } else {
                    displayTime =
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
                  }
                }
              }

              final badgeText = stateText;

              // Calculate progress for ONGOING class
              double progressValue = 0.0;
              String durationDisplay = '';
              if ((isCurrentClass || stateText == 'COMPLETED') &&
                  classStartTime != null &&
                  classEndTime != null) {
                final totalDuration = classEndTime.difference(classStartTime);
                final elapsedDuration = now.difference(classStartTime);
                progressValue = stateText == 'COMPLETED'
                    ? 1.0
                    : (elapsedDuration.inSeconds / totalDuration.inSeconds)
                          .clamp(0.0, 1.0);

                // Format total duration
                final durationHours = totalDuration.inHours;
                final durationMins = totalDuration.inMinutes.remainder(60);
                if (durationHours > 0) {
                  durationDisplay = 'Total: ${durationHours}h ${durationMins}m';
                } else {
                  durationDisplay = 'Total: ${durationMins}m';
                }
              }

              return _AnimatedClassCard(
                classData: classData,
                className: className,
                subjectName: subjectName,
                timeDisplay: timeDisplay,
                roomNumber: roomNumber,
                stateText: stateText,
                stateColor: stateColor,
                displayTime: displayTime,
                isCurrentClass: isCurrentClass,
                progressValue: progressValue,
                durationDisplay: durationDisplay,
                badgeText: badgeText,
                cardIndex: index + 1,
                totalCards: _allClasses.length,
              );
            },
          ),
        ),
        // Swipe hints
        if (_allClasses.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swap_horizontal_circle_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe to view all classes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnimatedClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String className;
  final String subjectName;
  final String timeDisplay;
  final String roomNumber;
  final String stateText;
  final Color stateColor;
  final String displayTime;
  final bool isCurrentClass;
  final double progressValue;
  final String durationDisplay;
  final String badgeText;
  final int cardIndex;
  final int totalCards;

  const _AnimatedClassCard({
    required this.classData,
    required this.className,
    required this.subjectName,
    required this.timeDisplay,
    required this.roomNumber,
    required this.stateText,
    required this.stateColor,
    required this.displayTime,
    required this.isCurrentClass,
    required this.progressValue,
    required this.durationDisplay,
    required this.badgeText,
    required this.cardIndex,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dashboard class card should always redirect to the Schedule / Classes screen.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeacherScheduleScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.18),
              Colors.white.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: stateText == 'ONGOING'
                ? stateColor.withOpacity(0.7)
                : Colors.white.withOpacity(0.3),
            width: stateText == 'ONGOING' ? 2.0 : 1.2,
          ),
          boxShadow: [
            if (stateText == 'ONGOING')
              BoxShadow(
                color: stateColor.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top row: Class info and Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subjectName.isNotEmpty
                                  ? subjectName
                                  : 'No Subject',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: stateColor.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: Time, Room, and Countdown
            Row(
              children: [
                // Time
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Room
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        roomNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCurrentClass
                          ? Icons.timer_outlined
                          : Icons.hourglass_empty_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isCurrentClass || stateText == 'COMPLETED') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progressValue,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    stateColor.withOpacity(0.8),
                                    stateColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: stateColor.withOpacity(0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
