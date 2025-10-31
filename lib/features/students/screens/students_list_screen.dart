import 'package:flutter/material.dart';
import 'package:skoolwala/shared/widgets/custom_app_bar.dart';
import 'package:skoolwala/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:skoolwala/shared/theme/app_theme.dart';
import '../../teacher/services/teacher_class_service.dart';

/// Students List Screen
/// Displays students for a specific class and section
class StudentsListScreen extends StatefulWidget {
  final int? classId;
  final int? sectionId;
  final String? className;

  const StudentsListScreen({
    super.key,
    this.classId,
    this.sectionId,
    this.className,
  });

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  List<TeacherStudent> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await TeacherClassService.getMyStudents(
        classId: widget.classId,
        sectionId: widget.sectionId,
      );

      if (response.isSuccess) {
        setState(() {
          _students = response.students;
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
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.className ?? 'Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudents,
            tooltip: 'Refresh',
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
            const SizedBox(height: 8),
            const Text(
              'There are no students enrolled in this class.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: student.photo.isNotEmpty
                    ? NetworkImage(student.photo)
                    : null,
                child: student.photo.isEmpty
                    ? Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(
                student.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (student.roll != null && student.roll!.isNotEmpty)
                    Text('Roll: ${student.roll}'),
                  Text('Admission No: ${student.admissionNo}'),
                  if (student.displayClass.isNotEmpty)
                    Text(
                      student.displayClass,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to student details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Student details for ${student.name}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
