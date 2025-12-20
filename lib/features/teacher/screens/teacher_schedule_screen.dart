import 'package:flutter/material.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/features/teacher/models/class_schedule.dart';
import 'package:skoolwala/features/teacher/models/today_class.dart';
import 'package:skoolwala/features/teacher/models/day_schedule.dart';
import 'package:skoolwala/features/teacher/models/class_item.dart';
import 'package:skoolwala/features/teacher/services/class_notification_service.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/features/teacher/screens/mark_student_attendance_screen.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/widgets/premium_entrance_animation.dart';

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

  List<TodayClass> _todayClasses = [];
  List<DaySchedule> _weekSchedule = [];
  bool _isLoadingToday = true;
  bool _isLoadingWeek = false;
  final Set<String> _expandedDays = {}; // Track which days are expanded

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

    // Set callback for class reminders
    _notificationService.setOnClassReminderCallback(() {
      if (mounted) {
        _showClassReminderDialog();
      }
    });
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C63FF), Color(0xFF4B43B2)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
            child: const Text(
              'Class Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
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

  /// Build Today's Classes View (Tab 1)
  Widget _buildTodayView() {
    if (_isLoadingToday) {
      return Center(
        child: AppLoadingIndicator(
          color: Colors.white,
          text: 'Loading today\'s schedule...',
        ),
      );
    }

    if (_todayClasses.isEmpty) {
      return _buildTodayEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadTodayClasses(showLoader: false),
      color: Colors.white,
      backgroundColor: AppTheme.dashboardPrimary,
      child: CustomScrollView(
        slivers: [
          // Removed CurrentClassWidget and NextClassWidget from here
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${_todayClasses.length} ${_todayClasses.length == 1 ? 'Class' : 'Classes'} Today',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final classItem = _todayClasses[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: _buildTodayClassCard(classItem),
                      ),
                    );
                  },
                );
              }, childCount: _todayClasses.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    if (_isLoadingWeek) {
      return Center(
        child: AppLoadingIndicator(
          color: Colors.white,
          text: 'Loading weekly schedule...',
        ),
      );
    }

    if (_weekSchedule.isEmpty) {
      return _buildWeekEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemCount: _weekSchedule.length,
      itemBuilder: (context, index) {
        final daySchedule = _weekSchedule[index];
        return PremiumEntranceAnimation(
          index: index,
          child: _buildDayScheduleCard(daySchedule),
        );
      },
    );
  }

  /// Build empty state for Today's view
  Widget _buildTodayEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Classes Today',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have no scheduled classes for today.\nEnjoy your free time!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _tabController?.animateTo(1);
                    if (_weekSchedule.isEmpty) {
                      _loadWeekSchedule(showLoader: true);
                    }
                  },
                  icon: const Icon(Icons.calendar_view_week_rounded),
                  label: const Text('VIEW WEEKLY SCHEDULE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _loadTodayClasses(showLoader: true),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('REFRESH SCHEDULE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
        ),
      ),
    );
  }

  /// Build empty state for Week view
  Widget _buildWeekEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Schedule Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Weekly schedule will appear here once assigned.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _loadWeekSchedule(showLoader: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('REFRESH WEEK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

    if (classStartTime != null && classEndTime != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = classStartTime.hour * 60 + classStartTime.minute;
      final endMinutes = classEndTime.hour * 60 + classEndTime.minute;

      if (nowMinutes >= startMinutes && nowMinutes <= endMinutes) {
        statusText = 'ONGOING';
        statusColor = AppTheme.successGreen;
      } else if (nowMinutes > endMinutes) {
        statusText = 'COMPLETED';
        statusColor = AppTheme.infoBlue;
        isCompleted = true;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkStudentAttendanceScreen(
                  classId: classItem.classId,
                  sectionId: classItem.sectionId,
                  className: classItem.classSection,
                  subjectId: classItem.subjectId,
                  subjectName: classItem.subjectName,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Status Indicator Edge Glow
                Positioned(
                  left: 0,
                  top: 24,
                  bottom: 24,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Time Block
                      Column(
                        children: [
                          Text(
                            classItem.startTime.substring(0, 5),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Text(
                            classItem.endTime.substring(0, 5),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Info Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    classItem.classSection,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              classItem.subjectName ?? 'No Subject',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  classItem.roomNumber,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                if (!isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryPurple,
                                          AppTheme.primaryPurple.withBlue(255),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryPurple
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'ATTENDANCE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isToday
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.08),
            isToday
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isToday
              ? AppTheme.dashboardAccent.withOpacity(0.4)
              : Colors.white.withOpacity(0.12),
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          if (isToday)
            BoxShadow(
              color: AppTheme.dashboardAccent.withOpacity(0.1),
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
        children: [
          // Header - tappable to expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDays.remove(daySchedule.day);
                } else {
                  _expandedDays.add(daySchedule.day);
                }
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: isToday
                          ? AppTheme.dashboardAccent
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              daySchedule.day,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.dashboardAccent.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: AppTheme.dashboardAccent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${daySchedule.totalClasses} CLASSES SCHEDULED',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded content - list of classes
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 12),
                        ),
                        ...daySchedule.classes.map(
                          (classItem) =>
                              _buildWeekClassItemFromClassItem(classItem),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Build class item for week view expanded card
  Widget _buildWeekClassItemFromClassItem(ClassItem classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      ? classItem.timeDisplay.split(' - ')[1].substring(0, 5)
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
                    if (classItem.subjectName != null &&
                        classItem.subjectName!.isNotEmpty) ...[
                      Icon(
                        Icons.book_outlined,
                        size: 12,
                        color: AppTheme.dashboardAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        classItem.subjectName!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
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
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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
