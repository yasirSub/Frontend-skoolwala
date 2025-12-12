// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/library_service.dart';
import 'issue_book_screen.dart';

/// Book List Screen
/// Displays all available books in the library
class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<Book> _books = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await LibraryService.getBookList();
      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load books: $e';
        _isLoading = false;
      });
    }
  }

  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) return _books;
    return _books.where((book) {
      return book.name.toLowerCase().contains(_searchQuery) ||
          (book.author != null &&
              book.author!.toLowerCase().contains(_searchQuery)) ||
          (book.isbn != null &&
              book.isbn!.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books by name, author, or ISBN...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
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
              ),
            ),
          ),
          // Books List
          Expanded(child: _buildBody()),
        ],
      ),
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
            ElevatedButton(onPressed: _loadBooks, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_filteredBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.library_books,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No books found matching "$_searchQuery"'
                  : 'No books available',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBooks.length,
        itemBuilder: (context, index) {
          return _buildBookCard(_filteredBooks[index]);
        },
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          radius: 30,
          child: Icon(
            Icons.book,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
        title: Text(
          book.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.author != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(book.author!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
            if (book.isbn != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'ISBN: ${book.isbn}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: book.available > 0
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${book.available} Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: book.available > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Total: ${book.total}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Show book details or navigate to issue book
          _showBookDetails(book);
        },
      ),
    );
  }

  void _showBookDetails(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (book.author != null) ...[
                const Text(
                  'Author:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(book.author!),
                const SizedBox(height: 8),
              ],
              if (book.isbn != null) ...[
                const Text(
                  'ISBN:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(book.isbn!),
                const SizedBox(height: 8),
              ],
              const Text(
                'Availability:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('${book.available} of ${book.total} available'),
              if (book.category != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Category:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(book.category!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (book.available > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IssueBookScreen(book: book),
                  ),
                );
              },
              child: const Text('Issue Book'),
            ),
        ],
      ),
    );
  }
}

/// Book Model
class Book {
  final String id;
  final String name;
  final String? author;
  final String? isbn;
  final String? category;
  final int total;
  final int available;

  Book({
    required this.id,
    required this.name,
    this.author,
    this.isbn,
    this.category,
    required this.total,
    required this.available,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['book_name']?.toString() ?? '',
      author: json['author']?.toString(),
      isbn: json['isbn']?.toString(),
      category:
          json['category']?.toString() ?? json['category_name']?.toString(),
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      available: int.tryParse(json['available']?.toString() ?? '0') ?? 0,
    );
  }
}
