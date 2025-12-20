import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/student_attendance_service.dart';
import '../services/teacher_class_service.dart';
import '../../attendance/services/attendance_service.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';

class MarkStudentAttendanceScreen extends StatefulWidget {
  final TeacherClass? teacherClass;
  final int? classId;
  final int? sectionId;
  final String? className;
  final int? subjectId; // For subject-wise attendance
  final String? subjectName; // For displaying subject name

  const MarkStudentAttendanceScreen({
    super.key,
    this.teacherClass,
    this.classId,
    this.sectionId,
    this.className,
    this.subjectId,
    this.subjectName,
  });

  @override
  State<MarkStudentAttendanceScreen> createState() =>
      _MarkStudentAttendanceScreenState();
}

class _MarkStudentAttendanceScreenState
    extends State<MarkStudentAttendanceScreen> {
  List<StudentAttendanceData> _students = [];
  List<StudentAttendanceData> _filteredStudents = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String _selectedDateStr = '';
  final Map<int, String> _attendanceStatus = {}; // enroll_id -> status
  final Map<int, String> _attendanceRemarks = {}; // enroll_id -> remark
  late TextEditingController _searchController;

  // Attendance type variables
  int _attendanceType = 0; // 0 = Day-Wise, 1 = Subject-Wise
  String _attendanceTypeDisplay = 'Day-Wise Attendance';
  String _attendanceTypeDescription = '';
  bool _isSubjectWise = false;
  bool _isDayWise = true;

  bool _attendanceTypeLoading = true;

  // Select all students
  bool _selectAllStudents = false;
  Set<int> _selectedStudentIds = {};

  // Subject selection for subject-wise attendance
  int? _selectedSubjectId;
  List<Map<String, dynamic>> _availableSubjects = [];
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_filterStudents);
    _selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _selectedSubjectId = widget.subjectId; // Use passed subjectId if available
    _loadAttendanceType();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where(
              (student) =>
                  student.name.toLowerCase().contains(query) ||
                  student.roll.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  Future<void> _loadAttendanceType() async {
    try {
      print('🔄 [DEBUG] Loading attendance type from API...');

      final response = await AttendanceService.getAttendanceType();

      print('📡 [DEBUG] API Response: $response');

      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'];

        print('✅ [DEBUG] Attendance Type Data:');
        print('   - attendance_type: ${data['attendance_type']}');
        print('   - type_name: ${data['type_name']}');
        print('   - type_display: ${data['type_display']}');
        print('   - description: ${data['description']}');
        print('   - is_day_wise: ${data['is_day_wise']}');
        print('   - is_subject_wise: ${data['is_subject_wise']}');

        // Convert to proper types
        final newAttendanceType =
            int.tryParse(data['attendance_type']?.toString() ?? '0') ?? 0;
        final newIsSubjectWise =
            data['is_subject_wise'] == true ||
            data['is_subject_wise'] == 'true' ||
            data['is_subject_wise'] == 1 ||
            data['is_subject_wise'] == '1';
        final newIsDayWise =
            data['is_day_wise'] == true ||
            data['is_day_wise'] == 'true' ||
            data['is_day_wise'] == 1 ||
            data['is_day_wise'] == '1';

        print(
          '⚙️ [DEBUG] Before setState - _isSubjectWise: $_isSubjectWise, newIsSubjectWise: $newIsSubjectWise',
        );

        setState(() {
          _attendanceType = newAttendanceType;
          _attendanceTypeDisplay =
              data['type_display']?.toString() ?? 'Day-Wise Attendance';
          _attendanceTypeDescription = data['description']?.toString() ?? '';
          _isDayWise = newIsDayWise;
          _isSubjectWise = newIsSubjectWise;
          _attendanceTypeLoading = false;
        });

        // Load subjects if this is subject-wise attendance
        if (newIsSubjectWise) {
          _loadSubjects();
        } else {
          // If day-wise, immediately load students
          _loadStudents();
        }

        // Force rebuild to ensure UI updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print(
            '✅ [DEBUG] UI Updated - isSubjectWise: $_isSubjectWise, isDayWise: $_isDayWise',
          );
        });
      } else {
        print('❌ [DEBUG] API Error: ${response['message']}');
        setState(() {
          _attendanceTypeLoading = false;
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Exception loading attendance type: $e');
      setState(() {
        _attendanceTypeLoading = false;
      });
    }
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final classId = widget.teacherClass?.classId ?? widget.classId ?? 0;
      final sectionId = widget.teacherClass?.sectionId ?? widget.sectionId ?? 0;

      if (classId == 0 || sectionId == 0) {
        throw Exception('Class ID and Section ID are required');
      }

      print(
        '🔄 [DEBUG] Loading subjects for Class: $classId, Section: $sectionId',
      );

      final response = await TeacherClassService.getSubjectsForClassSection(
        classId: classId,
        sectionId: sectionId,
      );

      if (response['status'] == 'success') {
        final subjectsData =
            response['data']['subjects'] as List<dynamic>? ?? [];
        final subjects = subjectsData
            .map(
              (s) => {
                'id': int.parse(s['subject_id'].toString()),
                'name': s['subject_name'].toString(),
              },
            )
            .toList();

        print('✅ [DEBUG] Loaded ${subjects.length} subjects');
        for (var subject in subjects) {
          print('   - ${subject['name']} (ID: ${subject['id']})');
        }

        setState(() {
          _availableSubjects = subjects;
          _isLoadingSubjects = false;
        });

        // If no subject is selected yet, use the first one
        if (_selectedSubjectId == null && subjects.isNotEmpty) {
          setState(() {
            _selectedSubjectId = subjects.first['id'] as int;
          });
        }

        // Load students after subjects are loaded
        _loadStudents();
      } else {
        print('❌ [DEBUG] Failed to load subjects: ${response['message']}');
        setState(() {
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Error loading subjects: $e');
      setState(() {
        _isLoadingSubjects = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Clear previous class/subject attendance marks
      _attendanceStatus.clear();
      _attendanceRemarks.clear();
      _selectedStudentIds.clear();
      _selectAllStudents = false;
    });

    try {
      final classId = widget.teacherClass?.classId ?? widget.classId ?? 0;
      final sectionId = widget.teacherClass?.sectionId ?? widget.sectionId ?? 0;
      final subjectId = _selectedSubjectId;

      if (classId == 0 || sectionId == 0) {
        throw Exception('Class ID and Section ID are required');
      }

      print('═══════════════════════════════════════════════════════════');
      print('🔄 [DEBUG] Loading students for Attendance');
      print('   Class ID: $classId');
      print('   Section ID: $sectionId');
      print(
        '   Subject ID: $subjectId (${subjectId == null ? "NULL - DAY WISE" : "SET - SUBJECT WISE"})',
      );
      print('   Date: $_selectedDateStr');
      print('   Is Subject Wise: $_isSubjectWise');
      print('═══════════════════════════════════════════════════════════');

      // Get student attendance for the selected date (with subject if subject-wise)
      final response = await StudentAttendanceService.getStudentAttendance(
        classId: classId,
        sectionId: sectionId,
        date: _selectedDateStr,
        subjectId: subjectId,
      );

      if (response['status'] == 'success') {
        final studentsData = response['data']['students'] as List<dynamic>;
        final students = studentsData
            .map((item) => StudentAttendanceData.fromJson(item))
            .toList();

        print(
          '✅ [DEBUG] Loaded ${students.length} students for this class/subject',
        );

        // Show API response data for debugging
        if (response['data'] != null) {
          print('📡 [DEBUG] API Response Data:');
          print('   - returned_subject_id: ${response['data']['subject_id']}');
          print('   - returned_class_id: ${response['data']['class_id']}');
          print('   - returned_section_id: ${response['data']['section_id']}');
        }

        // Initialize attendance status map ONLY from database (not from previous class)
        int markedCount = 0;
        for (var student in students) {
          if (student.attendanceStatus.isNotEmpty) {
            _attendanceStatus[student.enrollId] = student.attendanceStatus;
            _attendanceRemarks[student.enrollId] = student.attendanceRemark;
            markedCount++;
            print(
              '   ✓ ${student.name} (Roll: ${student.roll}): ${student.attendanceStatus}',
            );
          }
        }
        print(
          '📊 [DEBUG] Total marked students from DB: $markedCount/${students.length}',
        );
        print('═══════════════════════════════════════════════════════════');

        setState(() {
          _students = students;
          _filteredStudents = students;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load students';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Error loading students: $e');
      setState(() {
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: AppTheme.dashboardPrimary.withOpacity(0.95),
              onSurface: Colors.white,
              secondary: AppTheme.accentCyan,
            ),
            dialogBackgroundColor: AppTheme.dashboardPrimary,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppTheme.primaryPurple,
              headerForegroundColor: Colors.white,
              backgroundColor: AppTheme.dashboardPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedDateStr = DateFormat('yyyy-MM-dd').format(picked);
        _attendanceStatus.clear();
        _attendanceRemarks.clear();
      });
      _loadStudents();
    }
  }

  void _markAllAttendance(String status) {
    setState(() {
      for (var student in _filteredStudents) {
        _attendanceStatus[student.enrollId] = status;
        if (status == 'P') {
          _attendanceRemarks.remove(student.enrollId);
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked ${_filteredStudents.length} student(s) as ${_getStatusLabel(status)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAllStudents = !_selectAllStudents;
      if (_selectAllStudents) {
        // Select all currently visible (filtered) students
        for (var student in _filteredStudents) {
          _selectedStudentIds.add(student.enrollId);
        }
        print('✅ [DEBUG] Selected all ${_filteredStudents.length} students');
      } else {
        // Deselect all (even those not filtered, for safety)
        _selectedStudentIds.clear();
        print('❌ [DEBUG] Deselected all students');
      }
    });
  }

  void _toggleStudentSelection(int enrollId) {
    setState(() {
      if (_selectedStudentIds.contains(enrollId)) {
        _selectedStudentIds.remove(enrollId);
      } else {
        _selectedStudentIds.add(enrollId);
      }
      // Update select all checkbox state
      _selectAllStudents =
          _selectedStudentIds.length == _filteredStudents.length;
      print(
        '👤 [DEBUG] Selected students: ${_selectedStudentIds.length}/${_filteredStudents.length}',
      );
    });
  }

  void _markSelectedAttendance(String status) {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select students first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      for (var enrollId in _selectedStudentIds) {
        _attendanceStatus[enrollId] = status;
        if (status == 'P') {
          _attendanceRemarks.remove(enrollId);
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked ${_selectedStudentIds.length} student(s) as ${_getStatusLabel(status)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setAttendanceStatus(int enrollId, String status) {
    setState(() {
      _attendanceStatus[enrollId] = status;
      if (status == 'P') {
        // Clear remark if marked present
        _attendanceRemarks.remove(enrollId);
      }
    });
  }

  void _setAttendanceRemark(int enrollId, String remark) {
    setState(() {
      if (remark.isEmpty) {
        _attendanceRemarks.remove(enrollId);
      } else {
        _attendanceRemarks[enrollId] = remark;
      }
    });
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students to mark attendance for')),
      );
      return;
    }

    // Check if at least one student has attendance marked
    final markedCount = _attendanceStatus.length;
    if (markedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark attendance for at least one student'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final classId = widget.teacherClass?.classId ?? widget.classId ?? 0;
      final sectionId = widget.teacherClass?.sectionId ?? widget.sectionId ?? 0;
      final subjectId = _selectedSubjectId;

      print(
        '💾 [DEBUG] Saving attendance for Class: $classId, Section: $sectionId, Subject: $subjectId, Date: $_selectedDateStr',
      );
      print('📊 [DEBUG] Marked students: $markedCount');

      // Prepare attendance entries
      final attendanceEntries = _students
          .where((student) => _attendanceStatus.containsKey(student.enrollId))
          .map(
            (student) => StudentAttendanceEntry(
              enrollId: student.enrollId,
              status: _attendanceStatus[student.enrollId]!,
              remark: _attendanceRemarks[student.enrollId],
            ),
          )
          .toList();

      final response = await StudentAttendanceService.markStudentAttendanceBulk(
        classId: classId,
        sectionId: sectionId,
        attendanceEntries: attendanceEntries,
        date: _selectedDateStr,
        subjectId: subjectId,
      );

      if (response.isSuccess) {
        print('✅ [DEBUG] Attendance saved successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Add a small delay then reload to ensure database update
          await Future.delayed(const Duration(milliseconds: 500));
          print('🔄 [DEBUG] Reloading students after save...');
          await _loadStudents();

          setState(() {
            _isSaving = false;
          });
        }
      } else {
        print('❌ [DEBUG] Save failed: ${response.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Error saving attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _printAll() async {
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students to print'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    final pageFormat = PdfPageFormat.a4;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Class: ${widget.teacherClass?.displayName ?? widget.className ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.Text(
                'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Roll', 'Student Name', 'Status', 'Remark'],
                data: [
                  for (var student in _students)
                    [
                      student.roll,
                      student.name,
                      _getStatusLabel(
                        _attendanceStatus[student.enrollId] ??
                            student.attendanceStatus,
                      ),
                      _attendanceRemarks[student.enrollId] ??
                          student.attendanceRemark,
                    ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                cellHeight: 30,
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'P':
        return '✓';
      case 'A':
        return '✗';
      case 'L':
        return '◐';
      case 'H':
        return '½';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'P':
        return AppTheme.successGreen;
      case 'A':
        return AppTheme.errorRed;
      case 'L':
        return AppTheme.warningOrange;
      case 'H':
      case 'HD':
        return AppTheme.infoBlue;
      default:
        return AppTheme.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.dashboardPrimary,
            AppTheme.dashboardPrimary.withBlue(100).withRed(40),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.teacherClass?.displayName ??
                    widget.className ??
                    'Attendance',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _selectDate,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM d, y').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  _isSubjectWise ? 'SUB' : 'DAY',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        body:
            _attendanceTypeLoading ||
                (_isSubjectWise &&
                    _isLoadingSubjects &&
                    _availableSubjects.isEmpty)
            ? const Center(
                child: AppLoadingIndicator(text: 'Loading configuration...'),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    // Premium Stats Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (_students.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _students.isEmpty
                                          ? 0
                                          : _attendanceStatus.length /
                                                _students.length,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.1,
                                      ),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${((_attendanceStatus.length / (_students.isEmpty ? 1 : _students.length)) * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHeaderStat(
                                'TOTAL',
                                _students.length.toString(),
                                Colors.white,
                              ),
                              _buildHeaderStat(
                                'PRESENT',
                                _students
                                    .where(
                                      (s) =>
                                          (_attendanceStatus[s.enrollId] ??
                                              s.attendanceStatus) ==
                                          'P',
                                    )
                                    .length
                                    .toString(),
                                AppTheme.successGreen,
                              ),
                              _buildHeaderStat(
                                'ABSENT',
                                _students
                                    .where(
                                      (s) =>
                                          (_attendanceStatus[s.enrollId] ??
                                              s.attendanceStatus) ==
                                          'A',
                                    )
                                    .length
                                    .toString(),
                                AppTheme.errorRed,
                              ),
                              _buildHeaderStat(
                                'MARKED',
                                _attendanceStatus.length.toString(),
                                AppTheme.infoBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search & Selection Row (Modern Dark Glass)
                    TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.12),
                                          Colors.white.withOpacity(0.04),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search students...',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          size: 20,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onChanged: (_) => _filterStudents(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _toggleSelectAll,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _selectAllStudents
                                            ? [
                                                AppTheme.primaryPurple,
                                                AppTheme.dashboardPrimaryLight,
                                              ]
                                            : [
                                                Colors.white.withOpacity(0.12),
                                                Colors.white.withOpacity(0.04),
                                              ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectAllStudents
                                            ? Colors.white24
                                            : Colors.white10,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _selectAllStudents
                                              ? AppTheme.primaryPurple.withOpacity(
                                                  0.3,
                                                )
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _selectAllStudents
                                          ? Icons.done_all_rounded
                                          : Icons.checklist_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                    // Bulk Status Chips (Only visible when selection exists)
                    if (_selectedStudentIds.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'MARK SELECTED:',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white.withOpacity(0.5),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildQuickActionChip(
                                      'P',
                                      'P',
                                      AppTheme.successGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickActionChip(
                                      'A',
                                      'A',
                                      AppTheme.errorRed,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickActionChip(
                                      'L',
                                      'L',
                                      AppTheme.warningOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildQuickActionChip(
                                      'H',
                                      'H',
                                      AppTheme.infoBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Students List
                    Expanded(child: _buildBody()),

                    // Action Bar (Floating Save Button)
                    if (_students.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
                          child: Hero(
                            tag: 'save_attendance_hero',
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryPurple,
                                    AppTheme.primaryPurple
                                        .withBlue(255)
                                        .withRed(100),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSaving ? null : _saveAttendance,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving)
                                        const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      else ...[
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          'FINALIZE ATTENDANCE',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2.5,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingIndicator();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStudents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No students found'
                  : 'No students match your search',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final status =
            _attendanceStatus[student.enrollId] ?? student.attendanceStatus;
        final remark =
            _attendanceRemarks[student.enrollId] ?? student.attendanceRemark;
        final isSelected = _selectedStudentIds.contains(student.enrollId);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutQuint,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: _StudentAttendanceCard(
                key: ValueKey(student.enrollId),
                student: student,
                currentStatus: status,
                currentRemark: remark,
                isSelected: isSelected,
                onStatusChanged: (newStatus) =>
                    _setAttendanceStatus(student.enrollId, newStatus),
                onRemarkChanged: (newRemark) =>
                    _setAttendanceRemark(student.enrollId, newRemark),
                onSelectionChanged: (val) =>
                    _toggleStudentSelection(student.enrollId),
                getStatusColor: _getStatusColor,
                getStatusLabel: _getStatusLabel,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color == Colors.white.withOpacity(0.6)
                ? Colors.white
                : color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return _buildHeaderStat(label, value, color);
  }

  Widget _buildQuickActionChip(String label, String status, Color color) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w900,
        fontSize: 11,
      ),
      side: BorderSide(color: color.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.zero,
      onPressed: () => _markSelectedAttendance(status),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'P':
        return 'Present';
      case 'A':
        return 'Absent';
      case 'L':
        return 'Late';
      case 'H':
      case 'HD':
        return 'Half Day';
      default:
        return 'Not Marked';
    }
  }
}

/// Optimized Student Attendance Card Widget
class _StudentAttendanceCard extends StatefulWidget {
  final StudentAttendanceData student;
  final String currentStatus;
  final String currentRemark;
  final bool isSelected;
  final Function(String) onStatusChanged;
  final Function(String) onRemarkChanged;
  final Function(bool?) onSelectionChanged;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusLabel;

  const _StudentAttendanceCard({
    required Key key,
    required this.student,
    required this.currentStatus,
    required this.currentRemark,
    required this.isSelected,
    required this.onStatusChanged,
    required this.onRemarkChanged,
    required this.onSelectionChanged,
    required this.getStatusColor,
    required this.getStatusLabel,
  }) : super(key: key);

  @override
  State<_StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<_StudentAttendanceCard>
    with SingleTickerProviderStateMixin {
  late TextEditingController _remarkController;
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(text: widget.currentRemark);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_StudentAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRemark != widget.currentRemark) {
      _remarkController.text = widget.currentRemark;
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isSelected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onSelectionChanged(!widget.isSelected),
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isSelected
                      ? [
                          AppTheme.primaryPurple.withOpacity(0.15),
                          AppTheme.primaryPurple.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.02),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isSelected
                      ? AppTheme.primaryPurple.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? AppTheme.primaryPurple.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      // Status Indicator Edge Glow
                      Positioned(
                        left: 0,
                        top: 24,
                        bottom: 24,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 4,
                          decoration: BoxDecoration(
                            color: widget.getStatusColor(widget.currentStatus),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget
                                    .getStatusColor(widget.currentStatus)
                                    .withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Circular Checkbox
                            GestureDetector(
                              onTap: () =>
                                  widget.onSelectionChanged(!widget.isSelected),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: widget.isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: widget.isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: AppTheme.dashboardPrimary,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Student Avatar with Glow
                            Container(
                              height: 48,
                              width: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Student Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ROLL: ${widget.student.roll}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Selection with Gradient Effects
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildPremiumStatusBtn(
                                  'P',
                                  AppTheme.successGreen,
                                  Icons.check_rounded,
                                ),
                                const SizedBox(width: 10),
                                _buildPremiumStatusBtn(
                                  'A',
                                  AppTheme.errorRed,
                                  Icons.close_rounded,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Expand for more
                            InkWell(
                              onTap: _toggleExpanded,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.more_vert_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Expanded Details Section
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.15),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSecondaryStatusAction(
                                        'L',
                                        'LATE',
                                        AppTheme.warningOrange,
                                        Icons.access_time_filled_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSecondaryStatusAction(
                                        'H',
                                        'HALF DAY',
                                        AppTheme.infoBlue,
                                        Icons.brightness_4_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _remarkController,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Add a remark...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 13,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.edit_note_rounded,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                    ),
                                    onSubmitted: (val) {
                                      widget.onRemarkChanged(val);
                                      _toggleExpanded();
                                    },
                                    onChanged: widget.onRemarkChanged,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryStatusAction(
    String status,
    String label,
    Color color,
    IconData icon,
  ) {
    final bool isCurrent = widget.currentStatus == status;
    return InkWell(
      onTap: () => widget.onStatusChanged(status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isCurrent
              ? LinearGradient(
                  colors: [color.withOpacity(0.4), color.withOpacity(0.2)],
                )
              : null,
          color: isCurrent ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? color.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isCurrent ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isCurrent ? Colors.white : Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumStatusBtn(String status, Color color, IconData icon) {
    final isSelected = widget.currentStatus == status;
    return InkWell(
      onTap: () => widget.onStatusChanged(status),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: isSelected ? null : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.3)
                : color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : color.withOpacity(0.9),
        ),
      ),
    );
  }
}

/// Helper class for student attendance data
class StudentAttendanceData {
  final int enrollId;
  final int studentId;
  final String name;
  final String registerNo;
  final String roll;
  final String photo;
  final String gender;
  final String attendanceStatus;
  final String attendanceRemark;

  StudentAttendanceData({
    required this.enrollId,
    required this.studentId,
    required this.name,
    required this.registerNo,
    required this.roll,
    required this.photo,
    required this.gender,
    required this.attendanceStatus,
    required this.attendanceRemark,
  });

  factory StudentAttendanceData.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceData(
      enrollId: int.parse(json['enroll_id']?.toString() ?? '0'),
      studentId: int.parse(json['student_id']?.toString() ?? '0'),
      name: json['name']?.toString() ?? '',
      registerNo: json['register_no']?.toString() ?? '',
      roll: json['roll']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      attendanceStatus: json['attendance_status']?.toString() ?? '',
      attendanceRemark: json['attendance_remark']?.toString() ?? '',
    );
  }
}
