import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/teacher_self_attendance_stats_service.dart';
import '../../../shared/services/session_manager.dart';

/// Teacher Self Attendance Screen
/// Shows attendance records with filters (month/date range/year) and statistics
class TeacherSelfAttendanceScreen extends StatefulWidget {
  const TeacherSelfAttendanceScreen({super.key});

  @override
  State<TeacherSelfAttendanceScreen> createState() =>
      _TeacherSelfAttendanceScreenState();
}

class _TeacherSelfAttendanceScreenState
    extends State<TeacherSelfAttendanceScreen> {
  String _filterType = 'month'; // 'month', 'daterange', 'year'
  String _filterValue = '';
  DateTime? _selectedMonth;
  DateTimeRange? _selectedDateRange;
  int? _selectedYear;

  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  List<dynamic> _attendanceRecords = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _filterValue = DateFormat('yyyy-MM').format(DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStatistics(), _loadAttendanceRecords()]);
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await TeacherSelfAttendanceStatsService.getSelfAttendanceStats(
            filterType: _filterType,
            filterValue: _filterValue,
          );

      if (response['status'] == 'success') {
        setState(() {
          _stats = response['data'];
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load statistics';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load statistics: $e';
      });
    }
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? startDate;
      String? endDate;
      String? month;
      String? year;

      switch (_filterType) {
        case 'month':
          if (_selectedMonth != null) {
            month = DateFormat('yyyy-MM').format(_selectedMonth!);
            _filterValue = month;
          }
          break;
        case 'daterange':
          if (_selectedDateRange != null) {
            startDate = DateFormat(
              'yyyy-MM-dd',
            ).format(_selectedDateRange!.start);
            endDate = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
            _filterValue = '$startDate to $endDate';
          }
          break;
        case 'year':
          if (_selectedYear != null) {
            year = _selectedYear.toString();
            _filterValue = year;
          }
          break;
      }

      final response =
          await TeacherSelfAttendanceStatsService.getAttendanceRecords(
            startDate: startDate,
            endDate: endDate,
            month: month,
            year: year,
          );

      if (response['status'] == 'success') {
        setState(() {
          _attendanceRecords = response['data']['records'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load records';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load records: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final initialDate = _selectedMonth ?? now;

    // Show year picker first
    final year = await showDialog<int>(
      context: context,
      builder: (context) {
        final years = List.generate(10, (index) => now.year - index);
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: years.length,
              itemBuilder: (context, index) {
                final y = years[index];
                return ListTile(
                  title: Text(y.toString()),
                  selected: initialDate.year == y,
                  onTap: () => Navigator.pop(context, y),
                );
              },
            ),
          ),
        );
      },
    );

    if (year == null) return;

    // Show month picker
    final month = await showDialog<int>(
      context: context,
      builder: (context) {
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
        return AlertDialog(
          title: Text('Select Month - $year'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(months[index]),
                  selected: initialDate.month == index + 1,
                  onTap: () => Navigator.pop(context, index + 1),
                );
              },
            ),
          ),
        );
      },
    );

    if (month != null) {
      final selected = DateTime(year, month, 1);
      setState(() {
        _selectedMonth = selected;
        _filterValue = DateFormat('yyyy-MM').format(selected);
      });
      _loadData();
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      helpText: 'Select Date Range',
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _filterValue =
            '${DateFormat('yyyy-MM-dd').format(picked.start)} to ${DateFormat('yyyy-MM-dd').format(picked.end)}';
      });
      _loadData();
    }
  }

  Future<void> _selectYear() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - index);

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              return ListTile(
                title: Text(year.toString()),
                selected: _selectedYear == year,
                onTap: () => Navigator.pop(context, year),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedYear = selected;
        _filterValue = selected.toString();
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = SessionManager.instance.currentTeacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Information Card
              if (teacher != null) _buildTeacherInfoCard(teacher),
              const SizedBox(height: 16),

              // Filter Section
              _buildFilterSection(),
              const SizedBox(height: 16),

              // Statistics Cards
              if (_stats != null) _buildStatisticsCards(),
              const SizedBox(height: 16),

              // Attendance Records
              _buildAttendanceRecordsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherInfoCard(teacher) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Your Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildInfoItem('Name', teacher.name ?? 'N/A'),
                _buildInfoItem('Staff ID', teacher.staffId ?? 'N/A'),
                if (teacher.designation != null)
                  _buildInfoItem('Designation', teacher.designation!),
                if (teacher.department != null)
                  _buildInfoItem('Department', teacher.department!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_list),
                SizedBox(width: 8),
                Text(
                  'Filter Attendance Records',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filter Type Dropdown
            DropdownButtonFormField<String>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'Filter Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'month', child: Text('By Month')),
                DropdownMenuItem(
                  value: 'daterange',
                  child: Text('By Date Range'),
                ),
                DropdownMenuItem(value: 'year', child: Text('By Year')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filterType = value;
                  });
                  _loadData();
                }
              },
            ),
            const SizedBox(height: 16),
            // Filter Value Input
            if (_filterType == 'month')
              InkWell(
                onTap: _selectMonth,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Month',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedMonth != null
                        ? DateFormat('MMMM yyyy').format(_selectedMonth!)
                        : 'Select Month',
                  ),
                ),
              )
            else if (_filterType == 'daterange')
              InkWell(
                onTap: _selectDateRange,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Date Range',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.date_range),
                  ),
                  child: Text(
                    _selectedDateRange != null
                        ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                        : 'Select Date Range',
                  ),
                ),
              )
            else if (_filterType == 'year')
              InkWell(
                onTap: _selectYear,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select Year',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedYear != null
                        ? _selectedYear.toString()
                        : 'Select Year',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_stats == null) return const SizedBox();

    final totalDays = _stats!['total_days'] ?? 0;
    final presentDays = _stats!['present_days'] ?? 0;
    final absentDays = _stats!['absent_days'] ?? 0;
    final halfDays = _stats!['half_days'] ?? 0;
    final lateDays = _stats!['late_days'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Total Days', totalDays.toString(), Colors.blue),
            _buildStatCard('Present', presentDays.toString(), Colors.green),
            _buildStatCard('Absent', absentDays.toString(), Colors.red),
            _buildStatCard('Half Day', halfDays.toString(), Colors.orange),
            _buildStatCard('Late', lateDays.toString(), Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              title,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceRecordsSection() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    if (_attendanceRecords.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No attendance records found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance Records',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = _attendanceRecords[index];
            return _buildAttendanceRecordCard(record);
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceRecordCard(Map<String, dynamic> record) {
    final date = record['date']?.toString() ?? '';
    final status = record['status']?.toString() ?? '';
    final inTime = record['in_time']?.toString();
    final outTime = record['out_time']?.toString();
    final remark = record['remark']?.toString();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'P':
        statusColor = Colors.green;
        statusText = 'Present';
        statusIcon = Icons.check_circle;
        break;
      case 'A':
        statusColor = Colors.red;
        statusText = 'Absent';
        statusIcon = Icons.cancel;
        break;
      case 'H':
        statusColor = Colors.orange;
        statusText = 'Half Day';
        statusIcon = Icons.access_time;
        break;
      case 'L':
        statusColor = Colors.amber;
        statusText = 'Late';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          DateFormat(
            'EEEE, MMMM dd, yyyy',
          ).format(DateTime.tryParse(date) ?? DateTime.now()),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (inTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.login, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('In: $inTime', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
            if (outTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.logout, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Out: $outTime', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
            if (remark != null && remark.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Remark: $remark',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
