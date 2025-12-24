import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';
import '../../students/models/student.dart';
import 'book_list_screen.dart';

/// Issue Book Screen
/// Allows teacher to issue a book to a student
class IssueBookScreen extends StatefulWidget {
  final Book? book;

  const IssueBookScreen({super.key, this.book});

  @override
  State<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends State<IssueBookScreen> {
  Book? _selectedBook;
  Student? _selectedStudent;
  DateTime? _issueDate;
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  final List<Student> _students = [];
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.book;
    _issueDate = DateTime.now();
    _dueDate = DateTime.now().add(const Duration(days: 7)); // Default 7 days
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });

    try {
      // Load students from all classes (or let teacher select class first)
      // For now, we'll show a message to select class first
      setState(() {
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _selectBook() async {
    final book = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookListScreen()),
    );
    if (book != null) {
      setState(() {
        _selectedBook = book as Book;
      });
    }
  }

  Future<void> _selectStudent() async {
    // Navigate to student selection
    // For now, show a dialog or navigate to student list
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Student'),
        content: const Text('Please select a class first to view students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _issueBook() async {
    if (_selectedBook == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a book')));
      return;
    }

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a student')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await LibraryService.issueBook(
        bookId: _selectedBook!.id,
        studentId: _selectedStudent!.id.toString(),
        issueDate: _issueDate!,
        dueDate: _dueDate!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book issued successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh book list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue book: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.book, size: 40),
                title: const Text('Book'),
                subtitle: Text(
                  _selectedBook?.name ?? 'Select a book',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedBook != null ? null : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectBook,
              ),
            ),
            const SizedBox(height: 16),

            // Student Selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, size: 40),
                title: const Text('Student'),
                subtitle: Text(
                  _selectedStudent?.name ?? 'Select a student',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedStudent != null ? null : Colors.grey,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectStudent,
              ),
            ),
            const SizedBox(height: 16),

            // Issue Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, size: 40),
                title: const Text('Issue Date'),
                subtitle: Text(
                  _issueDate != null
                      ? DateFormat('MMM dd, yyyy').format(_issueDate!)
                      : 'Select date',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _issueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _issueDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Due Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.event, size: 40),
                title: const Text('Due Date'),
                subtitle: Text(
                  _dueDate != null
                      ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                      : 'Select date',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: _issueDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 32),

            // Issue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _issueBook,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Issue Book', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
