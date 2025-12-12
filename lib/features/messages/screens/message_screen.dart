// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../services/message_service.dart';

/// Message Screen
/// Shows messages/notifications for the teacher
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMessages();
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

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await MessageService.getMessages();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  List<Message> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    return _messages.where((msg) {
      final subjectMatch = msg.subject.toLowerCase().contains(_searchQuery);
      final bodyMatch = msg.body.toLowerCase().contains(_searchQuery);
      final fromMatch = msg.from != null
          ? msg.from!.toLowerCase().contains(_searchQuery)
          : false;
      return subjectMatch || bodyMatch || fromMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
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
                hintText: 'Search messages...',
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
          // Messages List
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
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.mail_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No messages found matching "$_searchQuery"'
                  : 'No messages',
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
      onRefresh: _loadMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMessages.length,
        itemBuilder: (context, index) {
          return _buildMessageCard(_filteredMessages[index]);
        },
      ),
    );
  }

  Widget _buildMessageCard(Message message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: message.isRead ? 1 : 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: message.isRead
              ? Colors.grey.withOpacity(0.2)
              : Theme.of(context).primaryColor.withOpacity(0.2),
          child: Icon(
            message.isRead ? Icons.mail : Icons.mail_outline,
            color: message.isRead
                ? Colors.grey
                : Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          message.subject,
          style: TextStyle(
            fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (message.from != null) ...[
              Text(
                'From: ${message.from}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(message.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: message.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          _showMessageDetails(message);
        },
      ),
    );
  }

  void _showMessageDetails(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.from != null) ...[
                const Text(
                  'From:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(message.from!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(message.body),
              const SizedBox(height: 16),
              Text(
                DateFormat('MMMM dd, yyyy • hh:mm a').format(message.date),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    // Mark as read
    if (!message.isRead) {
      MessageService.markAsRead(message.id);
      _loadMessages();
    }
  }
}

/// Message Model
class Message {
  final String id;
  final String subject;
  final String body;
  final String? from;
  final DateTime date;
  final bool isRead;

  Message({
    required this.id,
    required this.subject,
    required this.body,
    this.from,
    required this.date,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      subject: json['subject']?.toString() ?? json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? json['message']?.toString() ?? '',
      from: json['from']?.toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}
