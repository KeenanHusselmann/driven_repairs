import 'package:uuid/uuid.dart';

class ShortUrl {
  final String id;
  final String shortCode;
  final String fullUrl;
  final String? ticketId;
  final String? customerId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int clickCount;

  ShortUrl({
    String? id,
    required this.shortCode,
    required this.fullUrl,
    this.ticketId,
    this.customerId,
    DateTime? createdAt,
    this.expiresAt,
    this.clickCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shortCode': shortCode,
      'fullUrl': fullUrl,
      'ticketId': ticketId,
      'customerId': customerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'clickCount': clickCount,
    };
  }

  factory ShortUrl.fromMap(Map<String, dynamic> map) {
    return ShortUrl(
      id: map['id'],
      shortCode: map['shortCode'],
      fullUrl: map['fullUrl'],
      ticketId: map['ticketId'],
      customerId: map['customerId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'])
          : null,
      clickCount: map['clickCount'] ?? 0,
    );
  }

  ShortUrl copyWith({
    String? id,
    String? shortCode,
    String? fullUrl,
    String? ticketId,
    String? customerId,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? clickCount,
  }) {
    return ShortUrl(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      fullUrl: fullUrl ?? this.fullUrl,
      ticketId: ticketId ?? this.ticketId,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      clickCount: clickCount ?? this.clickCount,
    );
  }
}
