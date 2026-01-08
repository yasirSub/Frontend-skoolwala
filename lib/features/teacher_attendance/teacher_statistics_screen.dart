import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:skoolwala/features/attendance/screens/quick_attendance_screen.dart';
import 'package:skoolwala/features/attendance/screens/weekend_attendance_inspection_screen.dart';
import 'package:skoolwala/features/teacher/models/today_class.dart';
import 'package:skoolwala/features/teacher/services/student_attendance_service.dart';
import 'package:skoolwala/features/teacher/services/teacher_class_service.dart';
import 'package:skoolwala/features/attendance/services/attendance_service.dart';
import 'package:skoolwala/features/teacher_attendance/teacher_attendance_screen.dart';
import 'package:skoolwala/shared/services/http_client.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:skoolwala/shared/widgets/premium_entrance_animation.dart';
import '../statistics/widgets/action_card.dart';

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

  // Student Analytics - Class & Subject Filter
  List<TeacherClass> _teacherClasses = [];
  _ClassSectionRef? _selectedStudentClass;
  bool _isLoadingClasses = false;

  // Subject-wise attendance support
  bool _isSubjectWise = false;
  List<Map<String, dynamic>> _availableSubjects = [];
  int? _selectedSubjectId;
  String? _selectedSubjectName;
  bool _isLoadingSubjects = false;
  bool _attendanceTypeLoaded = false;

  // Student Analytics Date Filter
  String _studentFilterType = 'month';
  String _studentFilterValue = DateTime.now().toString().substring(0, 7);

  // Animation controllers
  late AnimationController _loadingAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _staggerAnimationController;

  // Animations
  late Animation<double> _loadingAnimation;

  late final TabController _tabController;
  late final List<_AnalyticsTab> _tabs;

  @override
  void initState() {
    super.initState();

    final role = (SessionManager.instance.currentTeacher?.role ?? '')
        .toLowerCase();
    final isAdmin = role.contains('admin');

    _tabs = [
      _AnalyticsTab(
        label: isAdmin ? 'Admin' : 'Self',
        type: _AnalyticsTabType.self,
        showFilter: true,
      ),
      if (isAdmin)
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
      if (isAdmin)
        _AnalyticsTab(
          label: 'Other Roles',
          type: _AnalyticsTabType.otherRoles,
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

    // Start loading animation
    _loadingAnimationController.forward();

    loadStatistics();
    _loadAttendanceTypeAndClasses();
  }

  /// Load attendance type from backend and then load teacher's classes
  Future<void> _loadAttendanceTypeAndClasses() async {
    try {
      // First load attendance type
      final response = await AttendanceService.getAttendanceType();

      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'];
        final newIsSubjectWise =
            data['is_subject_wise'] == true ||
            data['is_subject_wise'] == 'true' ||
            data['is_subject_wise'] == 1 ||
            data['is_subject_wise'] == '1';

        if (mounted) {
          setState(() {
            _isSubjectWise = newIsSubjectWise;
            _attendanceTypeLoaded = true;
          });
        }
      }
    } catch (e) {
      // Default to day-wise if error
      if (mounted) {
        setState(() {
          _isSubjectWise = false;
          _attendanceTypeLoaded = true;
        });
      }
    }

    // Then load classes
    await _loadTeacherClasses();
  }

  /// Load teacher's assigned classes
  Future<void> _loadTeacherClasses() async {
    if (_isLoadingClasses) return;

    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final response = await TeacherClassService.getMyClasses();

      if (response.isSuccess && response.classes.isNotEmpty) {
        final classes = response.classes;
        // Debug print: log all loaded classes
        // ignore: avoid_print
        print('[DEBUG] Loaded teacher classes:');
        for (final c in classes) {
          print(
            '  - ${c.displayName} (classId: ${c.classId}, sectionId: ${c.sectionId})',
          );
        }

        // Set first class as default
        final firstClass = classes.first;
        final defaultRef = _ClassSectionRef(
          classId: firstClass.classId,
          sectionId: firstClass.sectionId,
          label: firstClass.displayName,
        );

        if (mounted) {
          setState(() {
            _teacherClasses = classes;
            _selectedStudentClass = defaultRef;
            _isLoadingClasses = false;
          });
        }

        // If subject-wise, load subjects for the selected class
        if (_isSubjectWise) {
          await _loadSubjectsForClass(firstClass.classId, firstClass.sectionId);
        }

        // Now load the student report
        _studentReportFuture = _loadStudentAttendanceReport();
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          setState(() {
            _teacherClasses = [];
            _isLoadingClasses = false;
          });
        }
        // Try to load with fallback method
        _studentReportFuture = _loadStudentAttendanceReport();
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _teacherClasses = [];
          _isLoadingClasses = false;
        });
      }
      // Still try to load student report with fallback
      _studentReportFuture = _loadStudentAttendanceReport();
      if (mounted) setState(() {});
    }
  }

  /// Load subjects for a specific class/section (for subject-wise mode)
  Future<void> _loadSubjectsForClass(int classId, int sectionId) async {
    if (!_isSubjectWise) return;

    setState(() {
      _isLoadingSubjects = true;
      _availableSubjects = [];
      _selectedSubjectId = null;
      _selectedSubjectName = null;
    });

    try {
      final response = await TeacherClassService.getSubjectsForClassSection(
        classId: classId,
        sectionId: sectionId,
      );

      if (response['status'] == 'success') {
        final subjectsList = (response['data'] as List?) ?? [];
        final subjects = subjectsList
            .map((s) => s as Map<String, dynamic>)
            .toList();

        if (mounted) {
          setState(() {
            _availableSubjects = subjects;
            if (subjects.isNotEmpty) {
              final firstSubject = subjects.first;
              _selectedSubjectId = int.tryParse(
                firstSubject['subject_id']?.toString() ?? '',
              );
              _selectedSubjectName = firstSubject['name']?.toString();
            }
            _isLoadingSubjects = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _availableSubjects = [];
            _isLoadingSubjects = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableSubjects = [];
          _isLoadingSubjects = false;
        });
      }
    }
  }

  /// Handle class selection change
  void _onClassSelected(_ClassSectionRef classRef) {
    if (_selectedStudentClass?.classId == classRef.classId &&
        _selectedStudentClass?.sectionId == classRef.sectionId) {
      return;
    }

    setState(() {
      _selectedStudentClass = classRef;
      _studentReportTarget = classRef;
      _selectedSubjectId = null;
      _selectedSubjectName = null;
    });

    // If subject-wise, load subjects for the new class
    if (_isSubjectWise) {
      _loadSubjectsForClass(classRef.classId, classRef.sectionId).then((_) {
        _reloadStudentReport();
      });
    } else {
      _reloadStudentReport();
    }
  }

  /// Handle subject selection change
  void _onSubjectSelected(int subjectId, String subjectName) {
    if (_selectedSubjectId == subjectId) return;

    setState(() {
      _selectedSubjectId = subjectId;
      _selectedSubjectName = subjectName;
    });

    _reloadStudentReport();
  }

  /// Reload student report with current filters
  void _reloadStudentReport() {
    setState(() {
      _studentReportFuture = _loadStudentAttendanceReport();
    });
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

  String _getFilterDisplayText() {
    return _getFilterDisplayTextFor(selectedFilterType, selectedFilterValue);
  }

  /// Shared helper to format filter display text
  String _getFilterDisplayTextFor(String filterType, String filterValue) {
    if (filterType == 'month') {
      try {
        final parts = filterValue.split('-');
        if (parts.length == 2) {
          final months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final monthIndex = int.parse(parts[1]) - 1;
          return '${months[monthIndex]} ${parts[0]}';
        }
      } catch (_) {}
    }
    return filterValue;
  }

  void _showDateFilterSheet({bool forStudent = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkPurple,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SELECT PERIOD',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(
              'This Month',
              Icons.calendar_today_rounded,
              forStudent
                  ? (_studentFilterType == 'month' &&
                        _studentFilterValue == _getCurrentMonth())
                  : (selectedFilterType == 'month' &&
                        selectedFilterValue == _getCurrentMonth()),
              () {
                Navigator.pop(context);
                setState(() {
                  if (forStudent) {
                    _studentFilterType = 'month';
                    _studentFilterValue = _getCurrentMonth();
                  } else {
                    selectedFilterType = 'month';
                    selectedFilterValue = _getCurrentMonth();
                  }
                });
                if (forStudent) {
                  _reloadStudentReport();
                } else {
                  _reloadStatistics();
                }
              },
            ),
            const SizedBox(height: 8),
            _buildFilterOption(
              'Last Month',
              Icons.history_rounded,
              forStudent
                  ? (_studentFilterType == 'month' &&
                        _studentFilterValue == _getLastMonth())
                  : (selectedFilterType == 'month' &&
                        selectedFilterValue == _getLastMonth()),
              () {
                Navigator.pop(context);
                setState(() {
                  if (forStudent) {
                    _studentFilterType = 'month';
                    _studentFilterValue = _getLastMonth();
                  } else {
                    selectedFilterType = 'month';
                    selectedFilterValue = _getLastMonth();
                  }
                });
                if (forStudent) {
                  _reloadStudentReport();
                } else {
                  _reloadStatistics();
                }
              },
            ),
            const SizedBox(height: 8),
            _buildFilterOption(
              'Custom Date Range',
              Icons.date_range_rounded,
              forStudent
                  ? _studentFilterType == 'daterange'
                  : selectedFilterType == 'daterange',
              () {
                Navigator.pop(context);
                _showDateRangePicker(forStudent: forStudent);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryPurple
                  : Colors.white.withOpacity(0.7),
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryPurple,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _getLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';
  }

  Future<void> _showDateRangePicker({bool forStudent = false}) async {
    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, 1);
    DateTime endDate = now;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkPurple,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SELECT DATE RANGE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePickerField(
                      'From Date',
                      startDate,
                      (picked) => setSheetState(() => startDate = picked),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePickerField(
                      'To Date',
                      endDate,
                      (picked) => setSheetState(() => endDate = picked),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final startStr = _formatApiDate(startDate);
                    final endStr = _formatApiDate(endDate);
                    setState(() {
                      if (forStudent) {
                        _studentFilterType = 'daterange';
                        _studentFilterValue = '$startStr to $endStr';
                      } else {
                        selectedFilterType = 'daterange';
                        selectedFilterValue = '$startStr to $endStr';
                      }
                    });
                    if (forStudent) {
                      _reloadStudentReport();
                    } else {
                      _reloadStatistics();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filter',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    DateTime date,
    Function(DateTime) onPicked,
  ) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(DateTime.now().year - 2),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppTheme.primaryPurple,
                  onPrimary: Colors.white,
                  surface: AppTheme.darkPurple,
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: AppTheme.darkPurple,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.primaryPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    // Use selected class if available, otherwise fall back to default
    _ClassSectionRef? target = _selectedStudentClass;

    if (target == null) {
      target = await _loadDefaultClassSectionForStudentReport();
      _selectedStudentClass = target;
    }

    _studentReportTarget = target;

    final now = DateTime.now();
    String startDate;
    String endDate;

    if (_studentFilterType == 'daterange' &&
        _studentFilterValue.contains(' to ')) {
      // Custom date range
      final parts = _studentFilterValue.split(' to ');
      startDate = parts[0];
      endDate = parts[1];
    } else if (_studentFilterType == 'month') {
      // Month filter
      try {
        final parts = _studentFilterValue.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final start = DateTime(year, month, 1);
        final lastDayOfMonth = DateTime(year, month + 1, 0);
        final end = lastDayOfMonth.isAfter(now) ? now : lastDayOfMonth;
        startDate = _formatApiDate(start);
        endDate = _formatApiDate(end);
      } catch (_) {
        final start = DateTime(now.year, now.month, 1);
        startDate = _formatApiDate(start);
        endDate = _formatApiDate(now);
      }
    } else {
      // Default to current month
      final start = DateTime(now.year, now.month, 1);
      startDate = _formatApiDate(start);
      endDate = _formatApiDate(now);
    }

    final resolvedTarget = target;
    if (resolvedTarget == null ||
        resolvedTarget.classId == 0 ||
        resolvedTarget.sectionId == 0) {
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

    // Always show stats for the selected class (day-wise or subject-wise)
    if (_isSubjectWise && _selectedSubjectId != null) {
      try {
        return await StudentAttendanceService.getAttendanceReport(
          classId: resolvedTarget.classId,
          sectionId: resolvedTarget.sectionId,
          startDate: startDate,
          endDate: endDate,
          subjectId: _selectedSubjectId,
        );
      } catch (e) {
        if (_shouldFallbackFromReportEndpointError(e)) {
          return _buildStudentReportFromDailyAttendance(
            target: resolvedTarget,
            startDate: startDate,
            endDate: endDate,
          );
        }
        rethrow;
      }
    }

    try {
      return await StudentAttendanceService.getAttendanceReport(
        classId: resolvedTarget.classId,
        sectionId: resolvedTarget.sectionId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      if (_shouldFallbackFromReportEndpointError(e)) {
        return _buildStudentReportFromDailyAttendance(
          target: resolvedTarget,
          startDate: startDate,
          endDate: endDate,
        );
      }
      rethrow;
    }

    // Fallback: single class (should not happen, but for safety)
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

    // Default: single class
    try {
      return await StudentAttendanceService.getAttendanceReport(
        classId: target.classId,
        sectionId: target.sectionId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
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
  @override
  Widget build(BuildContext context) {
    final selectedIndex = _tabController.index.clamp(
      0,
      (_tabs.length - 1).clamp(0, 999),
    );
    final showFilter = _tabs.isNotEmpty
        ? _tabs[selectedIndex].showFilter
        : true;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tabs[selectedIndex].type == _AnalyticsTabType.self
                      ? 'Attendance Statistics'
                      : 'Academic Analytics',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showFilter ? selectedFilterValue : 'Analytics Overview',
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
            // Show Subject/Day badge only on Student tab
            if (_attendanceTypeLoaded &&
                _tabs[selectedIndex].type == _AnalyticsTabType.student)
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isSubjectWise
                            ? AppTheme.primaryPurple.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isSubjectWise
                              ? AppTheme.primaryPurple.withOpacity(0.5)
                              : Colors.green.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSubjectWise
                                ? Icons.menu_book_rounded
                                : Icons.calendar_today_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isSubjectWise ? 'Subject' : 'Day',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildRoleTabs(),
            ),
            const SizedBox(height: 16),
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
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Rotating Ring
                  RotationTransition(
                    turns: _loadingAnimationController,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.transparent, width: 4),
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                  // Inner Pulse Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOutSine,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Icon(
                          Icons.insights_rounded,
                          color: AppTheme.primaryPurple.withOpacity(0.8),
                          size: 32,
                        ),
                      );
                    },
                    onEnd: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Syncing Analytics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arranging clinical attendance data...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 8,
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar Actions
          Row(
            children: [
              _buildModernIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 32),
          // Title Row
          Text(
            _tabs[selectedIndex].type == _AnalyticsTabType.self
                ? 'Attendance Statistics'
                : 'Academic Analytics',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 32),
          _buildRoleTabs(),
        ],
      ),
    );
  }

  Widget _buildModernIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.dashboardPrimary,
        unselectedLabelColor: Colors.white.withOpacity(0.8),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: _tabs
            .map((t) => Tab(height: 38, child: Text(t.label.toUpperCase())))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildStudentAttendanceAnalytics() {
    _studentReportFuture ??= _loadStudentAttendanceReport();

    return Column(
      children: [
        // Class/Subject Filter Section
        _buildStudentAnalyticsFilters(),

        // Main Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reloadStudentAttendanceReport,
            color: Colors.white,
            backgroundColor: AppTheme.primaryPurple,
            child: FutureBuilder<StudentAttendanceReportResponse>(
              future: _studentReportFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading student data...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildStudentEmptyState(
                    'Failed to Load',
                    'Error loading student data. Pull down to retry.',
                    Icons.error_outline_rounded,
                  );
                }

                final report = snapshot.data;
                if (report == null || !report.isSuccess) {
                  return _buildStudentEmptyState(
                    'No Data',
                    report?.message.isNotEmpty == true
                        ? report!.message
                        : 'No student data available for this class.',
                    Icons.school_outlined,
                  );
                }

                final summary = report.summary;
                final targetLabel =
                    _studentReportTarget?.label ?? 'Selected Class';
                final students = List<StudentAttendanceReportItem>.from(
                  report.students,
                );
                students.sort(
                  (a, b) =>
                      b.attendancePercentage.compareTo(a.attendancePercentage),
                );
                final topStudents = students.take(5).toList(growable: false);

                final totalRecords =
                    summary.totalPresent +
                    summary.totalAbsent +
                    summary.totalLate +
                    summary.totalHalfday;
                final attendanceRate = totalRecords > 0
                    ? ((summary.totalPresent / totalRecords) * 100)
                    : 0.0;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header Section
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: PremiumEntranceAnimation(
                          index: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLASS REPORT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withOpacity(0.6),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                targetLabel,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                ),
                                child: Text(
                                  '${summary.totalStudents} STUDENTS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Quick Stats Row
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: PremiumEntranceAnimation(
                          index: 1,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Attendance',
                                  '${attendanceRate.toStringAsFixed(0)}%',
                                  attendanceRate >= 75
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Present',
                                  summary.totalPresent.toString(),
                                  AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickStatCard(
                                  'Absent',
                                  summary.totalAbsent.toString(),
                                  AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Weekly Attendance Chart Section
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: PremiumEntranceAnimation(
                          index: 2,
                          child: _buildStudentWeeklyChart(
                            totalPresent: summary.totalPresent,
                            totalAbsent: summary.totalAbsent,
                          ),
                        ),
                      ),
                    ),

                    // Top Performers Section
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: PremiumEntranceAnimation(
                          index: 2,
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amberAccent.withOpacity(0.9),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'TOP PERFORMERS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Student Cards
                    if (topStudents.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: PremiumEntranceAnimation(
                            index: 3,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                'No student data available',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final student = topStudents[index];
                            return PremiumEntranceAnimation(
                              index: index + 3,
                              child: _buildStudentRankCard(student, index + 1),
                            );
                          }, childCount: topStudents.length),
                        ),
                      ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build the class/subject filter section for student analytics
  Widget _buildStudentAnalyticsFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Filter Row
          _buildStudentDateFilter(),
          const SizedBox(height: 12),

          // Class Selector
          _buildClassSelector(),

          // Subject Selector (only if subject-wise mode)
          if (_isSubjectWise) ...[
            const SizedBox(height: 12),
            _buildSubjectSelector(),
          ],
        ],
      ),
    );
  }

  /// Build date filter for student analytics - reuses existing filter sheet
  Widget _buildStudentDateFilter() {
    return GestureDetector(
      onTap: () => _showDateFilterSheet(forStudent: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPurple,
                    AppTheme.primaryPurple.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATE RANGE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFilterDisplayTextFor(
                      _studentFilterType,
                      _studentFilterValue,
                    ).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  /// Build class dropdown selector
  Widget _buildClassSelector() {
    if (_isLoadingClasses) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'LOADING CLASSES...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (_teacherClasses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.errorRed,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              'NO CLASSES ASSIGNED',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showClassSelectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_rounded,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECTED CLASS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedStudentClass?.label.toUpperCase() ??
                        'CHOOSE A CLASS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_circle_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Build subject dropdown selector (for subject-wise mode)
  Widget _buildSubjectSelector() {
    if (_isLoadingSubjects) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryPurple,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'LOADING SUBJECTS...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (_availableSubjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showSubjectSelectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELECTED SUBJECT',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedSubjectName?.toUpperCase() ?? 'CHOOSE A SUBJECT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_circle_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Show class selection bottom sheet
  void _showClassSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkPurple,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SELECT CLASS',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _teacherClasses.length,
                itemBuilder: (context, index) {
                  final classItem = _teacherClasses[index];
                  final isSelected =
                      _selectedStudentClass?.classId == classItem.classId &&
                      _selectedStudentClass?.sectionId == classItem.sectionId;

                  return _buildSelectionItem(
                    title: classItem.displayName,
                    subtitle: '${classItem.studentCount} students',
                    icon: Icons.class_rounded,
                    isSelected: isSelected,
                    onTap: () {
                      Navigator.pop(context);
                      _onClassSelected(
                        _ClassSectionRef(
                          classId: classItem.classId,
                          sectionId: classItem.sectionId,
                          label: classItem.displayName,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show subject selection bottom sheet
  void _showSubjectSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkPurple,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SELECT SUBJECT',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableSubjects.length,
                itemBuilder: (context, index) {
                  final subject = _availableSubjects[index];
                  final subjectId = int.tryParse(
                    subject['subject_id']?.toString() ?? '',
                  );
                  final subjectName = subject['name']?.toString() ?? 'Unknown';
                  final isSelected = _selectedSubjectId == subjectId;

                  return _buildSelectionItem(
                    title: subjectName,
                    subtitle: subject['subject_code']?.toString() ?? '',
                    icon: Icons.menu_book_rounded,
                    isSelected: isSelected,
                    iconColor: Colors.amber,
                    onTap: () {
                      Navigator.pop(context);
                      if (subjectId != null) {
                        _onSubjectSelected(subjectId, subjectName);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a selection item for bottom sheets
  Widget _buildSelectionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryPurple.withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryPurple.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppTheme.primaryPurple).withOpacity(
                      0.15,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppTheme.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryPurple,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRankCard(StudentAttendanceReportItem student, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? LinearGradient(
                      colors: [
                        Colors.amberAccent,
                        Colors.amberAccent.withOpacity(0.6),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: rank <= 3
                  ? [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3 ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildCompactMiniStat(
                      'P',
                      student.presentCount,
                      AppTheme.successGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactMiniStat(
                      'A',
                      student.absentCount,
                      AppTheme.errorRed,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactMiniStat(
                      'L',
                      student.lateCount,
                      AppTheme.warningOrange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryPurple,
                  AppTheme.primaryPurple.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${student.attendancePercentage.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMiniStat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildStudentEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentWeeklyChart({int totalPresent = 0, int totalAbsent = 0}) {
    // Use real data from the summary
    final weekData = _getStudentWeeklyData(
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.primaryPurple.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'WEEKLY OVERVIEW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF5B9BD5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Present',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A0A0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Absent',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bar Chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((day) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 14,
                              height: (day['present'] as int) * 12.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B9BD5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 14,
                              height: (day['absent'] as int) * 12.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8A0A0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day['date'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getStudentWeeklyData({
    int totalPresent = 0,
    int totalAbsent = 0,
  }) {
    // Show real data distribution across the week based on summary
    // If no data, show empty bars
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Calculate how many weekdays we have in the last 7 days
    int weekdayCount = 0;
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      if (date.weekday != 6 && date.weekday != 7) {
        weekdayCount++;
      }
    }

    // Distribute the totals evenly across weekdays (approximate visualization)
    final presentPerDay = weekdayCount > 0
        ? (totalPresent / weekdayCount).round()
        : 0;
    final absentPerDay = weekdayCount > 0
        ? (totalAbsent / weekdayCount).round()
        : 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final isWeekend = date.weekday == 6 || date.weekday == 7;
      data.add({
        'date': '${date.day}-${months[date.month - 1]}',
        'present': isWeekend ? 0 : presentPerDay,
        'absent': isWeekend ? 0 : absentPerDay,
      });
    }
    return data;
  }

  Widget _buildStudentAnalyticsInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.primaryPurple, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionCard(
            title: 'Teacher Attendance',
            subtitle: 'Enroll / mark attendance using various modules',
            primaryLabel: 'Face / Biometric',
            primaryIcon: Icons.face_retouching_natural_rounded,
            onPrimary: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeacherAttendanceScreen()),
              );
            },
            secondaryLabel: 'Weekend Audit',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionCard(
            title: 'Quick Attendance',
            subtitle: 'Direct check-in/out for specialized staff roles',
            primaryLabel: 'Scan / Register',
            primaryIcon: Icons.qr_code_scanner_rounded,
            onPrimary: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QuickAttendanceScreen()),
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
          const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 14,
          ),
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
    final summary = statisticsData!['summary_stats'];
    // API returns 'attendance_records' or 'records'
    final records =
        (statisticsData!['attendance_records'] ?? statisticsData!['records'])
            as List<dynamic>?;

    final presentPct = (summary['present_percentage'] ?? 0).toDouble();

    // Get today's check-in/out from today_status
    final todayStatus =
        statisticsData!['today_status'] as Map<String, dynamic>?;
    final todayCheckIn = (todayStatus?['check_in_time'] ?? '--:--').toString();
    final todayCheckOut = (todayStatus?['check_out_time'] ?? '--:--')
        .toString();

    // Calculate average check-in/out from records
    final avgTimes = _calculateAverageCheckTimes();
    final avgCheckIn = avgTimes['checkIn'] ?? todayCheckIn;
    final avgCheckOut = avgTimes['checkOut'] ?? todayCheckOut;

    return RefreshIndicator(
      onRefresh: _reloadStatistics,
      color: Colors.white,
      backgroundColor: AppTheme.primaryPurple,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Section
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MY ATTENDANCE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Statistics',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (todayStatus?['status'] == 'P'
                                        ? AppTheme.successGreen
                                        : AppTheme.warningOrange)
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  (todayStatus?['status'] == 'P'
                                          ? AppTheme.successGreen
                                          : AppTheme.warningOrange)
                                      .withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                todayStatus?['status'] == 'P'
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                size: 14,
                                color: todayStatus?['status'] == 'P'
                                    ? AppTheme.successGreen
                                    : AppTheme.warningOrange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                todayStatus?['status'] == 'P'
                                    ? 'PRESENT'
                                    : 'PENDING',
                                style: TextStyle(
                                  color: todayStatus?['status'] == 'P'
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date Filter Row
                    GestureDetector(
                      onTap: _showDateFilterSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Period',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedFilterType == 'daterange'
                                        ? selectedFilterValue
                                        : _getFilterDisplayText(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryPurple,
                                    AppTheme.primaryPurple.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Today's Status Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              (todayStatus?['status'] == 'P'
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange)
                                  .withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Icon(
                                todayStatus?['status'] == 'P'
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                size: 120,
                                color:
                                    (todayStatus?['status'] == 'P'
                                            ? AppTheme.successGreen
                                            : AppTheme.warningOrange)
                                        .withOpacity(0.05),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: (todayStatus?['status'] == 'P')
                                            ? [
                                                AppTheme.successGreen,
                                                const Color(0xFF00C49A),
                                              ]
                                            : [
                                                AppTheme.warningOrange,
                                                const Color(0xFFF2994A),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (todayStatus?['status'] == 'P'
                                                      ? AppTheme.successGreen
                                                      : AppTheme.warningOrange)
                                                  .withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      todayStatus?['status'] == 'P'
                                          ? Icons.how_to_reg_rounded
                                          : Icons.pending_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TODAY\'S STATUS',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          (todayStatus?['status_text'] ??
                                                  'Not Marked')
                                              .toString()
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (todayCheckIn != '--:--' &&
                                      todayCheckIn != 'null')
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'IN TIME',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successGreen
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            todayCheckIn,
                                            style: TextStyle(
                                              color: AppTheme.successGreen,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
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
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Average Check In/Out Row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeCard(
                        'Avg Check In',
                        avgCheckIn,
                        Icons.login_rounded,
                        AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeCard(
                        'Avg Check Out',
                        avgCheckOut,
                        Icons.logout_rounded,
                        AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Attendance Rate Card
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (presentPct >= 75
                                    ? AppTheme.successGreen
                                    : AppTheme.warningOrange)
                                .withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular Progress with Percentage
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circle
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 6,
                              ),
                            ),
                          ),
                          // Progress circle
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: presentPct / 100,
                              strokeWidth: 6,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                presentPct >= 75
                                    ? AppTheme.successGreen
                                    : AppTheme.warningOrange,
                              ),
                            ),
                          ),
                          // Percentage text
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${presentPct.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: presentPct >= 75
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  presentPct >= 75
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: presentPct >= 75
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ATTENDANCE RATE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              presentPct >= 90
                                  ? 'Excellent! Keep it up!'
                                  : presentPct >= 75
                                  ? 'Good standing'
                                  : presentPct >= 50
                                  ? 'Needs improvement'
                                  : 'Critical - Take action',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (presentPct >= 75
                                            ? AppTheme.successGreen
                                            : AppTheme.warningOrange)
                                        .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                presentPct >= 75
                                    ? '✓ On Track'
                                    : '⚠ Below Target',
                                style: TextStyle(
                                  color: presentPct >= 75
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),

          // Status Distribution Chart Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 3,
                child: Row(
                  children: [
                    Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'STATUS DISTRIBUTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 4,
                child: _buildWeeklyBarChart(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 5,
                child: _buildAttendanceChart(),
              ),
            ),
          ),

          // Attendance Records Section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
            sliver: SliverToBoxAdapter(
              child: PremiumEntranceAnimation(
                index: 5,
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ATTENDANCE RECORDS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Records List
          if (records != null && records.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final record = records[index] as Map<String, dynamic>;
                  return PremiumEntranceAnimation(
                    index: index + 6,
                    child: _buildAttendanceRecordCard(record),
                  );
                }, childCount: records.length > 10 ? 10 : records.length),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: PremiumEntranceAnimation(
                  index: 6,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Center(
                      child: Text(
                        'No attendance records found',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecordCard(Map<String, dynamic> record) {
    final status = record['status']?.toString();
    final statusText =
        (record['status_text'] ??
                record['status_full'] ??
                _getStatusText(status))
            .toString();
    final date = (record['date'] ?? record['attendance_date'] ?? '').toString();
    final day = (record['day'] ?? record['day_name'] ?? '').toString();
    final checkIn = (record['check_in_time'] ?? record['check_in'] ?? '--:--')
        .toString();
    final checkOut =
        (record['check_out_time'] ?? record['check_out'] ?? '--:--').toString();
    final workingHours =
        (record['working_hours'] ?? record['total_hours'] ?? '').toString();
    final remarks = (record['remarks'] ?? record['remark'] ?? '').toString();

    Color statusColor;
    switch (status) {
      case 'P':
        statusColor = AppTheme.successGreen;
        break;
      case 'A':
        statusColor = AppTheme.errorRed;
        break;
      case 'H':
        statusColor = AppTheme.warningOrange;
        break;
      case 'L':
        statusColor = AppTheme.primaryPurple;
        break;
      default:
        statusColor = Colors.white.withOpacity(0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Status Bar
              Container(width: 6, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (day.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  day.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRecordInfoChip(
                              Icons.login_rounded,
                              'IN',
                              checkIn,
                              AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRecordInfoChip(
                              Icons.logout_rounded,
                              'OUT',
                              checkOut,
                              AppTheme.primaryPurple,
                            ),
                          ),
                          if (workingHours.isNotEmpty &&
                              workingHours != 'null') ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRecordInfoChip(
                                Icons.timer_outlined,
                                'WORK',
                                workingHours,
                                Colors.blueAccent,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (remarks.isNotEmpty && remarks != 'null') ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            remarks,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'P':
        return 'Present';
      case 'A':
        return 'Absent';
      case 'H':
        return 'Halfday';
      case 'L':
        return 'Late';
      default:
        return 'Unknown';
    }
  }

  Widget _buildRecordInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color.withOpacity(0.8), size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _calculateAverageCheckTimes() {
    try {
      final records =
          (statisticsData?['attendance_records'] ?? statisticsData?['records'])
              as List<dynamic>?;
      if (records == null || records.isEmpty) return {};

      int totalCheckInMinutes = 0;
      int totalCheckOutMinutes = 0;
      int checkInCount = 0;
      int checkOutCount = 0;

      for (final record in records) {
        final checkIn = (record['check_in_time'] ?? record['in_time'] ?? '')
            .toString();
        final checkOut = (record['check_out_time'] ?? record['out_time'] ?? '')
            .toString();

        if (checkIn.isNotEmpty && checkIn != 'null') {
          final mins = _timeToMinutes(checkIn);
          if (mins > 0) {
            totalCheckInMinutes += mins;
            checkInCount++;
          }
        }

        if (checkOut.isNotEmpty && checkOut != 'null') {
          final mins = _timeToMinutes(checkOut);
          if (mins > 0) {
            totalCheckOutMinutes += mins;
            checkOutCount++;
          }
        }
      }

      String avgCheckIn = '--:--';
      String avgCheckOut = '--:--';

      if (checkInCount > 0) {
        final avgMins = totalCheckInMinutes ~/ checkInCount;
        avgCheckIn = _minutesToTime(avgMins);
      }

      if (checkOutCount > 0) {
        final avgMins = totalCheckOutMinutes ~/ checkOutCount;
        avgCheckOut = _minutesToTime(avgMins);
      }

      return {'checkIn': avgCheckIn, 'checkOut': avgCheckOut};
    } catch (e) {
      return {};
    }
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (_) {}
    return 0;
  }

  String _minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  double _barHeight(String time) {
    if (time.isEmpty || time == '--:--' || time == 'null') return 0.5;
    final mins = _timeToMinutes(time);
    if (mins == 0) return 0.5;
    // Normalized for a 140px container height when factor is 25
    return (mins / 300).clamp(0.5, 5.2);
  }

  String _shortDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildWeeklyBarChart() {
    final records =
        (statisticsData!['attendance_records'] ?? statisticsData!['records'])
            as List<dynamic>?;
    if (records == null || records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Center(
          child: Text(
            'No chart data available',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final chartRecords = records.take(7).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME LOGS (LAST 7 DAYS)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  _buildChartLegendItem('CI', const Color(0xFF5B9BD5)),
                  const SizedBox(width: 8),
                  _buildChartLegendItem('CO', const Color(0xFFE8A0A0)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartRecords.map((record) {
                final checkIn =
                    (record['check_in_time'] ?? record['in_time'] ?? '')
                        .toString();
                final checkOut =
                    (record['check_out_time'] ?? record['out_time'] ?? '')
                        .toString();
                final date = (record['date'] ?? '').toString();
                final ciH = _barHeight(checkIn);
                final coH = _barHeight(checkOut);
                final shortDateLabel = _shortDate(date);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 14,
                              height: ciH * 25,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF5B9BD5),
                                    const Color(0xFF5B9BD5).withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 14,
                              height: coH * 25,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFFE8A0A0),
                                    const Color(0xFFE8A0A0).withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shortDateLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 9,
            fontWeight: FontWeight.w900,
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

    final counts = _computeTeacherStatusCounts();
    final late = counts.late;
    final halfday = counts.halfday;

    final hasExtra = late > 0 || halfday > 0;
    final presentForChart = hasExtra ? counts.present : present;
    final absentForChart = hasExtra ? counts.absent : absent;
    final totalForCenter = hasExtra
        ? (counts.present + counts.absent + counts.late + counts.halfday)
        : total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: AppTheme.primaryPurple.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'SUMMARY BREAKDOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Days: $totalForCenter',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatusDistCard(
                  'Present',
                  presentForChart,
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusDistCard(
                  'Absent',
                  absentForChart,
                  AppTheme.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusDistCard(
                  'Late',
                  late,
                  AppTheme.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusDistCard(
                  'Halfday',
                  halfday,
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
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
            Text(
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
            Text(
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
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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

  Widget _buildStudentStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: color.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
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
    // Total days = all marked days (present + absent + late + halfday)
    final totalDays = present + absent + late + halfday;

    // Effective present counts: Present + (Late counts as 0.5 if enabled) + (HalfDay as 0.5)
    // Note: Late should NOT count as full present
    final effectivePresent = present + (halfday * 0.5);

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
