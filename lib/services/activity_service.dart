import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  // Log user activity
  Future<void> logActivity({
    required String userId,
    required String username,
    required UserRole userRole,
    required ActivityType activityType,
    required EntityType entityType,
    String? entityId,
    required String description,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final activity = ActivityLog(
        id: _uuid.v4(),
        userId: userId,
        username: username,
        userRole: userRole,
        activityType: activityType,
        entityType: entityType,
        entityId: entityId,
        description: description,
        metadata: metadata,
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
      );

      final db = await _db.database;
      await db.insert('activity_logs', activity.toMap());
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  // Get activity logs with filtering
  Future<List<ActivityLog>> getActivityLogs({
    String? userId,
    ActivityType? activityType,
    EntityType? entityType,
    String? entityId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _db.database;

      List<String> whereClause = [];
      List<dynamic> whereArgs = [];

      if (userId != null) {
        whereClause.add('userId = ?');
        whereArgs.add(userId);
      }

      if (activityType != null) {
        whereClause.add('activityType = ?');
        whereArgs.add(activityType.value);
      }

      if (entityType != null) {
        whereClause.add('entityType = ?');
        whereArgs.add(entityType.value);
      }

      if (entityId != null) {
        whereClause.add('entityId = ?');
        whereArgs.add(entityId);
      }

      if (startDate != null) {
        whereClause.add('timestamp >= ?');
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause.add('timestamp <= ?');
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final results = await db.query(
        'activity_logs',
        where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => ActivityLog.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting activity logs: $e');
      return [];
    }
  }

  // Get recent activities for dashboard
  Future<List<ActivityLog>> getRecentActivities({int limit = 10}) async {
    return getActivityLogs(limit: limit);
  }

  // Get all activities (for full activity log)
  Future<List<ActivityLog>> getAllActivities() async {
    return getActivityLogs(limit: 1000); // Get up to 1000 activities
  }

  // Get user's recent activities
  Future<List<ActivityLog>> getUserActivities(
    String userId, {
    int limit = 20,
  }) async {
    return getActivityLogs(userId: userId, limit: limit);
  }

  // Clean old activity logs (retention policy)
  Future<void> cleanOldLogs({int retentionDays = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final db = await _db.database;

      await db.delete(
        'activity_logs',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.millisecondsSinceEpoch],
      );
    } catch (e) {
      debugPrint('Error cleaning old logs: $e');
    }
  }

  // Get activity statistics
  Future<Map<String, int>> getActivityStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final db = await _db.database;

      List<String> whereClause = [];
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause.add('timestamp >= ?');
        whereArgs.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        whereClause.add('timestamp <= ?');
        whereArgs.add(endDate.millisecondsSinceEpoch);
      }

      final results = await db.query(
        'activity_logs',
        columns: ['activityType', 'COUNT(*) as count'],
        where: whereClause.isNotEmpty ? whereClause.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        groupBy: 'activityType',
      );

      final stats = <String, int>{};
      for (final result in results) {
        stats[result['activityType'] as String] = result['count'] as int;
      }

      return stats;
    } catch (e) {
      print('Error getting activity statistics: $e');
      return {};
    }
  }
}
