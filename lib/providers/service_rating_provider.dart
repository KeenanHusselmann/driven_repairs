import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/service_rating.dart';
import '../services/database_service.dart';

class ServiceRatingProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<ServiceRating> _ratings = [];
  bool _isLoading = false;

  List<ServiceRating> get ratings => _ratings;
  bool get isLoading => _isLoading;

  Future<void> loadRatings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbService.database;
      final maps = await db.query('service_ratings', orderBy: 'createdAt DESC');
      _ratings = maps.map((map) => ServiceRating.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading ratings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Import feedback from JSON files saved by the feedback server
  Future<int> importFeedbackFromFiles() async {
    int importedCount = 0;
    try {
      final feedbackDir = Directory('feedback_storage');
      
      // Check if directory exists
      if (!await feedbackDir.exists()) {
        debugPrint('Feedback storage directory does not exist');
        return 0;
      }

      // Get all JSON files
      final files = feedbackDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      if (files.isEmpty) {
        debugPrint('No feedback files to import');
        return 0;
      }

      debugPrint('Found ${files.length} feedback files to import');

      final db = await _dbService.database;
      
      for (final file in files) {
        try {
          // Read and parse JSON file
          final jsonString = await file.readAsString();
          final Map<String, dynamic> feedbackMap = jsonDecode(jsonString);
          
          // Check if this rating already exists in database
          final existing = await db.query(
            'service_ratings',
            where: 'id = ?',
            whereArgs: [feedbackMap['id']],
          );

          if (existing.isEmpty) {
            // Insert into database
            await db.insert('service_ratings', feedbackMap);
            importedCount++;
            debugPrint('✅ Imported feedback: ${feedbackMap['id']}');
          } else {
            debugPrint('⏭️  Feedback already exists: ${feedbackMap['id']}');
          }

          // Move file to imported folder to avoid re-importing
          final importedDir = Directory('feedback_storage/imported');
          if (!await importedDir.exists()) {
            await importedDir.create(recursive: true);
          }
          
          final fileName = file.uri.pathSegments.last;
          final newPath = 'feedback_storage/imported/$fileName';
          await file.rename(newPath);
          
        } catch (e) {
          debugPrint('⚠️  Error importing file ${file.path}: $e');
        }
      }

      // Reload ratings to reflect changes
      if (importedCount > 0) {
        await loadRatings();
        debugPrint('✅ Successfully imported $importedCount feedback items');
      }

    } catch (e) {
      debugPrint('Error importing feedback files: $e');
    }
    
    return importedCount;
  }

  Future<List<ServiceRating>> getRatingsForTicket(String ticketId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'service_ratings',
        where: 'ticketId = ?',
        whereArgs: [ticketId],
      );
      return maps.map((map) => ServiceRating.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading ratings for ticket: $e');
      return [];
    }
  }

  Future<List<ServiceRating>> getRatingsForCustomer(String customerId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        'service_ratings',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) => ServiceRating.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading ratings for customer: $e');
      return [];
    }
  }

  Future<ServiceRating?> createRating(ServiceRating rating) async {
    try {
      final newRating = ServiceRating(
        id: const Uuid().v4(),
        ticketId: rating.ticketId,
        customerId: rating.customerId,
        satisfactionRating: rating.satisfactionRating,
        timelinessRating: rating.timelinessRating,
        communicationRating: rating.communicationRating,
        qualityRating: rating.qualityRating,
        feedback: rating.feedback,
        wouldRecommend: rating.wouldRecommend,
        createdAt: DateTime.now(),
      );

      await _dbService.insert('service_ratings', newRating.toMap());
      _ratings.insert(0, newRating);
      notifyListeners();
      return newRating;
    } catch (e) {
      debugPrint('Error creating rating: $e');
      return null;
    }
  }

  Future<double> getAverageSatisfactionRating({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = 'SELECT AVG(satisfactionRating) as avg FROM service_ratings';
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
      debugPrint('Error calculating average satisfaction: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> getAllAverageRatings({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = '''
        SELECT 
          AVG(satisfactionRating) as satisfaction,
          AVG(timelinessRating) as timeliness,
          AVG(communicationRating) as communication,
          AVG(qualityRating) as quality
        FROM service_ratings
      ''';
      List<dynamic> args = [];
      
      if (since != null) {
        query += ' WHERE createdAt >= ?';
        args.add(since.millisecondsSinceEpoch);
      }

      final result = await db.rawQuery(query, args);
      if (result.isNotEmpty) {
        return {
          'satisfaction': (result.first['satisfaction'] as num?)?.toDouble() ?? 0.0,
          'timeliness': (result.first['timeliness'] as num?)?.toDouble() ?? 0.0,
          'communication': (result.first['communication'] as num?)?.toDouble() ?? 0.0,
          'quality': (result.first['quality'] as num?)?.toDouble() ?? 0.0,
        };
      }
      return {
        'satisfaction': 0.0,
        'timeliness': 0.0,
        'communication': 0.0,
        'quality': 0.0,
      };
    } catch (e) {
      debugPrint('Error calculating average ratings: $e');
      return {
        'satisfaction': 0.0,
        'timeliness': 0.0,
        'communication': 0.0,
        'quality': 0.0,
      };
    }
  }

  Future<int> getTotalRatingsCount({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = 'SELECT COUNT(*) as count FROM service_ratings';
      List<dynamic> args = [];
      
      if (since != null) {
        query += ' WHERE createdAt >= ?';
        args.add(since.millisecondsSinceEpoch);
      }

      final result = await db.rawQuery(query, args);
      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting ratings count: $e');
      return 0;
    }
  }

  Future<double> getRecommendationRate({DateTime? since}) async {
    try {
      final db = await _dbService.database;
      String query = '''
        SELECT 
          COUNT(CASE WHEN wouldRecommend = 1 THEN 1 END) * 100.0 / COUNT(*) as rate
        FROM service_ratings
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
      debugPrint('Error calculating recommendation rate: $e');
      return 0.0;
    }
  }
}
