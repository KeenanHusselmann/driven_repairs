import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_resolution_metric.dart';
import '../services/database_service.dart';

class TicketResolutionMetricProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<TicketResolutionMetric> _metrics = [];
  bool _isLoading = false;

  List<TicketResolutionMetric> get metrics => _metrics;
  bool get isLoading => _isLoading;

  Future<void> loadMetrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      final maps = await db.query('ticket_resolution_metrics', orderBy: 'createdAt DESC');
      _metrics = maps.map((map) => TicketResolutionMetric.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading metrics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TicketResolutionMetric?> getMetricForTicket(String ticketId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'ticket_resolution_metrics',
        where: 'ticketId = ?',
        whereArgs: [ticketId],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return TicketResolutionMetric.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading metric for ticket: $e');
      return null;
    }
  }

  Future<TicketResolutionMetric?> createMetric(TicketResolutionMetric metric) async {
    try {
      final now = DateTime.now();
      final newMetric = TicketResolutionMetric(
        id: const Uuid().v4(),
        ticketId: metric.ticketId,
        resolvedOnFirstCall: metric.resolvedOnFirstCall,
        callbackCount: metric.callbackCount,
        firstResponseTime: metric.firstResponseTime,
        resolutionTime: metric.resolutionTime,
        deliveredOnTime: metric.deliveredOnTime,
        scheduledDeliveryDate: metric.scheduledDeliveryDate,
        actualDeliveryDate: metric.actualDeliveryDate,
        delayReason: metric.delayReason,
        techniciansAssigned: metric.techniciansAssigned,
        totalLaborHours: metric.totalLaborHours,
        createdAt: now,
        updatedAt: now,
      );

      await _dbService.insert('ticket_resolution_metrics', newMetric.toMap());
      _metrics.insert(0, newMetric);
      notifyListeners();
      return newMetric;
    } catch (e) {
      debugPrint('Error creating metric: $e');
      return null;
    }
  }

  Future<bool> updateMetric(TicketResolutionMetric metric) async {
    try {
      final updatedMetric = metric.copyWith(updatedAt: DateTime.now());
      
      final db = await _dbService.database;
      await db.update(
        'ticket_resolution_metrics',
        updatedMetric.toMap(),
        where: 'id = ?',
        whereArgs: [updatedMetric.id],
      );

      final index = _metrics.indexWhere((m) => m.id == updatedMetric.id);
      if (index != -1) {
        _metrics[index] = updatedMetric;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating metric: $e');
      return false;
    }
  }

  // Performance Metrics Calculations

  Future<double> getOnTimeDeliveryRate({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = '''
        SELECT 
          COUNT(CASE WHEN deliveredOnTime = 1 THEN 1 END) * 100.0 / COUNT(*) as rate
        FROM ticket_resolution_metrics
      ''';
      List<dynamic> args = [];
      
      if (since != null) {
        query += ' WHERE createdAt >= ?';
        args.add(since.millisecondsSinceEpoch);
      }

      final result = await db.rawQuery(query, args);
      if (result.isNotEmpty && result.first['rate'] != null) {
        return (result.first['rate'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating on-time delivery rate: $e');
      return 0.0;
    }
  }

  Future<double> getFirstCallResolutionRate({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = '''
        SELECT 
          COUNT(CASE WHEN resolvedOnFirstCall = 1 THEN 1 END) * 100.0 / COUNT(*) as rate
        FROM ticket_resolution_metrics
      ''';
      List<dynamic> args = [];
      
      if (since != null) {
        query += ' WHERE createdAt >= ?';
        args.add(since.millisecondsSinceEpoch);
      }

      final result = await db.rawQuery(query, args);
      if (result.isNotEmpty && result.first['rate'] != null) {
        return (result.first['rate'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating first call resolution rate: $e');
      return 0.0;
    }
  }

  Future<double> getAverageResourceUtilization({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = 'SELECT AVG(totalLaborHours) as avg FROM ticket_resolution_metrics';
      List<dynamic> args = [];
      
      if (since != null) {
        query += ' WHERE createdAt >= ?';
        args.add(since.millisecondsSinceEpoch);
      }

      final result = await db.rawQuery(query, args);
      if (result.isNotEmpty && result.first['avg'] != null) {
        return (result.first['avg'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating average resource utilization: $e');
      return 0.0;
    }
  }

  Future<double> getAverageCallbackCount({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = 'SELECT AVG(callbackCount) as avg FROM ticket_resolution_metrics';
      List<dynamic> args = [];
      
      if (since != null) {
        query += ' WHERE createdAt >= ?';
        args.add(since.millisecondsSinceEpoch);
      }

      final result = await db.rawQuery(query, args);
      if (result.isNotEmpty && result.first['avg'] != null) {
        return (result.first['avg'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      debugPrint('Error calculating average callback count: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getComprehensiveMetrics({DateTime? since}) async {
    try {
      final onTimeRate = await getOnTimeDeliveryRate(since: since);
      final fcrRate = await getFirstCallResolutionRate(since: since);
      final avgUtilization = await getAverageResourceUtilization(since: since);
      final avgCallbacks = await getAverageCallbackCount(since: since);

      return {
        'onTimeDeliveryRate': onTimeRate,
        'firstCallResolutionRate': fcrRate,
        'averageResourceUtilization': avgUtilization,
        'averageCallbackCount': avgCallbacks,
      };
    } catch (e) {
      debugPrint('Error getting comprehensive metrics: $e');
      return {
        'onTimeDeliveryRate': 0.0,
        'firstCallResolutionRate': 0.0,
        'averageResourceUtilization': 0.0,
        'averageCallbackCount': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTrendData({
    required DateTime startDate,
    required DateTime endDate,
    String interval = 'day', // 'day', 'week', 'month'
  }) async {
    try {
      final db = await _dbService.database;
      
      // Group by time interval
      String dateFormat;
      switch (interval) {
        case 'week':
          dateFormat = '%Y-W%W';
          break;
        case 'month':
          dateFormat = '%Y-%m';
          break;
        default:
          dateFormat = '%Y-%m-%d';
      }

      final query = '''
        SELECT 
          strftime('$dateFormat', datetime(createdAt/1000, 'unixepoch')) as period,
          COUNT(*) as total,
          COUNT(CASE WHEN deliveredOnTime = 1 THEN 1 END) * 100.0 / COUNT(*) as onTimeRate,
          COUNT(CASE WHEN resolvedOnFirstCall = 1 THEN 1 END) * 100.0 / COUNT(*) as fcrRate,
          AVG(totalLaborHours) as avgUtilization,
          AVG(callbackCount) as avgCallbacks
        FROM ticket_resolution_metrics
        WHERE createdAt >= ? AND createdAt <= ?
        GROUP BY period
        ORDER BY period ASC
      ''';

      final result = await db.rawQuery(query, [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ]);

      return result.map((row) => {
        'period': row['period'] as String,
        'total': row['total'] as int,
        'onTimeRate': (row['onTimeRate'] as num?)?.toDouble() ?? 0.0,
        'fcrRate': (row['fcrRate'] as num?)?.toDouble() ?? 0.0,
        'avgUtilization': (row['avgUtilization'] as num?)?.toDouble() ?? 0.0,
        'avgCallbacks': (row['avgCallbacks'] as num?)?.toDouble() ?? 0.0,
      }).toList();
    } catch (e) {
      debugPrint('Error getting trend data: $e');
      return [];
    }
  }
}
