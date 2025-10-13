import 'user_role.dart';

enum ActivityType {
  login('LOGIN'),
  logout('LOGOUT'),
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE'),
  view('VIEW'),
  statusChange('STATUS_CHANGE'),
  assignment('ASSIGNMENT'),
  export('EXPORT'),
  import('IMPORT'),
  backup('BACKUP'),
  restore('RESTORE');

  const ActivityType(this.value);
  final String value;
}

enum EntityType {
  customer('CUSTOMER'),
  ticket('TICKET'),
  device('DEVICE'),
  part('PART'),
  user('USER'),
  system('SYSTEM');

  const EntityType(this.value);
  final String value;
}

class ActivityLog {
  final String id;
  final String userId;
  final String username;
  final UserRole userRole;
  final ActivityType activityType;
  final EntityType entityType;
  final String? entityId;
  final String description;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.username,
    required this.userRole,
    required this.activityType,
    required this.entityType,
    this.entityId,
    required this.description,
    this.metadata,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
  });

  ActivityLog copyWith({
    String? id,
    String? userId,
    String? username,
    UserRole? userRole,
    ActivityType? activityType,
    EntityType? entityType,
    String? entityId,
    String? description,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
    DateTime? timestamp,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userRole: userRole ?? this.userRole,
      activityType: activityType ?? this.activityType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userRole': userRole.value,
      'activityType': activityType.value,
      'entityType': entityType.value,
      'entityId': entityId,
      'description': description,
      'metadata': metadata != null ? metadata.toString() : null,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      userRole: UserRole.values.firstWhere(
        (r) => r.value == map['userRole'],
        orElse: () => UserRole.technician,
      ),
      activityType: ActivityType.values.firstWhere(
        (t) => t.value == map['activityType'],
        orElse: () => ActivityType.view,
      ),
      entityType: EntityType.values.firstWhere(
        (t) => t.value == map['entityType'],
        orElse: () => EntityType.system,
      ),
      entityId: map['entityId'],
      description: map['description'] ?? '',
      metadata: map['metadata'] != null && map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  @override
  String toString() {
    return 'ActivityLog{userId: $userId, activityType: ${activityType.value}, entityType: ${entityType.value}, description: $description}';
  }
}
