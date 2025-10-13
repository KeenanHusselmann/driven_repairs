class TicketResolutionMetric {
  final String id;
  final String ticketId;
  final bool resolvedOnFirstCall;
  final int callbackCount;
  final DateTime? firstResponseTime;
  final DateTime? resolutionTime;
  final bool deliveredOnTime;
  final DateTime? scheduledDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? delayReason;
  final List<String> techniciansAssigned; // List of technician IDs
  final double totalLaborHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketResolutionMetric({
    required this.id,
    required this.ticketId,
    required this.resolvedOnFirstCall,
    required this.callbackCount,
    this.firstResponseTime,
    this.resolutionTime,
    required this.deliveredOnTime,
    this.scheduledDeliveryDate,
    this.actualDeliveryDate,
    this.delayReason,
    this.techniciansAssigned = const [],
    required this.totalLaborHours,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration? get responseTime {
    if (firstResponseTime == null) return null;
    return firstResponseTime!.difference(createdAt);
  }

  Duration? get totalResolutionTime {
    if (resolutionTime == null) return null;
    return resolutionTime!.difference(createdAt);
  }

  int? get deliveryDelayDays {
    if (scheduledDeliveryDate == null || actualDeliveryDate == null) return null;
    return actualDeliveryDate!.difference(scheduledDeliveryDate!).inDays;
  }

  double get resourceUtilization {
    // Calculate resource utilization as hours per technician
    if (techniciansAssigned.isEmpty) return 0.0;
    return totalLaborHours / techniciansAssigned.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'resolvedOnFirstCall': resolvedOnFirstCall ? 1 : 0,
      'callbackCount': callbackCount,
      'firstResponseTime': firstResponseTime?.millisecondsSinceEpoch,
      'resolutionTime': resolutionTime?.millisecondsSinceEpoch,
      'deliveredOnTime': deliveredOnTime ? 1 : 0,
      'scheduledDeliveryDate': scheduledDeliveryDate?.millisecondsSinceEpoch,
      'actualDeliveryDate': actualDeliveryDate?.millisecondsSinceEpoch,
      'delayReason': delayReason,
      'techniciansAssigned': techniciansAssigned.join(','),
      'totalLaborHours': totalLaborHours,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory TicketResolutionMetric.fromMap(Map<String, dynamic> map) {
    return TicketResolutionMetric(
      id: map['id'] ?? '',
      ticketId: map['ticketId'] ?? '',
      resolvedOnFirstCall: (map['resolvedOnFirstCall'] ?? 0) == 1,
      callbackCount: map['callbackCount'] ?? 0,
      firstResponseTime: map['firstResponseTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['firstResponseTime'])
          : null,
      resolutionTime: map['resolutionTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolutionTime'])
          : null,
      deliveredOnTime: (map['deliveredOnTime'] ?? 0) == 1,
      scheduledDeliveryDate: map['scheduledDeliveryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledDeliveryDate'])
          : null,
      actualDeliveryDate: map['actualDeliveryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['actualDeliveryDate'])
          : null,
      delayReason: map['delayReason'],
      techniciansAssigned: map['techniciansAssigned'] != null && map['techniciansAssigned'].toString().isNotEmpty
          ? map['techniciansAssigned'].toString().split(',')
          : [],
      totalLaborHours: (map['totalLaborHours'] ?? 0.0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  TicketResolutionMetric copyWith({
    String? id,
    String? ticketId,
    bool? resolvedOnFirstCall,
    int? callbackCount,
    DateTime? firstResponseTime,
    DateTime? resolutionTime,
    bool? deliveredOnTime,
    DateTime? scheduledDeliveryDate,
    DateTime? actualDeliveryDate,
    String? delayReason,
    List<String>? techniciansAssigned,
    double? totalLaborHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketResolutionMetric(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      resolvedOnFirstCall: resolvedOnFirstCall ?? this.resolvedOnFirstCall,
      callbackCount: callbackCount ?? this.callbackCount,
      firstResponseTime: firstResponseTime ?? this.firstResponseTime,
      resolutionTime: resolutionTime ?? this.resolutionTime,
      deliveredOnTime: deliveredOnTime ?? this.deliveredOnTime,
      scheduledDeliveryDate: scheduledDeliveryDate ?? this.scheduledDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      delayReason: delayReason ?? this.delayReason,
      techniciansAssigned: techniciansAssigned ?? this.techniciansAssigned,
      totalLaborHours: totalLaborHours ?? this.totalLaborHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
