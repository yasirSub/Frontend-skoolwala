import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:skoolwala/shared/config/api_config.dart';
import 'package:skoolwala/shared/services/session_manager.dart';

import '../../../notifications/services/mailbox_notifications_sync.dart';

import '../models/mailbox_message.dart';
import '../models/mailbox_thread.dart';
import '../models/mailbox_recipient.dart';
import 'mailbox_unread_store.dart';

class MailboxApiService {
  MailboxApiService();

  String _endpoint(String path) => '${ApiConfig.getBaseUrl()}/$path';

  Map<String, String> _headers() {
    return {...ApiConfig.defaultHeaders};
  }

  Map<String, dynamic> _authBody() {
    return SessionManager.instance.getAuthBody();
  }

  void _debugRequest(String label, Uri url, Map<String, dynamic> payload) {
    if (!kDebugMode) return;
    final safe = Map<String, dynamic>.from(payload);
    if (safe.containsKey('password')) {
      safe['password'] = '***';
    }
    // ignore: avoid_print
    print('📩 [Mailbox][$label] POST $url');
    // ignore: avoid_print
    print('📩 [Mailbox][$label] payload: ${jsonEncode(safe)}');
  }

  void _debugResponse(String label, http.Response response) {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('📩 [Mailbox][$label] status: ${response.statusCode}');
    // ignore: avoid_print
    print('📩 [Mailbox][$label] body: ${response.body}');
  }

  Exception _mapTransportException(Object e) {
    final baseUrl = ApiConfig.getBaseUrl();
    final msg = e.toString();

    if (e is HandshakeException || msg.contains('CERTIFICATE_VERIFY_FAILED')) {
      return Exception(
        'SSL certificate error for $baseUrl. '
        'Server certificate is expired/invalid (or device date/time is wrong). '
        'Fix: renew SSL certificate on the server for this domain, then try again. '
        'Details: $msg',
      );
    }

    if (e is SocketException) {
      return Exception('Network error while connecting to $baseUrl: $msg');
    }

    return Exception(msg);
  }

  Future<Map<String, dynamic>> _postJson(
    String label,
    String apiPath,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse(_endpoint(apiPath));
    _debugRequest(label, url, payload);

    http.Response response;
    try {
      response = await http
          .post(url, headers: _headers(), body: jsonEncode(payload))
          .timeout(ApiConfig.requestTimeout);
    } catch (e) {
      throw _mapTransportException(e);
    }

    _debugResponse(label, response);

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception(
        'Invalid API response from ${ApiConfig.getBaseUrl()} ($apiPath). '
        'Raw: ${response.body}',
      );
    }
  }

  Future<List<MailboxMessage>> getMessages({required String box}) async {
    final payload = {..._authBody(), 'box': box, 'limit': 50, 'offset': 0};

    final decoded = await _postJson(
      'getMessages/$box',
      ApiConfig.getMessages,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to fetch messages',
      );
    }

    final messagesJson =
        ((decoded['data'] as Map<String, dynamic>)['messages'] as List?) ??
        const [];

    final messages = messagesJson
        .map((e) => MailboxMessage.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    if (box == 'inbox') {
      final unreadCount = messages.where((m) => m.readStatus == 0).length;
      await MailboxUnreadStore.setInboxUnreadCount(unreadCount);
    }

    // Auto-sync inbox messages into app Notifications + show OS notification
    if (box == 'inbox') {
      // Fire-and-forget to avoid blocking UI
      // ignore: unawaited_futures
      MailboxNotificationsSync.syncInboxMessages(messages);
    }

    return messages;
  }

  Future<MailboxThread> getMessageThread({required int messageId}) async {
    final payload = {..._authBody(), 'message_id': messageId};

    final decoded = await _postJson(
      'getMessageThread',
      ApiConfig.getMessageThread,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to fetch thread',
      );
    }

    return MailboxThread.fromJson(
      (decoded['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> markMessageAsRead({required int messageId}) async {
    final payload = {..._authBody(), 'message_id': messageId};

    final decoded = await _postJson(
      'markMessageAsRead',
      ApiConfig.markMessageAsRead,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to mark as read',
      );
    }
  }

  Future<int> sendMessage({
    required int receiverRoleId,
    required int receiverId,
    required String subject,
    required String body,
  }) async {
    final payload = {
      ..._authBody(),
      'receiver_role_id': receiverRoleId,
      'receiver_id': receiverId,
      'subject': subject,
      'body': body,
    };

    final decoded = await _postJson(
      'sendMessage',
      ApiConfig.sendMessage,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to send message',
      );
    }

    final data = (decoded['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return int.tryParse(data['message_id'].toString()) ?? 0;
  }

  Future<int> replyMessage({
    required int messageId,
    required String body,
  }) async {
    final payload = {..._authBody(), 'message_id': messageId, 'body': body};

    final decoded = await _postJson(
      'replyMessage',
      ApiConfig.replyMessage,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(decoded['message']?.toString() ?? 'Failed to send reply');
    }

    final data = (decoded['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return int.tryParse(data['reply_id'].toString()) ?? 0;
  }

  Future<List<MailboxRecipient>> getRecipients({required int roleId}) async {
    final payload = {..._authBody(), 'role_id': roleId};

    final decoded = await _postJson(
      'getRecipients',
      ApiConfig.mailboxRecipients,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to fetch recipients',
      );
    }

    final recipientsJson =
        ((decoded['data'] as Map<String, dynamic>)['recipients'] as List?) ??
        const [];

    return recipientsJson
        .map(
          (e) => MailboxRecipient.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> setFavouriteStatus({
    required int messageId,
    required bool status,
  }) async {
    final payload = {..._authBody(), 'message_id': messageId, 'status': status};

    final decoded = await _postJson(
      'setFavouriteStatus',
      ApiConfig.setMessageFavouriteStatus,
      payload,
    );

    if (decoded['status'] != 'success') {
      throw Exception(
        decoded['message']?.toString() ?? 'Failed to update favourite',
      );
    }
  }
}
