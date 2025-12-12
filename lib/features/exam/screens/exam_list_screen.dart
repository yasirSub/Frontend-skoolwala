import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../services/exam_service.dart';
import '../models/exam.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  List<Exam> _exams = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exams = await ExamService.getExamList();
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Session expired')
              ? 'Session error. Please login again.'
              : 'Failed to load exams';
          _isLoading = false;
        });
      }
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam List'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
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
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadExams, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_exams.isEmpty) {
      return const Center(child: Text("No exams found."));
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.builder(
        itemCount: _exams.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2C3E50),
                child: Icon(Icons.assignment, color: Colors.white),
              ),
              title: Text(
                exam.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: exam.remark != null && exam.remark!.isNotEmpty
                  ? Text(exam.remark!)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
