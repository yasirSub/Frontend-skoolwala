import 'package:flutter/material.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/teacher_class_service.dart';
import '../../students/services/student_service.dart';
import '../../students/models/class_model.dart';
import 'class_sections_screen.dart';

class MyClassesScreen extends StatefulWidget {
  final bool isSelectorMode;

  const MyClassesScreen({super.key, this.isSelectorMode = false});

  @override
  State<MyClassesScreen> createState() => _MyClassesScreenState();
}

class _MyClassesScreenState extends State<MyClassesScreen> {
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to get classes from getMyClasses first
      try {
        final response = await TeacherClassService.getMyClasses();
        if (response.isSuccess && response.classes.isNotEmpty) {
          // Group by classId to get unique classes
          final Map<int, Map<String, dynamic>> uniqueClassesMap = {};
          for (var teacherClass in response.classes) {
            if (!uniqueClassesMap.containsKey(teacherClass.classId)) {
              uniqueClassesMap[teacherClass.classId] = {
                'classId': teacherClass.classId,
                'className': teacherClass.className,
                'sectionCount': 0,
                'totalStudents': 0,
              };
            }
            uniqueClassesMap[teacherClass.classId]!['sectionCount'] =
                (uniqueClassesMap[teacherClass.classId]!['sectionCount']
                    as int) +
                1;
            uniqueClassesMap[teacherClass.classId]!['totalStudents'] =
                (uniqueClassesMap[teacherClass.classId]!['totalStudents']
                    as int) +
                teacherClass.studentCount;
          }
          setState(() {
            _classes = uniqueClassesMap.values.map((data) {
              return ClassModel(
                classId: data['classId'].toString(),
                className: data['className'] as String,
              );
            }).toList();
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        // If getMyClasses fails, fall back to getClassList
        print('getMyClasses failed, trying getClassList: $e');
      }

      // Fallback: Use getClassList to get all classes
      final classes = await StudentService.getClassList();
      setState(() {
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load classes: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToClass(ClassModel classModel) {
    if (widget.isSelectorMode) {
      // Return the selected class when in selector mode
      Navigator.pop(context, classModel);
    } else {
      // Navigate to sections screen to select a section
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassSectionsScreen(
            classId: int.parse(classModel.classId ?? '0'),
            className: classModel.className ?? 'Unknown Class',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectorMode ? 'Select Class' : 'My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClasses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AppLoadingIndicator());
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
            ElevatedButton(onPressed: _loadClasses, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.class_, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No classes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No classes are available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _classes.length,
        itemBuilder: (context, index) {
          final classModel = _classes[index];
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
                child: const Icon(Icons.class_, color: Colors.white),
              ),
              title: Text(
                classModel.className ?? 'Unknown Class',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: classModel.classCode != null
                  ? Text(
                      'Code: ${classModel.classCode}',
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
              trailing: Icon(
                widget.isSelectorMode
                    ? Icons.check_circle_outline
                    : Icons.chevron_right,
              ),
              onTap: () => _navigateToClass(classModel),
            ),
          );
        },
      ),
    );
  }
}
