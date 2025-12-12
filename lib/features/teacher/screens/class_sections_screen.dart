import 'package:flutter/material.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../students/services/student_service.dart';
import '../../students/models/class_model.dart';
import '../../students/screens/students_list_screen.dart';

/// Class Sections Screen
/// Shows sections for a selected class, then navigates to students list
class ClassSectionsScreen extends StatefulWidget {
  final int classId;
  final String className;

  const ClassSectionsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassSectionsScreen> createState() => _ClassSectionsScreenState();
}

class _ClassSectionsScreenState extends State<ClassSectionsScreen> {
  List<SectionModel> _sections = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sections = await StudentService.getSectionList(
        widget.classId.toString(),
      );

      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sections: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToStudents(SectionModel section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentsListScreen(
          classId: widget.classId,
          sectionId: int.parse(section.sectionId ?? '0'),
          className: '${widget.className} - ${section.sectionName}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Sections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSections,
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
              onPressed: _loadSections,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No sections found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no sections in this class.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final section = _sections[index];
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
                child: Text(
                  section.sectionName?.substring(0, 1).toUpperCase() ?? 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                section.sectionName ?? 'Unknown Section',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: section.sectionCode != null
                  ? Text(
                      'Code: ${section.sectionCode}',
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToStudents(section),
            ),
          );
        },
      ),
    );
  }
}
