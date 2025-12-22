class MailboxMessage {
  final int id;
  final String subject;
  final String body;
  final String sender;
  final String receiver;
  final int readStatus;
  final int replyStatus;
  final int favInbox;
  final int favSent;
  final String createdAt;
  final String updatedAt;

  const MailboxMessage({
    required this.id,
    required this.subject,
    required this.body,
    required this.sender,
    required this.receiver,
    required this.readStatus,
    required this.replyStatus,
    required this.favInbox,
    required this.favSent,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isFavouriteForBox(String box) {
    if (box == 'sent') return favSent == 1;
    if (box == 'important') return favInbox == 1 || favSent == 1;
    return favInbox == 1;
  }

  factory MailboxMessage.fromJson(Map<String, dynamic> json) {
    return MailboxMessage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      subject: (json['subject'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      receiver: (json['reciever'] ?? json['receiver'] ?? '').toString(),
      readStatus: int.tryParse(json['read_status'].toString()) ?? 0,
      replyStatus: int.tryParse(json['reply_status'].toString()) ?? 0,
      favInbox: int.tryParse(json['fav_inbox'].toString()) ?? 0,
      favSent: int.tryParse(json['fav_sent'].toString()) ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }
}
