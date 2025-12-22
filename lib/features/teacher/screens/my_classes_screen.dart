import 'package:flutter/material.dart';
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/widgets/app_loading_indicator.dart';
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
      // Use new teacher_schedule API to get all classes
      final baseUrl = ApiConfig.getBaseUrl();
      final url = '$baseUrl/teacher_schedule?action=getAllClasses';

      print('📚 Loading all teacher classes from: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: SessionManager.instance.getAuthHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ API Response: ${data['status']}');
        print('📊 Classes found: ${(data['data'] as List).length}');

        if (data['status'] == 'success') {
          final classesList = (data['data'] as List);

          if (classesList.isEmpty) {
            setState(() {
              _errorMessage = 'No classes assigned to you yet';
              _isLoading = false;
            });
            return;
          }

          // Convert API response to ClassModel
          final classes = classesList.map((classData) {
            return ClassModel(
              classId: classData['classId'].toString(),
              className: classData['className'] as String,
            );
          }).toList();

          setState(() {
            _classes = classes;
            _isLoading = false;
          });
          print('✅ Successfully loaded ${classes.length} classes');
          return;
        }
      }

      // If new API fails, show error
      setState(() {
        _errorMessage =
            'Failed to load classes (HTTP ${response.statusCode}). Please check your connection.';
        _isLoading = false;
      });
      print('❌ API Error: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('❌ API Error Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading classes: $e');
      setState(() {
        _errorMessage = 'Error: $e';
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
