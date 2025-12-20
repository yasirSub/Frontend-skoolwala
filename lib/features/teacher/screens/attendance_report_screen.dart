import 'package:flutter/material.dart';
import '../services/student_attendance_service.dart';
import '../services/teacher_class_service.dart';
import 'package:intl/intl.dart';

class AttendanceReportScreen extends StatefulWidget {
  final TeacherClass? teacherClass;
  final int? classId;
  final int? sectionId;
  final String? className;

  const AttendanceReportScreen({
    super.key,
    this.teacherClass,
    this.classId,
    this.sectionId,
    this.className,
  });

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  StudentAttendanceReportResponse? _report;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final classId = widget.teacherClass?.classId ?? widget.classId ?? 0;
      final sectionId = widget.teacherClass?.sectionId ?? widget.sectionId ?? 0;

      if (classId == 0 || sectionId == 0) {
        throw Exception('Class ID and Section ID are required');
      }

      final response = await StudentAttendanceService.getAttendanceReport(
        classId: classId,
        sectionId: sectionId,
        startDate: _dateFormat.format(_startDate),
        endDate: _dateFormat.format(_endDate),
      );

      if (response.isSuccess) {
        setState(() {
          _report = response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load report: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
      _loadReport();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _loadReport();
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B61FF), Color(0xFF6246EA)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: Text(
          widget.teacherClass?.displayName ??
              widget.className ??
              'Attendance Report',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Date Range'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Start Date'),
                        subtitle: Text(
                          DateFormat('MMMM d, yyyy').format(_startDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectStartDate,
                      ),
                      ListTile(
                        title: const Text('End Date'),
                        subtitle: Text(
                          DateFormat('MMMM d, yyyy').format(_endDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: _selectEndDate,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadReport();
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _buildBody(),
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
            ElevatedButton(onPressed: _loadReport, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_report == null || _report!.students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No attendance data found',
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
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          _buildSummaryCards(_report!.summary, _report!.totalDays),

          const SizedBox(height: 24),

          // Date Range Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Period',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      '${_report!.totalDays} working days',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Students List
          const Text(
            'Student Attendance Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ..._report!.students.map((student) => _buildStudentCard(student)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceSummary summary, int totalDays) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          'Total Students',
          summary.totalStudents.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildSummaryCard(
          'Present Days',
          summary.totalPresent.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildSummaryCard(
          'Absent Days',
          summary.totalAbsent.toString(),
          Icons.cancel,
          Colors.red,
        ),
        _buildSummaryCard(
          'Late Arrivals',
          summary.totalLate.toString(),
          Icons.schedule,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentAttendanceReportItem student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getPercentageColor(
                    student.attendancePercentage,
                  ),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (student.roll != null && student.roll!.isNotEmpty)
                        Text(
                          'Roll: ${student.roll}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${student.attendancePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getPercentageColor(
                          student.attendancePercentage,
                        ),
                      ),
                    ),
                    const Text(
                      'Attendance',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Present',
                  student.presentCount.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  'Absent',
                  student.absentCount.toString(),
                  Colors.red,
                ),
                _buildStatItem(
                  'Late',
                  student.lateCount.toString(),
                  Colors.orange,
                ),
                if (student.halfdayCount > 0)
                  _buildStatItem(
                    'Half Day',
                    student.halfdayCount.toString(),
                    Colors.blue,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
