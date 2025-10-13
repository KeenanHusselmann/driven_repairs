class ServiceRating {
  final String id;
  final String ticketId;
  final String customerId;
  final int satisfactionRating; // 1-5 stars
  final int timelinessRating; // 1-5 stars
  final int communicationRating; // 1-5 stars
  final int qualityRating; // 1-5 stars
  final String? feedback;
  final bool wouldRecommend;
  final DateTime createdAt;

  ServiceRating({
    required this.id,
    required this.ticketId,
    required this.customerId,
    required this.satisfactionRating,
    required this.timelinessRating,
    required this.communicationRating,
    required this.qualityRating,
    this.feedback,
    required this.wouldRecommend,
    required this.createdAt,
  });

  double get averageRating {
    return (satisfactionRating + timelinessRating + communicationRating + qualityRating) / 4.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'customerId': customerId,
      'satisfactionRating': satisfactionRating,
      'timelinessRating': timelinessRating,
      'communicationRating': communicationRating,
      'qualityRating': qualityRating,
      'feedback': feedback,
      'wouldRecommend': wouldRecommend ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ServiceRating.fromMap(Map<String, dynamic> map) {
    return ServiceRating(
      id: map['id'] ?? '',
      ticketId: map['ticketId'] ?? '',
      customerId: map['customerId'] ?? '',
      satisfactionRating: map['satisfactionRating'] ?? 0,
      timelinessRating: map['timelinessRating'] ?? 0,
      communicationRating: map['communicationRating'] ?? 0,
      qualityRating: map['qualityRating'] ?? 0,
      feedback: map['feedback'],
      wouldRecommend: (map['wouldRecommend'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  ServiceRating copyWith({
    String? id,
    String? ticketId,
    String? customerId,
    int? satisfactionRating,
    int? timelinessRating,
    int? communicationRating,
    int? qualityRating,
    String? feedback,
    bool? wouldRecommend,
    DateTime? createdAt,
  }) {
    return ServiceRating(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      customerId: customerId ?? this.customerId,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      timelinessRating: timelinessRating ?? this.timelinessRating,
      communicationRating: communicationRating ?? this.communicationRating,
      qualityRating: qualityRating ?? this.qualityRating,
      feedback: feedback ?? this.feedback,
      wouldRecommend: wouldRecommend ?? this.wouldRecommend,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
