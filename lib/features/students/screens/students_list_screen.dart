import 'package:flutter/material.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/student_service.dart';
import '../models/student.dart';
import '../../teacher/screens/my_classes_screen.dart';

/// Students List Screen
/// Displays list of students for a selected class-section
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
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (widget.classId == null || widget.sectionId == null) {
      // If no class/section provided, navigate to My Classes screen
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MyClassesScreen()),
            );
          }
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await StudentService.getStudentList(
        classId: widget.classId!.toString(),
        sectionId: widget.sectionId!.toString(),
      );

      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load students: $e';
        _isLoading = false;
      });
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = student.name?.toLowerCase() ?? '';
          final roll = student.roll?.toLowerCase() ?? '';
          final registerNo = student.registerNo?.toLowerCase() ?? '';
          return name.contains(query) ||
              roll.contains(query) ||
              registerNo.contains(query);
        }).toList();
      }
    });
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
      return const Center(child: AppLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
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
              'There are no students in this class.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, roll, or admission number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),
        // Students count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Total: ${_filteredStudents.length} student${_filteredStudents.length != 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Students list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadStudents,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return _buildStudentCard(student);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student student) {
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
          radius: 28,
          child: Text(
            student.initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          student.name ?? 'Unknown',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (student.roll != null && student.roll!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.badge, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Roll: ${student.roll}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            if (student.roll != null && student.roll!.isNotEmpty)
              const SizedBox(height: 4),
            if (student.registerNo != null && student.registerNo!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.credit_card, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Register: ${student.registerNo}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            if (student.mobileNo != null && student.mobileNo!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(student.mobileNo!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }
}
