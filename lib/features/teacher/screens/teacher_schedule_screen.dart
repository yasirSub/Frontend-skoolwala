import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/features/teacher/models/class_schedule.dart';
import 'package:skoolwala/features/teacher/models/today_class.dart';
import 'package:skoolwala/features/teacher/models/day_schedule.dart';
import 'package:skoolwala/features/teacher/models/class_item.dart';
import 'package:skoolwala/features/teacher/services/class_notification_service.dart';
import 'package:skoolwala/features/teacher/services/teacher_class_service.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/features/teacher/screens/mark_student_attendance_screen.dart';
import 'package:skoolwala/shared/widgets/animated_bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/premium_entrance_animation.dart';
import '../../../shared/animations/loading_animations.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen>
    with SingleTickerProviderStateMixin {
  final ClassNotificationService _notificationService =
      ClassNotificationService();
  TabController? _tabController;

  bool _attendanceTypeLoading = true;
  bool _isSubjectWise = false;
  bool _isDayWise = true;

  bool _assignedClassesLoaded = false;
  bool _isLoadingAssignedClasses = false;
  String? _assignedClassesError;
  List<TeacherClass> _assignedClasses = [];

  List<TodayClass> _todayClasses = [];
  List<DaySchedule> _weekSchedule = [];
  bool _isLoadingToday = true;
  bool _isLoadingWeek = false;
  final Set<String> _expandedDays = {}; // Track which days are expanded

  String? _lastAssignedDebugSignature;

  void _debugPrintAssignedMatching(String reason) {
    if (!kDebugMode) return;

    final assignedSig = _assignedClasses
        .map((c) => '${c.classId}-${c.sectionId}')
        .join(',');
    final todaySig = _todayClasses
        .map((c) => '${c.classId}-${c.sectionId}:${c.classSection}')
        .join(',');
    final signature =
        'dw=$_isDayWise|loaded=$_assignedClassesLoaded|a=$assignedSig|t=$todaySig|err=${_assignedClassesError ?? ''}';

    if (_lastAssignedDebugSignature == signature) return;
    _lastAssignedDebugSignature = signature;

    print('\n═══════════════════════════════════════════════════════════');
    print('🧪 ASSIGNED-CLASS DEBUG ($reason)');
    print(
      'DayWise=$_isDayWise | assignedLoaded=$_assignedClassesLoaded | assignedLoading=$_isLoadingAssignedClasses',
    );
    if (_assignedClassesError != null && _assignedClassesError!.isNotEmpty) {
      print('AssignedClassesError: $_assignedClassesError');
    }

    print('Assigned classes (${_assignedClasses.length}):');
    for (final c in _assignedClasses) {
      print(
        '  - classId=${c.classId}, sectionId=${c.sectionId}, display="${c.displayName}", class="${c.className}", section="${c.sectionName}"',
      );
    }

    print('Today classes (${_todayClasses.length}):');
    for (final t in _todayClasses) {
      final match = _isAllocatedClassTeacherForClass(
        classId: t.classId,
        sectionId: t.sectionId,
        classSection: t.classSection,
      );
      print(
        '  - classId=${t.classId}, sectionId=${t.sectionId}, section="${t.classSection}", matchAssigned=$match',
      );
    }
    print('═══════════════════════════════════════════════════════════\n');
  }

  Widget _buildClassTeacherAllocationInfo() {
    if (_attendanceTypeLoading || !_isDayWise) {
      return const SizedBox.shrink();
    }

    // If assigned classes not loaded yet, don't show noisy UI.
    if (!_assignedClassesLoaded) {
      return const SizedBox.shrink();
    }

    final hasAnyAssigned = _assignedClasses.isNotEmpty;
    final hasMatchInToday = _todayClasses.any(
      (t) => _isAllocatedClassTeacherForClass(
        classId: t.classId,
        sectionId: t.sectionId,
        classSection: t.classSection,
      ),
    );

    final allocationText = hasAnyAssigned
        ? _assignedClasses
              .map(
                (c) => c.displayName.isNotEmpty
                    ? c.displayName
                    : '${c.className} - ${c.sectionName}',
              )
              .join(', ')
        : 'No class teacher allocation found.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 18,
            color: Colors.white.withOpacity(0.75),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Teacher Allocation',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allocationText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (hasAnyAssigned && !hasMatchInToday) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: These classes may not appear in today\'s timetable list.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.index == 1 && _weekSchedule.isEmpty) {
        // Set loading state immediately when switching to View tab
        setState(() {
          _isLoadingWeek = true;
        });
        _loadWeekSchedule(); // Load week schedule when switching to View tab
      }
    });

    _loadTodayClasses(); // Load today's classes on screen open
    _loadAttendanceType(); // Load school attendance mode (Day-Wise/Subject-Wise)

    // Set callback for class reminders
    _notificationService.setOnClassReminderCallback(() {
      if (mounted) {
        _showClassReminderDialog();
      }
    });
  }

  Future<void> _loadAttendanceType() async {
    try {
      final response = await AttendanceService.getAttendanceType();

      if (!mounted) return;

      if (response['status'] == 'success') {
        final data = response['data'];

        final newAttendanceType =
            int.tryParse(data['attendance_type']?.toString() ?? '0') ?? 0;
        final newIsSubjectWise = newAttendanceType == 1;
        final newIsDayWise = newAttendanceType == 0;

        setState(() {
          _isSubjectWise = newIsSubjectWise;
          _isDayWise = newIsDayWise;
          _attendanceTypeLoading = false;
        });

        if (newIsDayWise) {
          _loadAssignedClasses();
        } else {
          setState(() {
            _assignedClassesLoaded = false;
            _isLoadingAssignedClasses = false;
            _assignedClassesError = null;
            _assignedClasses = [];
          });
        }
        return;
      }

      setState(() {
        _attendanceTypeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attendanceTypeLoading = false;
      });
    }
  }

  bool get _shouldShowAssignedClassesCard =>
      !_attendanceTypeLoading && _isDayWise;

  Future<void> _loadAssignedClasses({bool force = false}) async {
    if (!_shouldShowAssignedClassesCard) return;
    if (_isLoadingAssignedClasses) return;
    if (_assignedClassesLoaded && !force) return;

    if (!mounted) return;
    setState(() {
      _isLoadingAssignedClasses = true;
      _assignedClassesError = null;
    });

    try {
      final res = await TeacherClassService.getMyClasses();
      if (!mounted) return;

      if (res.isSuccess) {
        setState(() {
          _assignedClasses = res.classes;
          _assignedClassesLoaded = true;
          _isLoadingAssignedClasses = false;
          _assignedClassesError = null;
        });
        _debugPrintAssignedMatching('after _loadAssignedClasses success');
      } else {
        setState(() {
          _assignedClasses = [];
          _assignedClassesLoaded = true;
          _isLoadingAssignedClasses = false;
          _assignedClassesError = res.message.isNotEmpty
              ? res.message
              : 'Failed to load assigned classes';
        });
        _debugPrintAssignedMatching('after _loadAssignedClasses failure');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assignedClasses = [];
        _assignedClassesLoaded = true;
        _isLoadingAssignedClasses = false;
        _assignedClassesError = e.toString();
      });
      _debugPrintAssignedMatching('after _loadAssignedClasses exception');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  /// Load Today's Classes from API
  Future<void> _loadTodayClasses({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoadingToday = true;
      });
    }

    try {
      final baseUrl = ApiConfig.getBaseUrl();
      final url = '$baseUrl/getTeacherTodayClasses';

      print('\n═══════════════════════════════════════════════════════════');
      print('📱 LOADING TODAY\'S CLASSES');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 Endpoint: $url');
      print('═══════════════════════════════════════════════════════════\n');

      // Get auth credentials
      final authData = SessionManager.instance.getAuthBody();

      final response = await HttpClient().postJson(
        'getTeacherTodayClasses',
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      print('✅ API Response Status: ${response['status']}');
      print('📝 API Message: ${response['message']}');
      print('📅 API Day: ${response['day']}');
      print('📅 API Date: ${response['date']}');
      print('📊 Number of Classes: ${(response['data'] as List).length}');

      // Log current day for comparison
      final now = DateTime.now();
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      print('📅 App Current Day: ${weekdays[now.weekday - 1]}');
      print(
        '📅 App Current Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );

      if (response['status'] == 'success') {
        final classes = (response['data'] as List)
            .map((c) => TodayClass.fromJson(c))
            .toList();

        print('\n📋 TODAY\'S CLASSES LOADED:');
        for (int i = 0; i < classes.length; i++) {
          final cls = classes[i];
          print('  ${i + 1}. ${cls.classSection}');
          print('     ⏰ Time: ${cls.timeSlot}');
          print('     🏠 Room: ${cls.roomNumber}');
        }

        if (mounted) {
          // Sort classes by start time
          classes.sort((a, b) {
            try {
              final timeA = _parseTime(a.startTime);
              final timeB = _parseTime(b.startTime);
              return timeA.compareTo(timeB);
            } catch (e) {
              return 0;
            }
          });

          setState(() {
            _todayClasses = classes;
            _isLoadingToday = false;
          });

          _debugPrintAssignedMatching('after _loadTodayClasses success');

          // Convert to ClassSchedule for notification service
          final classSchedules = classes
              .map(
                (c) => ClassSchedule(
                  id: c.id.toString(),
                  className: c.className,
                  sectionName: c.sectionName,
                  roomNumber: c.roomNumber,
                  startTime: _parseTime(c.startTime),
                  endTime: _parseTime(c.endTime),
                  totalStudents: 0,
                ),
              )
              .toList();

          // Start monitoring for class reminders
          _notificationService.startMonitoring(classSchedules);

          print('\n✅ Today\'s classes loaded successfully');
          print(
            '═══════════════════════════════════════════════════════════\n',
          );
        }
      } else {
        print('\n❌ API Error: ${response['message']}');
        _handleError(response['message'] ?? 'Failed to load today\'s classes');
      }
    } catch (e) {
      print('\n❌ Exception Error: $e');
      print('═══════════════════════════════════════════════════════════\n');
      _handleError('Error loading today\'s classes: $e');
    }
  }

  /// Load Full Week Schedule from API
  Future<void> _loadWeekSchedule({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoadingWeek = true;
      });
    }

    try {
      final baseUrl = ApiConfig.getBaseUrl();
      print('\n📋 LOADING FULL WEEK SCHEDULE');
      print('🔗 Endpoint: $baseUrl/getTeacherSchedule\n');

      // Get auth credentials
      final authData = SessionManager.instance.getAuthBody();

      final response = await HttpClient().postJson(
        'getTeacherSchedule',
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      print('✅ API Response Status: ${response['status']}');
      print('📊 Total Days: ${(response['data'] as List).length}');

      if (response['status'] == 'success') {
        final schedule = (response['data'] as List)
            .map((d) => DaySchedule.fromJson(d))
            .toList();

        if (mounted) {
          setState(() {
            _weekSchedule = schedule;
            _isLoadingWeek = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoadingWeek = false;
        });
      }
    } catch (e) {
      print('❌ Error loading week schedule: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeek = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
      }
    }
  }

  /// Parse time string to DateTime (handles HH:MM:SS or HH:MM format)
  DateTime _parseTime(String timeStr) {
    try {
      // Remove any whitespace
      timeStr = timeStr.trim();

      // Split by colon
      final parts = timeStr.split(':');
      if (parts.length < 2) {
        throw Exception('Invalid time format');
      }

      // Parse hour and minute (ignore seconds if present)
      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());

      // Validate hour and minute
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        throw Exception('Invalid time values');
      }

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      print('Error parsing time "$timeStr": $e');
      return DateTime.now();
    }
  }

  /// Handle error and show user message
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isLoadingToday = false;
        _isLoadingWeek = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show class reminder dialog
  void _showClassReminderDialog() {
    final nextClass = _notificationService.getNextClass();
    if (nextClass == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.dashboardAccentLight.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              'Class Reminder!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your class starts in 10 minutes!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            _buildClassInfoTile(nextClass),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToClass(nextClass);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Go to Class'),
          ),
        ],
      ),
    );
  }

  /// Navigate to specific class details
  void _navigateToClass(ClassSchedule classSchedule) {
    // TODO: Navigate to class attendance or management screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening ${classSchedule.className} (${classSchedule.sectionName})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getTodayDayName() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[now.weekday - 1];
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _formatApiDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return '';
    }

    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('MMMM d, yyyy').format(parsed);
    } catch (e) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = SessionManager.instance.currentTeacher?.role;
    final navItems = BottomNavConfigs.getItemsForRole(userRole);

    return AppTheme.buildBackground(
      webBaseUrl: ApiConfig.getWebBaseUrl(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        bottomNavigationBar: AnimatedBottomNavBar(
          currentIndex: 1, // Schedule is index 1
          items: navItems,
          onTap: (index) {
            final itemLabel = navItems[index].label.toLowerCase().trim();
            if (itemLabel.contains('home')) {
              Navigator.pop(context); // Go back to dashboard
            } else if (itemLabel.contains('profile')) {
              // Navigate to profile
              Navigator.pop(context);
              // Profile navigation will be handled by dashboard
            }
            // If schedule is tapped, we're already here
          },
          autoNavigation: false,
          collapsible: true,
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          centerTitle: false,
          title: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(-20 * (1 - value), 0),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Class Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _attendanceTypeLoading
                      ? 'Attendance: Loading...'
                      : (_isSubjectWise
                            ? 'Attendance: Subject-Wise'
                            : (_isDayWise
                                  ? 'Attendance: Day-Wise'
                                  : 'Attendance: Unknown')),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat(
                                'MMM',
                              ).format(DateTime.now()).toUpperCase(),
                              style: TextStyle(
                                color: Colors.redAccent.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('d').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_todayClasses.isNotEmpty)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _todayClasses.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0.9)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: AppTheme.dashboardPrimary,
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.today_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('TODAY'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_view_week_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('WEEKLY'),
                      ],
                    ),
                  ),
                ],
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildTodayView(), _buildWeekView()],
        ),
      ),
    );
  }

  Widget _buildTodayView() {
    if (_isLoadingToday) {
      return _buildLoadingSkeleton();
    }

    if (_todayClasses.isEmpty) {
      return _buildTodayEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadTodayClasses(showLoader: false),
      color: Colors.white,
      backgroundColor: AppTheme.dashboardPrimary,
      edgeOffset: 20,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTodayDayName().toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your Schedule',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Text(
                            '${_todayClasses.length} PERIODS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildClassTeacherAllocationInfo(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return PremiumEntranceAnimation(
                  index: index + 1,
                  child: _buildTodayClassCard(_todayClasses[index]),
                );
              }, childCount: _todayClasses.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    if (_isLoadingWeek) {
      return _buildLoadingSkeleton();
    }

    if (_weekSchedule.isEmpty) {
      return _buildWeekEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadWeekSchedule(showLoader: false),
      color: Colors.white,
      backgroundColor: AppTheme.dashboardPrimary,
      edgeOffset: 20,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY PLAN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All Classes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return PremiumEntranceAnimation(
                  index: index + 1,
                  child: _buildDayScheduleCard(_weekSchedule[index]),
                );
              }, childCount: _weekSchedule.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }

  /// Build Skeleton Loading Animation
  Widget _buildLoadingSkeleton() {
    return LoadingAnimations.shimmer(
      baseColor: Colors.white.withOpacity(0.08),
      highlightColor: Colors.white.withOpacity(0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Skeleton
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 40,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 32),
            // Card Skeletons
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 20,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 14,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 12,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state for Today's view
  Widget _buildTodayEmptyState() {
    return Center(
      child: PremiumEntranceAnimation(
        index: 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Hero(
                  tag: 'empty_calendar',
                  child: Icon(
                    Icons.event_busy_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'NO CLASSES TODAY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your schedule for today is completely clear.\nTime to recharge or plan ahead!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              _buildEmptyActionButtons(
                primaryLabel: 'VIEW WEEKLY PLAN',
                onPrimary: () {
                  _tabController?.animateTo(1);
                  if (_weekSchedule.isEmpty) {
                    _loadWeekSchedule(showLoader: true);
                  }
                },
                onRefresh: () => _loadTodayClasses(showLoader: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActionButtons({
    required String primaryLabel,
    required VoidCallback onPrimary,
    required VoidCallback onRefresh,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.dashboardPrimary,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              primaryLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('REFRESH SCHEDULE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state for Week view
  Widget _buildWeekEmptyState() {
    return Center(
      child: PremiumEntranceAnimation(
        index: 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Hero(
                  tag: 'empty_week',
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'WEEKLY PLAN EMPTY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No weekly schedule has been assigned yet.\nPlease check back later or refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              _buildEmptyActionButtons(
                primaryLabel: 'REFRESH WEEKLY PLAN',
                onPrimary: () => _loadWeekSchedule(showLoader: true),
                onRefresh: () => _loadWeekSchedule(showLoader: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Today's Class Card
  Widget _buildTodayClassCard(TodayClass classItem) {
    // Check if class is upcoming or current
    final now = DateTime.now();
    DateTime? classStartTime;
    DateTime? classEndTime;

    try {
      classStartTime = _parseTime(classItem.startTime);
      classEndTime = _parseTime(classItem.endTime);
    } catch (e) {
      print('Error parsing times for ${classItem.classSection}: $e');
    }

    // Determine status and aesthetics
    String statusText = 'UPCOMING';
    Color statusColor = AppTheme.warningOrange;
    bool isCompleted = false;
    bool isOngoing = false;

    if (classStartTime != null && classEndTime != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = classStartTime.hour * 60 + classStartTime.minute;
      final endMinutes = classEndTime.hour * 60 + classEndTime.minute;

      if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
        statusText = 'ONGOING';
        statusColor = AppTheme.successGreen;
        isOngoing = true;
      } else if (nowMinutes > endMinutes) {
        statusText = 'COMPLETED';
        statusColor = AppTheme.infoBlue;
        isCompleted = true;
      }
    }

    final showAssignedClassBadge =
        _isDayWise &&
        _isAllocatedClassTeacherForClass(
          classId: classItem.classId,
          sectionId: classItem.sectionId,
          classSection: classItem.classSection,
        );

    final canMarkAttendance = !_isDayWise || showAssignedClassBadge;

    // Calculate Progress for Ongoing classes
    double progress = 0.0;
    if (isOngoing && classStartTime != null && classEndTime != null) {
      final total = classEndTime.difference(classStartTime).inMinutes;
      final elapsed = now.difference(classStartTime).inMinutes;
      progress = (elapsed / total).clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // All teachers can view attendance, but canMarkAttendance controls if they can save
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkStudentAttendanceScreen(
                  classId: classItem.classId,
                  sectionId: classItem.sectionId,
                  className: classItem.classSection,
                  subjectId: classItem.subjectId,
                  subjectName: classItem.subjectName,
                  canMarkAttendance: canMarkAttendance, // Pass permission flag
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(isOngoing ? 0.22 : 0.15),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isOngoing
                    ? statusColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.15),
                width: isOngoing ? 2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                if (isOngoing)
                  BoxShadow(
                    color: statusColor.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Top Right Accent Glow
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.15),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Time Indicator Section
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  classItem.startTime.substring(0, 5),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 2,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                Text(
                                  classItem.endTime.substring(0, 5),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Class Info Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        classItem.classSection,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (showAssignedClassBadge)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.verified_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (classItem.subjectName != null)
                                  Text(
                                    classItem.subjectName!.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.meeting_room_rounded,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Room ${classItem.roomNumber}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (isOngoing) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${(progress * 100).toInt()}% Done',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (isOngoing) ...[
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        statusColor.withOpacity(0.5),
                                        statusColor,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isCompleted && canMarkAttendance) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOngoing
                                  ? [
                                      AppTheme.primaryPurple,
                                      AppTheme.darkPurple,
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isOngoing
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryPurple.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MarkStudentAttendanceScreen(
                                          classId: classItem.classId,
                                          sectionId: classItem.sectionId,
                                          className: classItem.classSection,
                                          subjectId: classItem.subjectId,
                                          subjectName: classItem.subjectName,
                                        ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    'MARK ATTENDANCE',
                                    style: TextStyle(
                                      color: isOngoing
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Day Schedule Card (for Week View)
  Widget _buildDayScheduleCard(DaySchedule daySchedule) {
    final isExpanded = _expandedDays.contains(daySchedule.day);
    final isToday =
        daySchedule.day.toUpperCase() ==
        DateFormat('EEEE').format(DateTime.now()).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isToday
              ? AppTheme.dashboardAccent.withOpacity(0.6)
              : Colors.white.withOpacity(0.15),
          width: isToday ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          if (isToday)
            BoxShadow(
              color: AppTheme.dashboardAccent.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Header - tappable to expand/collapse
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedDays.remove(daySchedule.day);
                    } else {
                      _expandedDays.add(daySchedule.day);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isToday
                                ? [
                                    AppTheme.dashboardAccent,
                                    AppTheme.darkPurple,
                                  ]
                                : [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              daySchedule.day.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${daySchedule.totalClasses} CLASSES',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                if (isToday) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.dashboardAccent
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'TODAY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Expanded content
            if (isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Container(
                      height: 1.5,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    ...daySchedule.classes.map(
                      (classItem) =>
                          _buildWeekClassItemFromClassItem(classItem),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build class item for week view expanded card
  Widget _buildWeekClassItemFromClassItem(ClassItem classItem) {
    final canMarkAttendance =
        !_isDayWise ||
        _isAllocatedClassTeacherForClass(
          classId: classItem.classId,
          sectionId: classItem.sectionId,
          classSection: classItem.classSection,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // All teachers can view attendance, but canMarkAttendance controls if they can save
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkStudentAttendanceScreen(
                  classId: classItem.classId,
                  sectionId: classItem.sectionId,
                  className: classItem.classSection,
                  subjectId: classItem.subjectId,
                  subjectName: classItem.subjectName,
                  canMarkAttendance: canMarkAttendance, // Pass permission flag
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        classItem.timeDisplay.split(' - ')[0].substring(0, 5),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        classItem.timeDisplay.split(' - ').length > 1
                            ? classItem.timeDisplay
                                  .split(' - ')[1]
                                  .substring(0, 5)
                            : '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classItem.classSection,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (!_isDayWise &&
                              classItem.subjectName != null &&
                              classItem.subjectName!.isNotEmpty) ...[
                            Icon(
                              Icons.book_outlined,
                              size: 12,
                              color: AppTheme.dashboardAccent.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                classItem.subjectName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.room_outlined,
                            size: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            classItem.roomNumber,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedClassesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.class_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.85),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Assigned Classes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (_isLoadingAssignedClasses)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                )
              else
                IconButton(
                  onPressed: () => _loadAssignedClasses(force: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  color: Colors.white.withOpacity(0.75),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Refresh',
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_assignedClassesError != null &&
              _assignedClassesError!.isNotEmpty)
            Text(
              _assignedClassesError!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            )
          else if (_assignedClassesLoaded && _assignedClasses.isEmpty)
            Text(
              'No assigned classes found.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_assignedClasses.isNotEmpty)
            Column(
              children: _assignedClasses
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.white.withOpacity(0.55),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.displayName.isNotEmpty
                                  ? c.displayName
                                  : '${c.className} ${c.sectionName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            Text(
              'Loading assigned classes...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  String _normalizeClassSection(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  bool _isAllocatedClassTeacherForClass({
    required int classId,
    required int sectionId,
    required String classSection,
  }) {
    if (_assignedClasses.isEmpty) return false;

    for (final c in _assignedClasses) {
      if (c.classId == classId && c.sectionId == sectionId) {
        return true;
      }
    }

    // Fallback for legacy/odd API cases where ids don't line up.
    return _isAllocatedClassTeacherForSection(classSection);
  }

  bool _isAllocatedClassTeacherForSection(String classSection) {
    if (_assignedClasses.isEmpty) return false;
    final target = _normalizeClassSection(classSection);

    for (final c in _assignedClasses) {
      final candidates = <String?>[
        c.displayName,
        '${c.className} - ${c.sectionName}',
        '${c.className}-${c.sectionName}',
      ];

      for (final candidate in candidates) {
        if (candidate == null || candidate.trim().isEmpty) continue;
        if (_normalizeClassSection(candidate) == target) return true;
      }
    }
    return false;
  }

  /// Show options when class card is tapped
  void _showClassOptions(TodayClass classItem) {
    final displayName = classItem.classSection;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.darkPurple,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dashboardAccentLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.class_outlined,
                        color: AppTheme.dashboardAccentLight,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (classItem.subjectName != null)
                            Text(
                              classItem.subjectName!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Actions Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Mark\nAttendance',
                        Icons.fact_check_outlined,
                        Colors.green,
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MarkStudentAttendanceScreen(
                                classId: classItem.classId,
                                sectionId: classItem.sectionId,
                                className: displayName,
                                subjectId: classItem.subjectId,
                                subjectName: classItem.subjectName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build class info tile for reminder dialog
  Widget _buildClassInfoTile(ClassSchedule classSchedule) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classSchedule.className,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Section: ${classSchedule.sectionName}'),
          const SizedBox(height: 5),
          Text('Room: ${classSchedule.roomNumber}'),
          const SizedBox(height: 5),
          Text('Time: ${classSchedule.timeDisplay}'),
        ],
      ),
    );
  }
}
