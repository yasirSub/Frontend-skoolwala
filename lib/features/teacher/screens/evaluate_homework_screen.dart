import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/homework_service.dart';

class EvaluateHomeworkScreen extends StatefulWidget {
  final int homeworkId;

  const EvaluateHomeworkScreen({
    super.key,
    required this.homeworkId,
  });

  @override
  State<EvaluateHomeworkScreen> createState() =>
      _EvaluateHomeworkScreenState();
}

class _EvaluateHomeworkScreenState extends State<EvaluateHomeworkScreen> {
  HomeworkSubmissionsResponse? _data;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, String> _evaluationStatus = {};
  final Map<int, String> _evaluationRemarks = {};
  final Map<int, String> _evaluationRanks = {};

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HomeworkService.getHomeworkSubmissions(
        homeworkId: widget.homeworkId,
      );

      if (response.isSuccess) {
        // Initialize evaluation maps
        for (var submission in response.submissions) {
          if (submission.evaluated) {
            _evaluationStatus[submission.studentId] =
                submission.evaluationStatus ?? 'c';
            _evaluationRemarks[submission.studentId] =
                submission.evaluationRemark ?? '';
            _evaluationRanks[submission.studentId] =
                submission.evaluationRank ?? '';
          }
        }

        setState(() {
          _data = response;
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
        _errorMessage = 'Failed to load submissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEvaluation(int studentId) async {
    final status = _evaluationStatus[studentId] ?? 'i';
    final remark = _evaluationRemarks[studentId] ?? '';
    final rank = _evaluationRanks[studentId] ?? '';

    try {
      final success = await HomeworkService.evaluateHomework(
        homeworkId: widget.homeworkId,
        studentId: studentId,
        status: status,
        remark: remark.isEmpty ? null : remark,
        rank: rank.isEmpty ? null : rank,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluation saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSubmissions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save evaluation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluate Homework'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
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
              onPressed: _loadSubmissions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_data == null || _data!.submissions.isEmpty) {
      return const Center(
        child: Text('No submissions found'),
      );
    }

    return Column(
      children: [
        // Summary Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_data!.homework.subjectName} - ${_data!.homework.displayClass}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSummaryChip(
                    'Total',
                    _data!.totalStudents.toString(),
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryChip(
                    'Submitted',
                    _data!.submittedCount.toString(),
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryChip(
                    'Evaluated',
                    '${_data!.evaluatedCount}/${_data!.totalStudents}',
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Submissions List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSubmissions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _data!.submissions.length,
              itemBuilder: (context, index) {
                final submission = _data!.submissions[index];
                return _buildSubmissionCard(submission);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildSubmissionCard(HomeworkSubmission submission) {
    final currentStatus = _evaluationStatus[submission.studentId] ?? 'i';
    final currentRemark = _evaluationRemarks[submission.studentId] ?? '';
    final currentRank = _evaluationRanks[submission.studentId] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: submission.submitted
              ? Colors.green
              : submission.evaluated
                  ? Colors.blue
                  : Colors.grey,
          child: Text(
            submission.studentName.isNotEmpty
                ? submission.studentName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          submission.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (submission.roll != null && submission.roll!.isNotEmpty)
              Text('Roll: ${submission.roll}'),
            Row(
              children: [
                if (submission.submitted)
                  Chip(
                    label: const Text('Submitted', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green.withOpacity(0.2),
                  )
                else
                  Chip(
                    label: const Text('Not Submitted', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.red.withOpacity(0.2),
                  ),
                const SizedBox(width: 8),
                if (submission.evaluated)
                  Chip(
                    label: const Text('Evaluated', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue.withOpacity(0.2),
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Submission Info
                if (submission.submitted) ...[
                  const Text(
                    'Submission Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (submission.submissionDate != null)
                    Text(
                      'Submitted: ${DateFormat('MMM d, yyyy').format(DateTime.parse(submission.submissionDate!))}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (submission.submissionMessage != null &&
                      submission.submissionMessage!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      submission.submissionMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                  const Divider(height: 24),
                ],

                // Evaluation
                const Text(
                  'Evaluation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Completed'),
                      selected: currentStatus == 'c',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _evaluationStatus[submission.studentId] = 'c';
                          });
                        }
                      },
                      selectedColor: Colors.green,
                      backgroundColor: Colors.green.withOpacity(0.2),
                    ),
                    ChoiceChip(
                      label: const Text('Incomplete'),
                      selected: currentStatus == 'i',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _evaluationStatus[submission.studentId] = 'i';
                          });
                        }
                      },
                      selectedColor: Colors.red,
                      backgroundColor: Colors.red.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: currentRemark),
                  decoration: const InputDecoration(
                    labelText: 'Remark',
                    hintText: 'Enter evaluation remark...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _evaluationRemarks[submission.studentId] = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: currentRank),
                  decoration: const InputDecoration(
                    labelText: 'Rank/Grade',
                    hintText: 'e.g., A, B, 1st, 2nd...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _evaluationRanks[submission.studentId] = value;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _saveEvaluation(submission.studentId),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Evaluation'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

