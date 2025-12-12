import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/homework_service.dart';
import 'evaluate_homework_screen.dart';
import 'create_homework_screen.dart';

class HomeworkListScreen extends StatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  State<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends State<HomeworkListScreen>
    with SingleTickerProviderStateMixin {
  List<Homework> _homeworks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'published', 'pending'

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _filterStatus = 'all';
              break;
            case 1:
              _filterStatus = 'published';
              break;
            case 2:
              _filterStatus = 'pending';
              break;
          }
        });
        _loadHomeworks();
      }
    });
    _loadHomeworks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeworks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await HomeworkService.getMyHomeworks(
        status: _filterStatus == 'all' ? null : _filterStatus,
      );

      if (response.isSuccess) {
        setState(() {
          _homeworks = response.homeworks;
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
        _errorMessage = 'Failed to load homeworks: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createHomework() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateHomeworkScreen(),
      ),
    );

    if (result != null) {
      _loadHomeworks();
    }
  }

  void _navigateToEvaluate(Homework homework) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvaluateHomeworkScreen(homeworkId: homework.id),
      ),
    ).then((_) => _loadHomeworks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Homeworks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHomeworks,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Published', icon: Icon(Icons.publish)),
            Tab(text: 'Pending', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createHomework,
        icon: const Icon(Icons.add),
        label: const Text('Create Homework'),
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
              onPressed: _loadHomeworks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_homeworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No homeworks found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first homework assignment',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHomeworks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _homeworks.length,
        itemBuilder: (context, index) {
          final homework = _homeworks[index];
          final isOverdue = homework.status == 'published' &&
              DateTime.parse(homework.dateOfSubmission).isBefore(DateTime.now());

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: InkWell(
              onTap: () => _navigateToEvaluate(homework),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                homework.subjectName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                homework.displayClass,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            homework.status == 'published' ? 'Published' : 'Pending',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: homework.status == 'published'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        _buildInfoItem(
                          Icons.calendar_today,
                          'Given',
                          DateFormat('MMM d').format(
                            DateTime.parse(homework.dateOfHomework),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          Icons.event,
                          'Due',
                          DateFormat('MMM d, yyyy').format(
                            DateTime.parse(homework.dateOfSubmission),
                          ),
                          isOverdue ? Colors.red : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      homework.description.length > 100
                          ? '${homework.description.substring(0, 100)}...'
                          : homework.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatChip(
                          Icons.people,
                          '${homework.submissionCount}/${homework.studentCount}',
                          'Submissions',
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          Icons.check_circle,
                          '${homework.evaluationCount}',
                          'Evaluated',
                          homework.evaluationCount < homework.studentCount
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, [Color? color]) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, [Color? color]) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color ?? Colors.grey),
      label: Text(
        '$value $label',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: (color ?? Colors.grey).withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }
}

