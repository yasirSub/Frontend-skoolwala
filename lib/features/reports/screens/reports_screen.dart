import 'package:flutter/material.dart';
import '../../teacher/screens/my_classes_screen.dart';
import '../../teacher/services/teacher_class_service.dart';
import '../../teacher/screens/attendance_report_screen.dart';

/// Reports Screen
/// Main screen for accessing different types of reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            icon: Icons.assessment,
            title: 'Student Reports',
            description: 'View detailed reports for students',
            color: Colors.blue,
            onTap: () async {
              final selectedClass = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyClassesScreen(isSelectorMode: true),
                ),
              );
              if (selectedClass != null && context.mounted) {
                // Navigate to student reports
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student Reports - Coming Soon'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            icon: Icons.bar_chart,
            title: 'Attendance Reports',
            description: 'View attendance statistics and reports',
            color: Colors.green,
            onTap: () async {
              final selectedClass = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyClassesScreen(isSelectorMode: true),
                ),
              );
              if (selectedClass != null && context.mounted) {
                final teacherClass = selectedClass as TeacherClass;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AttendanceReportScreen(teacherClass: teacherClass),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildReportCard(
            icon: Icons.trending_up,
            title: 'Academic Reports',
            description: 'View academic performance and grades',
            color: Colors.orange,
            onTap: () async {
              final selectedClass = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyClassesScreen(isSelectorMode: true),
                ),
              );
              if (selectedClass != null && context.mounted) {
                // Navigate to academic reports
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Academic Reports - Coming Soon'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
