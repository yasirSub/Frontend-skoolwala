import 'mailbox_message.dart';
import 'mailbox_reply.dart';

class MailboxThread {
  final MailboxMessage message;
  final List<MailboxReply> replies;

  const MailboxThread({required this.message, required this.replies});

  factory MailboxThread.fromJson(Map<String, dynamic> json) {
    final messageJson =
        (json['message'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final repliesJson = (json['replies'] as List?) ?? const [];

    return MailboxThread(
      message: MailboxMessage.fromJson(messageJson),
      replies: repliesJson
          .map((e) => MailboxReply.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
