import 'package:flutter/material.dart';
import '../../teacher/screens/my_classes_screen.dart';
import '../../teacher/screens/mark_student_attendance_screen.dart';
import '../../teacher/screens/attendance_report_screen.dart';
import '../../teacher/screens/homework_list_screen.dart';
import '../../teacher/screens/create_homework_screen.dart';
import '../../students/screens/students_list_screen.dart';
import '../../teacher/services/teacher_class_service.dart';

/// Widget that displays a grid of teacher feature cards
class TeacherFeaturesMenu extends StatelessWidget {
  const TeacherFeaturesMenu({super.key});

  @override
  Widget build(BuildContext context) {
    // Debug: Ensure widget is visible
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _FeatureCard(
                icon: Icons.class_,
                title: 'My Classes',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyClassesScreen()),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.people,
                title: 'My Students',
                color: Colors.green,
                onTap: () async {
                  // Show class selector
                  final selectedClass = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MyClassesScreen(isSelectorMode: true),
                    ),
                  );
                  if (selectedClass != null && context.mounted) {
                    final teacherClass = selectedClass as TeacherClass;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentsListScreen(
                          classId: teacherClass.classId,
                          sectionId: teacherClass.sectionId,
                          className: teacherClass.displayName,
                        ),
                      ),
                    );
                  }
                },
              ),
              _FeatureCard(
                icon: Icons.how_to_reg,
                title: 'Mark Attendance',
                color: Colors.orange,
                onTap: () async {
                  // Show class selector
                  final selectedClass = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MyClassesScreen(isSelectorMode: true),
                    ),
                  );
                  if (selectedClass != null && context.mounted) {
                    final teacherClass = selectedClass as TeacherClass;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarkStudentAttendanceScreen(
                          teacherClass: teacherClass,
                        ),
                      ),
                    );
                  }
                },
              ),
              _FeatureCard(
                icon: Icons.bar_chart,
                title: 'Attendance Reports',
                color: Colors.purple,
                onTap: () async {
                  // Show class selector
                  final selectedClass = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MyClassesScreen(isSelectorMode: true),
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
              _FeatureCard(
                icon: Icons.assignment,
                title: 'My Homeworks',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeworkListScreen(),
                    ),
                  );
                },
              ),
              _FeatureCard(
                icon: Icons.add_task,
                title: 'Create Homework',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateHomeworkScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
