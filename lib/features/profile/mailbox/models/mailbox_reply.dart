class MailboxReply {
  final int id;
  final int messageId;
  final String body;
  final int identity;
  final String createdAt;

  const MailboxReply({
    required this.id,
    required this.messageId,
    required this.body,
    required this.identity,
    required this.createdAt,
  });

  factory MailboxReply.fromJson(Map<String, dynamic> json) {
    return MailboxReply(
      id: int.tryParse(json['id'].toString()) ?? 0,
      messageId: int.tryParse(json['message_id'].toString()) ?? 0,
      body: (json['body'] ?? '').toString(),
      identity: int.tryParse(json['identity'].toString()) ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
