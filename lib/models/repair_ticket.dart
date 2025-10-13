enum RepairStatus {
  pending,
  diagnosed,
  inProgress,
  waitingForParts,
  waitingForCustomer,
  testing,
  completed,
  cancelled,
  onHold;

  String get displayName {
    switch (this) {
      case RepairStatus.pending:
        return 'Pending';
      case RepairStatus.diagnosed:
        return 'Diagnosed';
      case RepairStatus.inProgress:
        return 'In Progress';
      case RepairStatus.waitingForParts:
        return 'Waiting for Parts';
      case RepairStatus.waitingForCustomer:
        return 'Waiting for Customer';
      case RepairStatus.testing:
        return 'Testing';
      case RepairStatus.completed:
        return 'Completed';
      case RepairStatus.cancelled:
        return 'Cancelled';
      case RepairStatus.onHold:
        return 'On Hold';
    }
  }

  bool get isActive {
    return this != RepairStatus.completed && this != RepairStatus.cancelled;
  }
}

enum Priority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }
}

class RepairTicket {
  final String id;
  final String customerId;
  final String deviceId;
  final String? technicianId;
  final String? createdBy; // User ID who created the ticket
  final String title;
  final String description;
  final RepairStatus status;
  final Priority priority;
  final double? estimatedCost;
  final double? finalCost;
  final DateTime? estimatedCompletion;
  final DateTime? actualCompletion;
  final String? diagnosis;
  final String? resolution;
  final String? notes;
  final List<String> parts; // List of part IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  RepairTicket({
    required this.id,
    required this.customerId,
    required this.deviceId,
    this.technicianId,
    this.createdBy,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.estimatedCost,
    this.finalCost,
    this.estimatedCompletion,
    this.actualCompletion,
    this.diagnosis,
    this.resolution,
    this.notes,
    this.parts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (estimatedCompletion == null || !status.isActive) return false;
    return DateTime.now().isAfter(estimatedCompletion!);
  }

  Duration? get timeToCompletion {
    if (estimatedCompletion == null || !status.isActive) return null;
    final now = DateTime.now();
    if (now.isAfter(estimatedCompletion!)) return null;
    return estimatedCompletion!.difference(now);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'deviceId': deviceId,
      'technicianId': technicianId,
      'createdBy': createdBy,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'estimatedCost': estimatedCost,
      'finalCost': finalCost,
      'estimatedCompletion': estimatedCompletion?.millisecondsSinceEpoch,
      'actualCompletion': actualCompletion?.millisecondsSinceEpoch,
      'diagnosis': diagnosis,
      'resolution': resolution,
      'notes': notes,
      'parts': parts.join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory RepairTicket.fromMap(Map<String, dynamic> map) {
    return RepairTicket(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      technicianId: map['technicianId'],
      createdBy: map['createdBy'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: RepairStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RepairStatus.pending,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => Priority.medium,
      ),
      estimatedCost: map['estimatedCost']?.toDouble(),
      finalCost: map['finalCost']?.toDouble(),
      estimatedCompletion: map['estimatedCompletion'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['estimatedCompletion'])
          : null,
      actualCompletion: map['actualCompletion'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['actualCompletion'])
          : null,
      diagnosis: map['diagnosis'],
      resolution: map['resolution'],
      notes: map['notes'],
      parts: map['parts'] != null && map['parts'].isNotEmpty
          ? map['parts'].split(',')
          : [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  RepairTicket copyWith({
    String? id,
    String? customerId,
    String? deviceId,
    String? technicianId,
    String? createdBy,
    String? title,
    String? description,
    RepairStatus? status,
    Priority? priority,
    double? estimatedCost,
    double? finalCost,
    DateTime? estimatedCompletion,
    DateTime? actualCompletion,
    String? diagnosis,
    String? resolution,
    String? notes,
    List<String>? parts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RepairTicket(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      deviceId: deviceId ?? this.deviceId,
      technicianId: technicianId ?? this.technicianId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      finalCost: finalCost ?? this.finalCost,
      estimatedCompletion: estimatedCompletion ?? this.estimatedCompletion,
      actualCompletion: actualCompletion ?? this.actualCompletion,
      diagnosis: diagnosis ?? this.diagnosis,
      resolution: resolution ?? this.resolution,
      notes: notes ?? this.notes,
      parts: parts ?? this.parts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RepairTicket(id: $id, title: $title, status: ${status.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RepairTicket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
