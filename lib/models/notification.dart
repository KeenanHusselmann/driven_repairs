import 'user_role.dart';

enum NotificationType {
  info('INFO'),
  warning('WARNING'),
  error('ERROR'),
  success('SUCCESS'),
  reminder('REMINDER'),
  assignment('ASSIGNMENT'),
  statusUpdate('STATUS_UPDATE'),
  system('SYSTEM');

  const NotificationType(this.value);
  final String value;
}

enum NotificationPriority {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH'),
  urgent('URGENT');

  const NotificationPriority(this.value);
  final String value;
}

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String? userId; // If null, it's a broadcast notification
  final String? fromUserId;
  final String? fromUsername;
  final UserRole? targetRole; // For role-based notifications
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? actionData;
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.userId,
    this.fromUserId,
    this.fromUsername,
    this.targetRole,
    this.entityType,
    this.entityId,
    this.actionData,
    this.isRead = false,
    this.isArchived = false,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUnread => !isRead;

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? userId,
    String? fromUserId,
    String? fromUsername,
    UserRole? targetRole,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? actionData,
    bool? isRead,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      targetRole: targetRole ?? this.targetRole,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      actionData: actionData ?? this.actionData,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.value,
      'priority': priority.value,
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'targetRole': targetRole?.value,
      'entityType': entityType,
      'entityId': entityId,
      'actionData': actionData?.toString(),
      'isRead': isRead ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.value == map['type'],
        orElse: () => NotificationType.info,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.value == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      userId: map['userId'],
      fromUserId: map['fromUserId'],
      fromUsername: map['fromUsername'],
      targetRole: map['targetRole'] != null
          ? UserRole.values.firstWhere(
              (r) => r.value == map['targetRole'],
              orElse: () => UserRole.technician,
            )
          : null,
      entityType: map['entityType'],
      entityId: map['entityId'],
      actionData: map['actionData'] != null
          ? Map<String, dynamic>.from(map['actionData'])
          : null,
      isRead: (map['isRead'] ?? 0) == 1,
      isArchived: (map['isArchived'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      readAt: map['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'])
          : null,
    );
  }

  @override
  String toString() {
    return 'Notification{id: $id, title: $title, type: ${type.value}, priority: ${priority.value}}';
  }
}
