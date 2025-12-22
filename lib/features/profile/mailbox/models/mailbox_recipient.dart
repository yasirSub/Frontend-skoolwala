class MailboxRecipient {
  final int id;
  final String name;
  final String? email;
  final String? mobile;

  const MailboxRecipient({
    required this.id,
    required this.name,
    this.email,
    this.mobile,
  });

  factory MailboxRecipient.fromJson(Map<String, dynamic> json) {
    return MailboxRecipient(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
    );
  }
}
