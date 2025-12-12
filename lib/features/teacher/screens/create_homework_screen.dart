import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/homework_service.dart';
import '../services/teacher_class_service.dart';

class CreateHomeworkScreen extends StatefulWidget {
  final TeacherClass? teacherClass;
  final int? classId;
  final int? sectionId;

  const CreateHomeworkScreen({
    super.key,
    this.teacherClass,
    this.classId,
    this.sectionId,
  });

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  TeacherClass? _selectedClass;
  int? _selectedSubjectId;
  DateTime _homeworkDate = DateTime.now();
  DateTime _submissionDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _scheduleDate;
  String _status = 'published';
  bool _smsNotification = false;
  bool _isLoading = false;
  bool _isLoadingSubjects = false;

  List<TeacherClass> _classes = [];
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    if (widget.teacherClass != null) {
      _selectedClass = widget.teacherClass;
      _loadSubjects();
    } else {
      _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    try {
      final response = await TeacherClassService.getMyClasses();
      if (response.isSuccess) {
        setState(() {
          _classes = response.classes;
          if (widget.classId != null && widget.sectionId != null) {
            _selectedClass = _classes.firstWhere(
              (c) =>
                  c.classId == widget.classId &&
                  c.sectionId == widget.sectionId,
              orElse: () => _classes.isNotEmpty ? _classes.first : _classes.first,
            );
            if (_selectedClass != null) {
              _loadSubjects();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load classes: $e')),
        );
      }
    }
  }

  Future<void> _loadSubjects() async {
    if (_selectedClass == null) return;

    setState(() {
      _isLoadingSubjects = true;
    });

    try {
      final response = await TeacherClassService.getSubjectsForClassSection(
        classId: _selectedClass!.classId,
        sectionId: _selectedClass!.sectionId,
      );

      if (response['status'] == 'success') {
        final subjectsData = response['data']['subjects'] as List<dynamic>;
        setState(() {
          _subjects = subjectsData
              .map((s) => {
                    'id': int.parse(s['subject_id'].toString()),
                    'name': s['subject_name'].toString(),
                  })
              .toList();
          _isLoadingSubjects = false;
        });
      } else {
        setState(() {
          _isLoadingSubjects = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSubjects = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(DateTime initialDate, Function(DateTime) onSelect) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      onSelect(picked);
    }
  }

  Future<void> _submitHomework() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    if (_submissionDate.isBefore(_homeworkDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Submission date cannot be before homework date')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final homework = await HomeworkService.createHomework(
        classId: _selectedClass!.classId,
        sectionId: _selectedClass!.sectionId,
        subjectId: _selectedSubjectId!,
        dateOfHomework: DateFormat('yyyy-MM-dd').format(_homeworkDate),
        dateOfSubmission: DateFormat('yyyy-MM-dd').format(_submissionDate),
        description: _descriptionController.text.trim(),
        scheduleDate: _scheduleDate != null
            ? DateFormat('yyyy-MM-dd').format(_scheduleDate!)
            : null,
        status: _status,
        smsNotification: _smsNotification,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Homework created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, homework);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create homework: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Homework'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submitHomework,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Class Selection
            if (widget.teacherClass == null)
              DropdownButtonFormField<TeacherClass>(
                value: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Class *',
                  border: OutlineInputBorder(),
                ),
                items: _classes.map((cls) {
                  return DropdownMenuItem(
                    value: cls,
                    child: Text(cls.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                    _selectedSubjectId = null;
                  });
                  _loadSubjects();
                },
                validator: (value) =>
                    value == null ? 'Please select a class' : null,
              )
            else
              ListTile(
                title: const Text('Class'),
                subtitle: Text(_selectedClass?.displayName ?? ''),
                leading: const Icon(Icons.class_),
              ),

            const SizedBox(height: 16),

            // Subject Selection
            if (_isLoadingSubjects)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<int>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  border: OutlineInputBorder(),
                ),
                items: _subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject['id'] as int,
                    child: Text(subject['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSubjectId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a subject' : null,
              ),

            const SizedBox(height: 16),

            // Homework Date
            ListTile(
              title: const Text('Homework Date *'),
              subtitle: Text(DateFormat('MMMM d, yyyy').format(_homeworkDate)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(_homeworkDate, (date) {
                setState(() {
                  _homeworkDate = date;
                });
              }),
            ),

            // Submission Date
            ListTile(
              title: const Text('Submission Date *'),
              subtitle: Text(DateFormat('MMMM d, yyyy').format(_submissionDate)),
              leading: const Icon(Icons.event),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectDate(_submissionDate, (date) {
                setState(() {
                  _submissionDate = date;
                });
              }),
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter homework description...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter homework description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'published',
                  child: Text('Published'),
                ),
                DropdownMenuItem(
                  value: 'pending',
                  child: Text('Pending (Schedule for later)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _status = value ?? 'published';
                  if (_status == 'pending') {
                    _scheduleDate = _scheduleDate ?? DateTime.now().add(const Duration(days: 1));
                  }
                });
              },
            ),

            // Schedule Date (if pending)
            if (_status == 'pending') ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Schedule Date'),
                subtitle: Text(_scheduleDate != null
                    ? DateFormat('MMMM d, yyyy').format(_scheduleDate!)
                    : 'Not set'),
                leading: const Icon(Icons.schedule),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectDate(
                  _scheduleDate ?? DateTime.now().add(const Duration(days: 1)),
                  (date) {
                    setState(() {
                      _scheduleDate = date;
                    });
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // SMS Notification
            SwitchListTile(
              title: const Text('Send SMS Notification'),
              subtitle: const Text('Notify students via SMS'),
              value: _smsNotification,
              onChanged: (value) {
                setState(() {
                  _smsNotification = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitHomework,
                icon: const Icon(Icons.save),
                label: Text(_isLoading ? 'Creating...' : 'Create Homework'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

