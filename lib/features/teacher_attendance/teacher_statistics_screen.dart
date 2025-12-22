import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '../../../shared/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:skoolwala/features/attendance/screens/quick_attendance_screen.dart';
import 'package:skoolwala/features/attendance/screens/weekend_attendance_inspection_screen.dart';
import 'package:skoolwala/features/teacher/models/today_class.dart';
import 'package:skoolwala/features/teacher/services/student_attendance_service.dart';
import 'package:skoolwala/features/teacher_attendance/teacher_attendance_screen.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/shared/services/session_manager.dart';

class TeacherStatisticsScreen extends StatefulWidget {
  final String staffId;

  const TeacherStatisticsScreen({super.key, required this.staffId});

  @override
  State<TeacherStatisticsScreen> createState() =>
      _TeacherStatisticsScreenState();
}

class _TeacherStatisticsScreenState extends State<TeacherStatisticsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? statisticsData;
  bool isLoading = true;
  String? error;
  String selectedFilterType = 'month';
  String selectedFilterValue = DateTime.now().toString().substring(0, 7);

  Future<StudentAttendanceReportResponse>? _studentReportFuture;
  _ClassSectionRef? _studentReportTarget;

  // Animation controllers
  late AnimationController _loadingAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _staggerAnimationController;

  // Animations
  late Animation<double> _loadingAnimation;
  late Animation<double> _contentAnimation;

  late final TabController _tabController;
  late final List<_AnalyticsTab> _tabs;

  @override
  void initState() {
    super.initState();

    final role = (SessionManager.instance.currentTeacher?.role ?? '')
        .toLowerCase();
    final isAdmin = role.contains('admin');

    _tabs = isAdmin
        ? [
            _AnalyticsTab(
              label: 'Teacher',
              type: _AnalyticsTabType.adminTeacher,
              showFilter: false,
            ),
            _AnalyticsTab(
              label: 'Student',
              type: _AnalyticsTabType.student,
              showFilter: false,
            ),
            _AnalyticsTab(
              label: 'Other Roles',
              type: _AnalyticsTabType.otherRoles,
              showFilter: false,
            ),
          ]
        : [
            _AnalyticsTab(
              label: 'Self',
              type: _AnalyticsTabType.self,
              showFilter: true,
            ),
            _AnalyticsTab(
              label: 'Student',
              type: _AnalyticsTabType.student,
              showFilter: false,
            ),
          ];

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    // Initialize animation controllers
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _staggerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start loading animation
    _loadingAnimationController.forward();

    loadStatistics();
    _studentReportFuture = _loadStudentAttendanceReport();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _contentAnimationController.dispose();
    _staggerAnimationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadStatistics() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final baseUrl = ApiConfig.getBaseUrl();
      final url = Uri.parse(
        '$baseUrl/getTeacherSelfAttendanceStats?staff_id=${widget.staffId}&filter_type=$selectedFilterType&filter_value=$selectedFilterValue',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              statisticsData = data['data'];
              isLoading = false;
            });

            // Start content animations
            _contentAnimationController.forward();
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _staggerAnimationController.forward();
            });
          }
        } else {
          if (mounted) {
            setState(() {
              error = data['message'] ?? 'Failed to load statistics';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            error = 'Server error: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error loading statistics: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadStatistics() async {
    _contentAnimationController.reset();
    _staggerAnimationController.reset();
    await loadStatistics();
  }

  String _formatApiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<_ClassSectionRef?> _loadDefaultClassSectionForStudentReport() async {
    try {
      final authData = SessionManager.instance.getAuthBody();

      // Prefer today's classes (gives the most relevant class/section)
      final todayResponse = await HttpClient().postJson(
        ApiConfig.getTeacherTodayClasses,
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      if (todayResponse['status'] == 'success') {
        final list = (todayResponse['data'] as List?) ?? const [];
        if (list.isNotEmpty) {
          final cls = TodayClass.fromJson(list.first as Map<String, dynamic>);
          return _ClassSectionRef(
            classId: cls.classId,
            sectionId: cls.sectionId,
            label: cls.classSection.isNotEmpty
                ? cls.classSection
                : '${cls.className} - ${cls.sectionName}',
          );
        }
      }
    } catch (_) {
      // fallthrough to getTeacherClasses
    }

    try {
      final authData = SessionManager.instance.getAuthBody();
      final classesResponse = await HttpClient().postJson(
        ApiConfig.getTeacherClasses,
        body: {
          'username': authData['username'],
          'password': authData['password'],
        },
        requireAuth: false,
      );

      if (classesResponse['status'] == 'success') {
        final list = (classesResponse['data'] as List?) ?? const [];
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final classId =
              int.tryParse(first['class_id']?.toString() ?? '') ?? 0;
          final sectionId =
              int.tryParse(first['section_id']?.toString() ?? '') ?? 0;
          final label = first['class_section']?.toString().trim();
          final className = first['class_name']?.toString().trim();
          final sectionName = first['section_name']?.toString().trim();
          return _ClassSectionRef(
            classId: classId,
            sectionId: sectionId,
            label: (label != null && label.isNotEmpty)
                ? label
                : '${className ?? ''} - ${sectionName ?? ''}'.trim(),
          );
        }
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  Future<StudentAttendanceReportResponse> _loadStudentAttendanceReport() async {
    final target = await _loadDefaultClassSectionForStudentReport();
    _studentReportTarget = target;

    if (target == null || target.classId == 0 || target.sectionId == 0) {
      return StudentAttendanceReportResponse(
        status: 'error',
        classId: 0,
        sectionId: 0,
        startDate: '',
        endDate: '',
        totalDays: 0,
        students: const [],
        summary: AttendanceSummary(
          totalStudents: 0,
          totalPresent: 0,
          totalAbsent: 0,
          totalLate: 0,
          totalHalfday: 0,
        ),
        message: 'No class/section assigned to load student analytics.',
      );
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final startDate = _formatApiDate(start);
    final endDate = _formatApiDate(now);

    try {
      return await StudentAttendanceService.getAttendanceReport(
        classId: target.classId,
        sectionId: target.sectionId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      // Some deployments return an HTML 404 page (often with status 200) for
      // missing endpoints. In that case, fall back to computing analytics from
      // the existing studentAttendance?action=get API.
      if (_shouldFallbackFromReportEndpointError(e)) {
        return _buildStudentReportFromDailyAttendance(
          target: target,
          startDate: startDate,
          endDate: endDate,
        );
      }
      rethrow;
    }
  }

  bool _shouldFallbackFromReportEndpointError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('html instead of json') ||
        msg.contains('404') ||
        msg.contains('page not found') ||
        msg.contains('getstudentattendancereport');
  }

  Future<StudentAttendanceReportResponse>
  _buildStudentReportFromDailyAttendance({
    required _ClassSectionRef target,
    required String startDate,
    required String endDate,
  }) async {
    DateTime? start;
    DateTime? end;
    try {
      start = DateTime.parse(startDate);
      end = DateTime.parse(endDate);
    } catch (_) {
      start = null;
      end = null;
    }

    if (start == null || end == null) {
      return StudentAttendanceReportResponse(
        status: 'error',
        classId: target.classId,
        sectionId: target.sectionId,
        startDate: startDate,
        endDate: endDate,
        totalDays: 0,
        students: const [],
        summary: AttendanceSummary(
          totalStudents: 0,
          totalPresent: 0,
          totalAbsent: 0,
          totalLate: 0,
          totalHalfday: 0,
        ),
        message: 'Invalid date range for analytics.',
      );
    }

    final Map<int, _StudentAgg> byEnrollId = {};
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalLate = 0;
    int totalHalfday = 0;

    int daysRequested = 0;
    int daysSucceeded = 0;

    // Inclusive range
    for (
      DateTime cursor = start;
      !cursor.isAfter(end);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      daysRequested++;
      final dateStr = _formatApiDate(cursor);

      try {
        final resp = await StudentAttendanceService.getStudentAttendance(
          classId: target.classId,
          sectionId: target.sectionId,
          date: dateStr,
        );

        if ((resp['status']?.toString() ?? '') != 'success') {
          continue;
        }

        final data = resp['data'];
        final students = (data is Map<String, dynamic>)
            ? (data['students'] as List?)
            : null;

        if (students == null) {
          continue;
        }

        daysSucceeded++;

        for (final raw in students) {
          if (raw is! Map<String, dynamic>) continue;

          final enrollId =
              int.tryParse(raw['enroll_id']?.toString() ?? '') ?? 0;
          if (enrollId == 0) continue;

          final studentId =
              int.tryParse(raw['student_id']?.toString() ?? '') ?? 0;
          final name = raw['name']?.toString() ?? '';
          final registerNo = raw['register_no']?.toString() ?? '';
          final roll = raw['roll']?.toString();
          final photo = raw['photo']?.toString() ?? '';

          var status = (raw['attendance_status']?.toString() ?? '')
              .trim()
              .toUpperCase();
          if (status == 'HD') status = 'H';
          if (status.isEmpty) {
            // Not marked; don't count this day.
            byEnrollId
                .putIfAbsent(
                  enrollId,
                  () => _StudentAgg(
                    enrollId: enrollId,
                    studentId: studentId,
                    name: name,
                    registerNo: registerNo,
                    roll: roll,
                    photo: photo,
                  ),
                )
                .touchMeta(
                  studentId: studentId,
                  name: name,
                  registerNo: registerNo,
                  roll: roll,
                  photo: photo,
                );
            continue;
          }

          final agg = byEnrollId.putIfAbsent(
            enrollId,
            () => _StudentAgg(
              enrollId: enrollId,
              studentId: studentId,
              name: name,
              registerNo: registerNo,
              roll: roll,
              photo: photo,
            ),
          );
          agg.touchMeta(
            studentId: studentId,
            name: name,
            registerNo: registerNo,
            roll: roll,
            photo: photo,
          );

          agg.totalMarkedDays++;

          switch (status) {
            case 'P':
              agg.present++;
              totalPresent++;
              break;
            case 'A':
              agg.absent++;
              totalAbsent++;
              break;
            case 'L':
              agg.late++;
              totalLate++;
              break;
            case 'H':
              agg.halfday++;
              totalHalfday++;
              break;
            default:
              // Unknown status; ignore.
              break;
          }
        }
      } catch (_) {
        // Skip day on network/auth errors
        continue;
      }
    }

    final students = byEnrollId.values
        .map((a) => a.toReportItem())
        .toList(growable: false);

    final message = daysSucceeded == 0
        ? 'No daily attendance data available for this range.'
        : (daysSucceeded < daysRequested
              ? 'Computed from daily attendance (partial data: $daysSucceeded/$daysRequested days).'
              : 'Computed from daily attendance.');

    return StudentAttendanceReportResponse(
      status: 'success',
      classId: target.classId,
      sectionId: target.sectionId,
      startDate: startDate,
      endDate: endDate,
      totalDays: daysRequested,
      students: students,
      summary: AttendanceSummary(
        totalStudents: students.length,
        totalPresent: totalPresent,
        totalAbsent: totalAbsent,
        totalLate: totalLate,
        totalHalfday: totalHalfday,
      ),
      message: message,
    );
  }

  Future<void> _reloadStudentAttendanceReport() async {
    setState(() {
      _studentReportFuture = _loadStudentAttendanceReport();
    });
    try {
      await _studentReportFuture;
    } catch (_) {
      // handled by FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((t) {
                    switch (t.type) {
                      case _AnalyticsTabType.self:
                        return isLoading
                            ? _buildAnimatedLoadingView()
                            : error != null
                            ? _buildErrorWidget()
                            : _buildStatisticsContent();
                      case _AnalyticsTabType.student:
                        return _buildStudentAttendanceAnalytics();
                      case _AnalyticsTabType.adminTeacher:
                        return _buildAdminTeacherAttendance();
                      case _AnalyticsTabType.otherRoles:
                        return _buildOtherRolesAttendance();
                    }
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLoadingView() {
    return FadeTransition(
      opacity: _loadingAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing Attendance...',
              style: AppTheme.headingSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Gathering your latest insights', style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final selectedIndex = _tabController.index.clamp(
      0,
      (_tabs.length - 1).clamp(0, 999),
    );
    final showFilter = _tabs.isNotEmpty
        ? _tabs[selectedIndex].showFilter
        : true;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dashboardPrimaryLight.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              if (showFilter) _buildFilterBadge(),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Attendance Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Performance and tracking analysis',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 14),
          _buildRoleTabs(),
        ],
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.dashboardPrimary,
        unselectedLabelColor: Colors.white.withOpacity(0.85),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: _tabs
            .map(
              (t) => Tab(
                child: Text(
                  t.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildStudentAttendanceAnalytics() {
    _studentReportFuture ??= _loadStudentAttendanceReport();

    return RefreshIndicator(
      onRefresh: _reloadStudentAttendanceReport,
      child: FutureBuilder<StudentAttendanceReportResponse>(
        future: _studentReportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 40),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              children: [
                _buildStudentAnalyticsInfoCard(
                  title: 'Student Analytics',
                  subtitle: 'Failed to load report. Pull down to retry.',
                  icon: Icons.error_outline_rounded,
                ),
              ],
            );
          }

          final report = snapshot.data;
          if (report == null || !report.isSuccess) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              children: [
                _buildStudentAnalyticsInfoCard(
                  title: 'Student Analytics',
                  subtitle: report?.message.isNotEmpty == true
                      ? report!.message
                      : 'No data available. Pull down to refresh.',
                  icon: Icons.info_outline_rounded,
                ),
              ],
            );
          }

          final summary = report.summary;
          final targetLabel = _studentReportTarget?.label;

          final students = List<StudentAttendanceReportItem>.from(
            report.students,
          );
          students.sort(
            (a, b) => b.attendancePercentage.compareTo(a.attendancePercentage),
          );
          final topStudents = students.take(5).toList(growable: false);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (targetLabel != null && targetLabel.isNotEmpty)
                              ? targetLabel
                              : 'Selected Class/Section',
                          style: TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _reloadStudentAttendanceReport,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Range: ${report.startDate} → ${report.endDate}',
                style: TextStyle(
                  color: AppTheme.textGray.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (report.message.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  report.message,
                  style: TextStyle(
                    color: AppTheme.textGray.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MiniStatCard(
                    title: 'Students',
                    value: summary.totalStudents.toString(),
                    icon: Icons.groups_rounded,
                    gradient: AppTheme.primaryGradient.colors,
                  ),
                  _MiniStatCard(
                    title: 'Present',
                    value: summary.totalPresent.toString(),
                    icon: Icons.verified_rounded,
                    gradient: AppTheme.successGradient.colors,
                  ),
                  _MiniStatCard(
                    title: 'Absent',
                    value: summary.totalAbsent.toString(),
                    icon: Icons.cancel_rounded,
                    gradient: AppTheme.errorGradient.colors,
                  ),
                  _MiniStatCard(
                    title: 'Late',
                    value: summary.totalLate.toString(),
                    icon: Icons.timer_rounded,
                    gradient: AppTheme.warningGradient.colors,
                  ),
                  _MiniStatCard(
                    title: 'Halfday',
                    value: summary.totalHalfday.toString(),
                    icon: Icons.timelapse_rounded,
                    gradient: AppTheme.infoGradient.colors,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DonutChartCard(
                title: 'Distribution',
                centerTopText: 'Total',
                centerValueText:
                    (summary.totalPresent +
                            summary.totalAbsent +
                            summary.totalLate +
                            summary.totalHalfday)
                        .toString(),
                elevated: true,
                slices: [
                  _DonutSlice(
                    label: 'Present',
                    value: summary.totalPresent.toDouble(),
                    color: AppTheme.accentGreen,
                  ),
                  _DonutSlice(
                    label: 'Absent',
                    value: summary.totalAbsent.toDouble(),
                    color: AppTheme.accentRed,
                  ),
                  _DonutSlice(
                    label: 'Late',
                    value: summary.totalLate.toDouble(),
                    color: AppTheme.warningOrange,
                  ),
                  _DonutSlice(
                    label: 'Halfday',
                    value: summary.totalHalfday.toDouble(),
                    color: AppTheme.infoBlue,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top Students (by %)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (topStudents.isEmpty)
                      Text(
                        'No student data for this range.',
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      ...topStudents.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'P:${s.presentCount}  A:${s.absentCount}  L:${s.lateCount}  H:${s.halfdayCount}',
                                      style: TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: AppTheme.buttonShadow,
                                ),
                                child: Text(
                                  '${s.attendancePercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentAnalyticsInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.dashboardPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.dashboardPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTeacherAttendance() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCard(
            title: 'Teacher Attendance',
            subtitle: 'Use face / quick attendance modules',
            primaryLabel: 'Teacher Attendance',
            primaryIcon: Icons.face_retouching_natural_rounded,
            onPrimary: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeacherAttendanceScreen()),
              );
            },
            secondaryLabel: 'Weekend Inspection',
            secondaryIcon: Icons.insights_rounded,
            onSecondary: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeekendAttendanceInspectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherRolesAttendance() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionCard(
            title: 'Other Roles Attendance',
            subtitle: 'Use quick attendance (check-in / check-out)',
            primaryLabel: 'Quick Attendance',
            primaryIcon: Icons.qr_code_scanner_rounded,
            onPrimary: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuickAttendanceScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            selectedFilterValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 72,
              color: AppTheme.errorRed.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text('Oops! Something went wrong', style: AppTheme.headingSmall),
            const SizedBox(height: 8),
            Text(
              error ?? 'We couldn\'t load your statistics.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: loadStatistics,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    if (statisticsData == null) return const SizedBox();

    return FadeTransition(
      opacity: _contentAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_contentAnimation),
        child: RefreshIndicator(
          onRefresh: _reloadStatistics,
          color: AppTheme.primaryPurple,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedSection(_buildTodayStatus(), 0.0, 0.3),
                const SizedBox(height: 28),
                _buildAnimatedSection(_buildOverviewGrid(), 0.2, 0.5),
                const SizedBox(height: 28),
                _buildAnimatedSection(_buildAttendanceChart(), 0.4, 0.7),
                const SizedBox(height: 28),
                _buildSectionHeader('Recent Activity'),
                const SizedBox(height: 16),
                _buildAnimatedSection(_buildRecentActivityDiagram(), 0.55, 0.8),
                const SizedBox(height: 28),
                _buildSectionHeader('Monthly Activity'),
                const SizedBox(height: 16),
                _buildAnimatedSection(_buildAttendanceRecords(), 0.6, 1.0),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(Widget child, double start, double end) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _staggerAnimationController,
              curve: Interval(start, end, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerAnimationController,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTodayStatus() {
    final todayStatus = statisticsData!['today_status'] as Map<String, dynamic>;
    final status = todayStatus['status'] as String;

    Color statusColor;
    IconData statusIcon;
    List<Color> gradient;

    switch (status) {
      case 'P':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.verified_rounded;
        gradient = AppTheme.successGradient.colors;
        break;
      case 'A':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel_rounded;
        gradient = AppTheme.errorGradient.colors;
        break;
      case 'H':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.time_to_leave_rounded;
        gradient = AppTheme.warningGradient.colors;
        break;
      case 'L':
        statusColor = AppTheme.primaryPurple;
        statusIcon = Icons.timer_rounded;
        gradient = AppTheme.primaryGradient.colors;
        break;
      default:
        statusColor = AppTheme.textGray;
        statusIcon = Icons.help_rounded;
        gradient = [AppTheme.textGray, AppTheme.textGray.withOpacity(0.8)];
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: statusColor.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Status',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayStatus['status_text'] ?? 'Unknown',
                      style: AppTheme.headingSmall.copyWith(
                        color: statusColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (todayStatus['check_in_time'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      todayStatus['check_in_time'],
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('Check-in', style: AppTheme.bodySmall),
                  ],
                ),
            ],
          ),
          if (todayStatus['face_verified'] ||
              todayStatus['location_verified']) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (todayStatus['face_verified'])
                  _buildStatusChip(
                    'Face Verified',
                    Icons.face_retouching_natural_rounded,
                    AppTheme.accentCyan,
                  ),
                if (todayStatus['location_verified'])
                  _buildStatusChip(
                    'Location Match',
                    Icons.location_on_rounded,
                    AppTheme.infoBlue,
                  ),
                if (todayStatus['gps_verified'])
                  _buildStatusChip(
                    'GPS Fixed',
                    Icons.gps_fixed_rounded,
                    AppTheme.primaryPurple,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    final summaryStats =
        statisticsData!['summary_stats'] as Map<String, dynamic>;

    return Row(
      children: [
        Expanded(
          child: _PremiumOverviewCard(
            title: 'Present',
            value: summaryStats['present_days'].toString(),
            subtitle: '${summaryStats['present_percentage']}% Rate',
            icon: Icons.check_circle_rounded,
            gradient: AppTheme.successGradient.colors,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _PremiumOverviewCard(
            title: 'Absent',
            value: summaryStats['absent_days'].toString(),
            subtitle: 'This Period',
            icon: Icons.cancel_rounded,
            gradient: AppTheme.errorGradient.colors,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final summaryStats =
        statisticsData!['summary_stats'] as Map<String, dynamic>;
    final total = (summaryStats['total_days'] as int?) ?? 0;
    final present = (summaryStats['present_days'] as int?) ?? 0;
    final absent = (summaryStats['absent_days'] as int?) ?? 0;

    // Use record list to derive distribution (includes L/H when available)
    final counts = _computeTeacherStatusCounts();
    final late = counts.late;
    final halfday = counts.halfday;

    // If API doesn't provide L/H in records, fall back to total split
    final hasExtra = late > 0 || halfday > 0;
    final presentForChart = hasExtra ? counts.present : present;
    final absentForChart = hasExtra ? counts.absent : absent;
    final totalForCenter = hasExtra
        ? (counts.present + counts.absent + counts.late + counts.halfday)
        : total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _DonutChartCard(
            title: 'Distribution',
            centerTopText: 'Total',
            centerValueText: totalForCenter.toString(),
            elevated: false,
            slices: [
              _DonutSlice(
                label: 'Present',
                value: presentForChart.toDouble(),
                color: AppTheme.accentGreen,
              ),
              _DonutSlice(
                label: 'Absent',
                value: absentForChart.toDouble(),
                color: AppTheme.accentRed,
              ),
              _DonutSlice(
                label: 'Late',
                value: late.toDouble(),
                color: AppTheme.primaryPurple,
              ),
              _DonutSlice(
                label: 'Holiday',
                value: halfday.toDouble(),
                color: AppTheme.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _TeacherStatusCounts _computeTeacherStatusCounts() {
    try {
      final records =
          (statisticsData?['attendance_records'] as List?) ?? const [];
      var present = 0;
      var absent = 0;
      var late = 0;
      var halfday = 0;

      for (final raw in records) {
        if (raw is! Map) continue;
        var status = (raw['status']?.toString() ?? '').trim().toUpperCase();
        if (status == 'HD') status = 'H';
        switch (status) {
          case 'P':
            present++;
            break;
          case 'A':
            absent++;
            break;
          case 'L':
            late++;
            break;
          case 'H':
            halfday++;
            break;
          default:
            break;
        }
      }

      return _TeacherStatusCounts(
        present: present,
        absent: absent,
        late: late,
        halfday: halfday,
      );
    } catch (_) {
      return const _TeacherStatusCounts(
        present: 0,
        absent: 0,
        late: 0,
        halfday: 0,
      );
    }
  }

  Widget _buildRecentActivityDiagram() {
    final records = (statisticsData!['attendance_records'] as List);

    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 48,
              color: AppTheme.textGray.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            const Text(
              'No activity to show yet',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    final recent = records.take(14).toList();

    Color statusColor(String status) {
      switch (status) {
        case 'P':
          return AppTheme.accentGreen;
        case 'A':
          return AppTheme.accentRed;
        case 'H':
          return AppTheme.accentOrange;
        case 'L':
          return AppTheme.primaryPurple;
        default:
          return AppTheme.textGray;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last ${recent.length} entries',
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in recent)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor(
                      (r['status'] ?? '').toString(),
                    ).withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend('Present', 0, AppTheme.accentGreen),
              _buildLegend('Absent', 0, AppTheme.accentRed),
              _buildLegend('Holiday', 0, AppTheme.accentOrange),
              _buildLegend('Late', 0, AppTheme.primaryPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.headingSmall.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    );
  }

  Widget _buildAttendanceRecords() {
    final records = statisticsData!['attendance_records'] as List;

    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: AppTheme.textGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No recent records found',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.take(10).length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildRecordListItem(record);
      },
    );
  }

  Widget _buildRecordListItem(Map<String, dynamic> record) {
    final status = record['status'] as String;
    Color color;
    switch (status) {
      case 'P':
        color = AppTheme.successGreen;
        break;
      case 'A':
        color = AppTheme.errorRed;
        break;
      case 'H':
        color = AppTheme.warningOrange;
        break;
      default:
        color = AppTheme.primaryPurple;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.smallShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _formatDay(record['date']),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatMonth(record['date']),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
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
                  record['status_text'] ?? 'Unknown',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (record['check_in_time'] != null)
                  Text(
                    'Time: ${record['check_in_time']}',
                    style: AppTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (record['face_verified'])
            Icon(
              Icons.face_unlock_rounded,
              color: AppTheme.accentCyan.withOpacity(0.5),
              size: 20,
            ),
        ],
      ),
    );
  }

  String _formatDay(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return dt.day.toString();
    } catch (_) {
      return '--';
    }
  }

  String _formatMonth(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return months[dt.month - 1];
    } catch (_) {
      return '---';
    }
  }
}

class _ClassSectionRef {
  final int classId;
  final int sectionId;
  final String label;

  const _ClassSectionRef({
    required this.classId,
    required this.sectionId,
    required this.label,
  });
}

enum _AnalyticsTabType { self, student, adminTeacher, otherRoles }

class _AnalyticsTab {
  final String label;
  final _AnalyticsTabType type;
  final bool showFilter;

  const _AnalyticsTab({
    required this.label,
    required this.type,
    required this.showFilter,
  });
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutSlice {
  const _DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class _TeacherStatusCounts {
  const _TeacherStatusCounts({
    required this.present,
    required this.absent,
    required this.late,
    required this.halfday,
  });

  final int present;
  final int absent;
  final int late;
  final int halfday;
}

class _DonutChartCard extends StatelessWidget {
  const _DonutChartCard({
    required this.title,
    required this.slices,
    required this.centerTopText,
    required this.centerValueText,
    required this.elevated,
  });

  final String title;
  final List<_DonutSlice> slices;
  final String centerTopText;
  final String centerValueText;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    final effectiveSlices = slices
        .where((s) => s.value > 0)
        .toList(growable: false);
    final legendSlices = effectiveSlices.isNotEmpty
        ? effectiveSlices
        : slices.toList(growable: false);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: _DonutChartPainter(
                      slices: effectiveSlices,
                      backgroundColor: AppTheme.backgroundLight,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerTopText,
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        centerValueText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final s in legendSlices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DonutLegendRow(
                        label: s.label,
                        value: s.value.toInt(),
                        total: total,
                        color: s.color,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    if (!elevated) return content;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: content,
    );
  }
}

class _DonutLegendRow extends StatelessWidget {
  const _DonutLegendRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0 : ((value / total) * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
        const SizedBox(width: 8),
        Text(
          '$pct%',
          style: TextStyle(
            color: AppTheme.textGray.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({required this.slices, required this.backgroundColor});

  final List<_DonutSlice> slices;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 16.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, bgPaint);

    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final s in slices) {
      if (s.value <= 0) continue;
      final sweep = (s.value / total) * (math.pi * 2);
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _StudentAgg {
  final int enrollId;
  int studentId;
  String name;
  String registerNo;
  String? roll;
  String photo;

  int present = 0;
  int absent = 0;
  int late = 0;
  int halfday = 0;
  int totalMarkedDays = 0;

  _StudentAgg({
    required this.enrollId,
    required this.studentId,
    required this.name,
    required this.registerNo,
    required this.roll,
    required this.photo,
  });

  void touchMeta({
    required int studentId,
    required String name,
    required String registerNo,
    required String? roll,
    required String photo,
  }) {
    if (this.studentId == 0 && studentId != 0) this.studentId = studentId;
    if (this.name.isEmpty && name.isNotEmpty) this.name = name;
    if (this.registerNo.isEmpty && registerNo.isNotEmpty) {
      this.registerNo = registerNo;
    }
    if ((this.roll == null || this.roll!.isEmpty) &&
        (roll?.isNotEmpty == true)) {
      this.roll = roll;
    }
    if (this.photo.isEmpty && photo.isNotEmpty) this.photo = photo;
  }

  StudentAttendanceReportItem toReportItem() {
    final totalDays = totalMarkedDays;
    final effectivePresent = present + late + (halfday * 0.5);
    final percentage = totalDays <= 0
        ? 0.0
        : (effectivePresent / totalDays) * 100;

    return StudentAttendanceReportItem(
      enrollId: enrollId,
      studentId: studentId,
      name: name,
      registerNo: registerNo,
      roll: roll,
      photo: photo,
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      halfdayCount: halfday,
      totalAttendanceDays: totalDays,
      attendancePercentage: percentage,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;

  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTheme.textGray.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPrimary,
              icon: Icon(primaryIcon),
              label: Text(primaryLabel),
              style: AppTheme.primaryButtonStyle.copyWith(
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
                ),
              ),
            ),
          ),
          if (secondaryLabel != null &&
              secondaryIcon != null &&
              onSecondary != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSecondary,
                icon: Icon(secondaryIcon),
                label: Text(secondaryLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPurple,
                  side: BorderSide(color: AppTheme.borderGray),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _PremiumOverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              fontSize: 10,
              color: AppTheme.textGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
