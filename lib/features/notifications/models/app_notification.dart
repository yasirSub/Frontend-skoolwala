class AppNotification {
  final String id;

  /// e.g. "mail", "class", "attendance", "general"
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Optional deep-link target inside the app.
  /// When present, the notifications list can navigate with `Navigator.pushNamed`.
  ///
  /// Kept optional for backward compatibility with existing stored notifications.
  final String? routeName;
  final Map<String, dynamic>? routeArgs;

  /// Optional time window for time-based notifications (e.g. classes).
  ///
  /// When present, the UI can render a progress indicator for ongoing items.
  /// Kept optional for backward compatibility with existing stored notifications.
  final DateTime? startAt;
  final DateTime? endAt;

  /// If set and in the future, this notification should not be removable.
  ///
  /// Used to keep ongoing class notifications until class end.
  final DateTime? lockedUntil;

  const AppNotification({
    required this.id,
    this.type = 'general',
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.routeName,
    this.routeArgs,
    this.startAt,
    this.endAt,
    this.lockedUntil,
  });

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? routeName,
    Map<String, dynamic>? routeArgs,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? lockedUntil,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      routeName: routeName ?? this.routeName,
      routeArgs: routeArgs ?? this.routeArgs,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'routeName': routeName,
      'routeArgs': routeArgs,
      'startAt': startAt?.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'lockedUntil': lockedUntil?.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    final createdAt = createdAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(createdAtRaw);

    final startAtRaw = json['startAt']?.toString();
    final endAtRaw = json['endAt']?.toString();
    final lockedUntilRaw = json['lockedUntil']?.toString();

    final routeArgsRaw = json['routeArgs'];

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: createdAt ?? DateTime.now(),
      isRead: json['isRead'] == true || json['isRead'] == 1,
      routeName: json['routeName']?.toString(),
      routeArgs: routeArgsRaw is Map
          ? routeArgsRaw.map((key, value) => MapEntry(key.toString(), value))
          : null,
      startAt: startAtRaw == null ? null : DateTime.tryParse(startAtRaw),
      endAt: endAtRaw == null ? null : DateTime.tryParse(endAtRaw),
      lockedUntil: lockedUntilRaw == null
          ? null
          : DateTime.tryParse(lockedUntilRaw),
    );
  }
}
