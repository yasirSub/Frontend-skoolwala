import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/student_attendance_service.dart';
import '../services/teacher_class_service.dart';
import '../../attendance/services/attendance_service.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/theme/app_theme.dart';

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
  bool _isSubjectWise = false;
  bool _isDayWise = true;
  bool _attendanceTypeLoading = true;

  // Select all students
  bool _selectAllStudents = false;
  final Set<int> _selectedStudentIds = {};

  // Subject selection for subject-wise attendance
  int? _selectedSubjectId;
  List<Map<String, dynamic>> _availableSubjects = [];
  bool _isLoadingSubjects = false;

  Future<void> _reloadForCurrentState() async {
    // If we don't know the attendance mode yet, fetch it first.
    if (_attendanceTypeLoading) {
      await _loadAttendanceType();
      return;
    }

    if (_isSubjectWise) {
      // If subject-wise but we don't have a subject selected, load subjects
      // instead of calling the attendance API with null subject.
      if (_selectedSubjectId == null || _selectedSubjectId == 0) {
        await _loadSubjects();
        return;
      }
    }

    await _loadStudents();
  }

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
          _isDayWise = newIsDayWise;
          _isSubjectWise = newIsSubjectWise;
          _attendanceTypeLoading = false;
        });

        // Centralize any follow-up loading through the same safe gate.
        // This prevents accidental day-wise calls when subject-wise is enabled.
        await _reloadForCurrentState();

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
        date: _selectedDateStr,
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

        if (subjects.isEmpty && widget.subjectId == null) {
          // In subject-wise mode, subjects are derived from timetable for the selected date.
          // If empty, the teacher likely has no scheduled class for that date.
          print(
            '🚫 [GUARD] Subject-wise mode but 0 timetable subjects for date $_selectedDateStr. Blocking attendance API call.',
          );
          setState(() {
            _selectedSubjectId = null;
            _students = [];
            _filteredStudents = [];
            _isLoading = false;
            _errorMessage =
                'No subject classes are scheduled for the selected date. Please choose another date.';
          });
          return;
        }

        // If current selected subject is not available for this date, switch to first.
        final availableIds = subjects.map((s) => s['id'] as int).toSet();
        if (_selectedSubjectId == null ||
            !availableIds.contains(_selectedSubjectId)) {
          if (subjects.isNotEmpty) {
            setState(() {
              _selectedSubjectId = subjects.first['id'] as int;
            });
          }
        }

        // Load students after subjects are loaded and a subject is selected
        // (if subjectId was passed in, _selectedSubjectId is already set).
        if (_selectedSubjectId != null && _selectedSubjectId != 0) {
          await _loadStudents();
        }
      } else {
        print('❌ [DEBUG] Failed to load subjects: ${response['message']}');
        setState(() {
          _isLoadingSubjects = false;
          _isLoading = false;
          _errorMessage =
              response['message']?.toString() ?? 'Failed to load subjects';
        });
      }
    } catch (e) {
      print('❌ [DEBUG] Error loading subjects: $e');
      setState(() {
        _isLoadingSubjects = false;
        _isLoading = false;
        _errorMessage = 'Failed to load subjects: $e';
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

      // HARD GUARD:
      // If API says subject-wise but there are no subjects (and none were passed in),
      // we must never hit the attendance API with a null subjectId (backend treats that as day-wise).
      if (_isSubjectWise &&
          widget.subjectId == null &&
          _availableSubjects.isEmpty) {
        print(
          '🚫 [GUARD] Prevented day-wise fallback: subject-wise enabled but subject list is empty and no subjectId was passed.',
        );
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No subjects are assigned for this class/section. Please ask admin to assign subjects for this class.';
        });
        return;
      }

      if (_isSubjectWise && (subjectId == null || subjectId == 0)) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Subject-wise attendance is enabled. Please select a subject to continue.';
        });
        return;
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
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedDateStr = DateFormat('yyyy-MM-dd').format(picked);
        _attendanceStatus.clear();
        _attendanceRemarks.clear();
      });

      // If subject-wise and subject isn't fixed by navigation, reload subjects for the new date
      // so the dropdown matches the timetable-based authorization.
      if (_isSubjectWise &&
          !_attendanceTypeLoading &&
          widget.subjectId == null) {
        setState(() {
          _availableSubjects = [];
          _selectedSubjectId = null;
        });
        await _loadSubjects();
        return;
      }

      _reloadForCurrentState();
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
        // Select all filtered students
        _selectedStudentIds.clear();
        for (var student in _filteredStudents) {
          _selectedStudentIds.add(student.enrollId);
        }
        print('✅ [DEBUG] Selected all ${_filteredStudents.length} students');
      } else {
        // Deselect all
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
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSubjectName =
        widget.subjectName ??
        _availableSubjects
            .where((s) => (s['id'] as int?) == _selectedSubjectId)
            .map((s) => s['name'] as String?)
            .cast<String?>()
            .firstWhere(
              (name) => name != null && name.trim().isNotEmpty,
              orElse: () => null,
            );

    final markedCount = _students
        .where(
          (s) =>
              (_attendanceStatus[s.enrollId] ?? s.attendanceStatus).isNotEmpty,
        )
        .length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.darkPurple,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.teacherClass?.displayName ??
                  widget.className ??
                  'Mark Attendance',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              selectedSubjectName != null
                  ? '$selectedSubjectName • ${DateFormat('MMMM d, yyyy').format(_selectedDate)}'
                  : DateFormat('MMMM d, yyyy').format(_selectedDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM').format(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.dashboardPrimaryLight, AppTheme.darkPurple],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _students.isEmpty
                                ? 0
                                : (markedCount / _students.length).clamp(
                                    0.0,
                                    1.0,
                                  ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatPill(
                              'TOTAL',
                              _students.length.toString(),
                              Colors.white70,
                            ),
                          ),
                          Expanded(
                            child: _buildStatPill(
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
                          ),
                          Expanded(
                            child: _buildStatPill(
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
                          ),
                          Expanded(
                            child: _buildStatPill(
                              'MARKED',
                              markedCount.toString(),
                              AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.textDark.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(color: Colors.white60),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white60,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (_) => _filterStudents(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _toggleSelectAll,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        child: Icon(
                          _selectAllStudents
                              ? Icons.checklist_rtl
                              : Icons.playlist_add_check,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_selectedStudentIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionChip(
                          'Present',
                          'P',
                          AppTheme.successGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionChip('Absent', 'A', AppTheme.errorRed),
                        const SizedBox(width: 8),
                        _buildQuickActionChip(
                          'Late',
                          'L',
                          AppTheme.warningOrange,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickActionChip(
                          'Half Day',
                          'H',
                          AppTheme.infoBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
              if (_students.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: SafeArea(
                    top: false,
                    child: InkWell(
                      onTap: _isSaving ? null : _saveAttendance,
                      borderRadius: BorderRadius.circular(30),
                      child: Opacity(
                        opacity: _isSaving ? 0.7 : 1,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: AppTheme.buttonShadow,
                          ),
                          child: Center(
                            child: _isSaving
                                ? const AppLoadingIndicator(
                                    size: 22,
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'FINALIZE ATTENDANCE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
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
      return const Center(child: AppLoadingIndicator(color: Colors.white));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reloadForCurrentState,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.16),
                foregroundColor: Colors.white,
              ),
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
            Icon(Icons.people_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No students found'
                  : 'No students match your search',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final status =
            _attendanceStatus[student.enrollId] ?? student.attendanceStatus;
        final remark =
            _attendanceRemarks[student.enrollId] ?? student.attendanceRemark;
        final isSelected = _selectedStudentIds.contains(student.enrollId);

        return _StudentAttendanceCard(
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
        );
      },
    );
  }

  Widget _buildStatPill(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String label, String status, Color color) {
    return ActionChip(
      label: Text(label),
      avatar: Icon(Icons.check, size: 16, color: color),
      backgroundColor: Colors.white.withOpacity(0.12),
      labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      side: BorderSide(color: Colors.white.withOpacity(0.16)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final statusColor = widget.getStatusColor(widget.currentStatus);
    final statusLabel = widget.getStatusLabel(widget.currentStatus);

    final isMarked = widget.currentStatus.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(widget.isSelected ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(
                  widget.isSelected ? 0.22 : 0.14,
                ),
                width: widget.isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () =>
                            widget.onSelectionChanged(!widget.isSelected),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.22)
                                : Colors.white.withOpacity(0.10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: widget.isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.14),
                        backgroundImage: widget.student.photo.isNotEmpty
                            ? NetworkImage(widget.student.photo)
                            : null,
                        child: widget.student.photo.isEmpty
                            ? Text(
                                widget.student.name.isNotEmpty
                                    ? widget.student.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      // Student info section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student name - prominent
                            Text(
                              widget.student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.14),
                                ),
                              ),
                              child: Text(
                                'ROLL: ${widget.student.roll}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _InlineStatusButton(
                        icon: Icons.check,
                        borderColor: AppTheme.successGreen,
                        isActive: widget.currentStatus == 'P',
                        onTap: () => widget.onStatusChanged('P'),
                      ),
                      const SizedBox(width: 10),
                      _InlineStatusButton(
                        icon: Icons.close,
                        borderColor: AppTheme.errorRed,
                        isActive: widget.currentStatus == 'A',
                        onTap: () => widget.onStatusChanged('A'),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _toggleExpanded,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          child: RotationTransition(
                            turns: Tween(
                              begin: 0.0,
                              end: 0.5,
                            ).animate(_animationController),
                            child: Icon(
                              Icons.more_horiz,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Expanded Content
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.textDark.withOpacity(0.22),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withOpacity(0.10),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Buttons
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildCompactStatusButton(
                                    'P',
                                    'Present',
                                    AppTheme.successGreen,
                                  ),
                                  _buildCompactStatusButton(
                                    'A',
                                    'Absent',
                                    AppTheme.errorRed,
                                  ),
                                  _buildCompactStatusButton(
                                    'L',
                                    'Late',
                                    AppTheme.warningOrange,
                                  ),
                                  _buildCompactStatusButton(
                                    'H',
                                    'Half Day',
                                    AppTheme.infoBlue,
                                  ),
                                ],
                              ),
                              // Remark TextField
                              const SizedBox(height: 12),
                              TextField(
                                controller: _remarkController,
                                decoration: InputDecoration(
                                  labelText: 'Remark (Optional)',
                                  hintText: 'Add a note...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.10),
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                                maxLines: 2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                                onChanged: widget.onRemarkChanged,
                              ),
                              const SizedBox(height: 10),
                              if (isMarked)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.35),
                                        ),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }

  Widget _buildCompactStatusButton(String status, String label, Color color) {
    final isSelected = widget.currentStatus == status;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onStatusChanged(status),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStatusButton extends StatelessWidget {
  final IconData icon;
  final Color borderColor;
  final bool isActive;
  final VoidCallback onTap;

  const _InlineStatusButton({
    required this.icon,
    required this.borderColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive
        ? borderColor.withOpacity(0.35)
        : Colors.white.withOpacity(0.10);
    final iconColor = isActive ? Colors.white : borderColor.withOpacity(0.95);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? borderColor.withOpacity(0.95)
                : borderColor.withOpacity(0.35),
            width: isActive ? 2.0 : 1.2,
          ),
        ),
        child: Icon(icon, color: iconColor),
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
