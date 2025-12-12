import 'package:flutter/material.dart';
import '../services/student_attendance_service.dart';
import '../services/teacher_class_service.dart';
import 'package:intl/intl.dart';

class MarkStudentAttendanceScreen extends StatefulWidget {
  final TeacherClass? teacherClass;
  final int? classId;
  final int? sectionId;
  final String? className;

  const MarkStudentAttendanceScreen({
    super.key,
    this.teacherClass,
    this.classId,
    this.sectionId,
    this.className,
  });

  @override
  State<MarkStudentAttendanceScreen> createState() =>
      _MarkStudentAttendanceScreenState();
}

class _MarkStudentAttendanceScreenState
    extends State<MarkStudentAttendanceScreen> {
  List<StudentAttendanceData> _students = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  String _selectedDateStr = '';
  final Map<int, String> _attendanceStatus = {}; // enroll_id -> status
  final Map<int, String> _attendanceRemarks = {}; // enroll_id -> remark

  @override
  void initState() {
    super.initState();
    _selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final classId =
          widget.teacherClass?.classId ?? widget.classId ?? 0;
      final sectionId =
          widget.teacherClass?.sectionId ?? widget.sectionId ?? 0;

      if (classId == 0 || sectionId == 0) {
        throw Exception('Class ID and Section ID are required');
      }

      // Get student attendance for the selected date
      final response = await StudentAttendanceService.getStudentAttendance(
        classId: classId,
        sectionId: sectionId,
        date: _selectedDateStr,
      );

      if (response['status'] == 'success') {
        final studentsData = response['data']['students'] as List<dynamic>;
        final students = studentsData
            .map((item) => StudentAttendanceData.fromJson(item))
            .toList();

        // Initialize attendance status map
        for (var student in students) {
          if (student.attendanceStatus.isNotEmpty) {
            _attendanceStatus[student.enrollId] = student.attendanceStatus;
            _attendanceRemarks[student.enrollId] = student.attendanceRemark;
          }
        }

        setState(() {
          _students = students;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load students';
          _isLoading = false;
        });
      }
    } catch (e) {
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
      _loadStudents();
    }
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
      final classId =
          widget.teacherClass?.classId ?? widget.classId ?? 0;
      final sectionId =
          widget.teacherClass?.sectionId ?? widget.sectionId ?? 0;

      // Prepare attendance entries
      final attendanceEntries = _students
          .where((student) => _attendanceStatus.containsKey(student.enrollId))
          .map((student) => StudentAttendanceEntry(
                enrollId: student.enrollId,
                status: _attendanceStatus[student.enrollId]!,
                remark: _attendanceRemarks[student.enrollId],
              ))
          .toList();

      final response =
          await StudentAttendanceService.markStudentAttendanceBulk(
        classId: classId,
        sectionId: sectionId,
        attendanceEntries: attendanceEntries,
        date: _selectedDateStr,
      );

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );

          // Reload students to show updated status
          _loadStudents();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
        return Colors.green;
      case 'A':
        return Colors.red;
      case 'L':
        return Colors.orange;
      case 'H':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.teacherClass?.displayName ??
              widget.className ??
              'Mark Attendance',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    '${_attendanceStatus.length} marked',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green.withOpacity(0.2),
                ),
              ],
            ),
          ),

          // Students list
          Expanded(
            child: _buildBody(),
          ),

          // Save button
          if (_students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAttendance,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
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

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No students found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final currentStatus =
              _attendanceStatus[student.enrollId] ?? student.attendanceStatus;
          final currentRemark =
              _attendanceRemarks[student.enrollId] ?? student.attendanceRemark;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: currentStatus.isNotEmpty
                    ? _getStatusColor(currentStatus)
                    : Colors.grey,
                child: Text(
                  currentStatus.isNotEmpty
                      ? _getStatusIcon(currentStatus)
                      : student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (student.roll.isNotEmpty) Text('Roll: ${student.roll}'),
                  if (currentStatus.isNotEmpty)
                    Chip(
                      label: Text(_getStatusLabel(currentStatus)),
                      backgroundColor:
                          _getStatusColor(currentStatus).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _getStatusColor(currentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mark Attendance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildStatusButton(
                              'P', 'Present', Colors.green, student.enrollId),
                          _buildStatusButton(
                              'A', 'Absent', Colors.red, student.enrollId),
                          _buildStatusButton(
                              'L', 'Late', Colors.orange, student.enrollId),
                          _buildStatusButton('H', 'Half Day', Colors.blue,
                              student.enrollId),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: currentRemark),
                        decoration: InputDecoration(
                          labelText: 'Remark (Optional)',
                          hintText: 'Enter remark...',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                        ),
                        maxLines: 2,
                        onChanged: (value) =>
                            _setAttendanceRemark(student.enrollId, value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusButton(
      String status, String label, Color color, int enrollId) {
    final isSelected = _attendanceStatus[enrollId] == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _setAttendanceStatus(enrollId, status);
        }
      },
      selectedColor: color,
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: FontWeight.bold,
      ),
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
        return 'Half Day';
      default:
        return 'Not Marked';
    }
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

