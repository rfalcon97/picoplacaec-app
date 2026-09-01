enum NotificationKind { nightBefore, sameDay, serverPush }

class NotificationHistoryEntry {
  const NotificationHistoryEntry({
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    this.read = false,
  });

  final String title;
  final String body;
  final NotificationKind kind;
  final DateTime createdAt;
  final bool read;

  NotificationHistoryEntry copyWith({bool? read}) => NotificationHistoryEntry(
        title: title,
        body: body,
        kind: kind,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory NotificationHistoryEntry.fromJson(Map<String, dynamic> json) => NotificationHistoryEntry(
        title: json['title'] as String,
        body: json['body'] as String,
        kind: NotificationKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => NotificationKind.sameDay,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
      );
}
