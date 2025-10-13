import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/short_url.dart';
import '../services/database_service.dart';

class ShortUrlProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<ShortUrl> _shortUrls = [];
  bool _isLoading = false;

  List<ShortUrl> get shortUrls => _shortUrls;
  bool get isLoading => _isLoading;

  // Generate a random short code
  String _generateShortCode({int length = 6}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Check if a short code already exists
  Future<bool> _shortCodeExists(String shortCode) async {
    final db = await _dbService.database;
    final result = await db.query(
      'short_urls',
      where: 'shortCode = ?',
      whereArgs: [shortCode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Generate a unique short code
  Future<String> _generateUniqueShortCode() async {
    String shortCode;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      shortCode = _generateShortCode();
      attempts++;
      if (attempts >= maxAttempts) {
        // If we can't find a unique 6-char code, try 7 chars
        shortCode = _generateShortCode(length: 7);
      }
    } while (await _shortCodeExists(shortCode) && attempts < maxAttempts * 2);

    return shortCode;
  }

  // Create a short URL
  Future<ShortUrl?> createShortUrl({
    required String fullUrl,
    String? ticketId,
    String? customerId,
    DateTime? expiresAt,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final shortCode = await _generateUniqueShortCode();
      final shortUrl = ShortUrl(
        shortCode: shortCode,
        fullUrl: fullUrl,
        ticketId: ticketId,
        customerId: customerId,
        expiresAt: expiresAt,
      );

      final db = await _dbService.database;
      await db.insert('short_urls', shortUrl.toMap());

      _shortUrls.add(shortUrl);
      
      _isLoading = false;
      notifyListeners();

      debugPrint('Created short URL: $shortCode for $fullUrl');
      return shortUrl;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error creating short URL: $e');
      return null;
    }
  }

  // Get short URL by code
  Future<ShortUrl?> getShortUrlByCode(String shortCode) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'short_urls',
        where: 'shortCode = ?',
        whereArgs: [shortCode],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final shortUrl = ShortUrl.fromMap(result.first);

      // Check if expired
      if (shortUrl.expiresAt != null &&
          shortUrl.expiresAt!.isBefore(DateTime.now())) {
        debugPrint('Short URL $shortCode has expired');
        return null;
      }

      // Increment click count
      await db.update(
        'short_urls',
        {'clickCount': shortUrl.clickCount + 1},
        where: 'id = ?',
        whereArgs: [shortUrl.id],
      );

      return shortUrl;
    } catch (e) {
      debugPrint('Error getting short URL: $e');
      return null;
    }
  }

  // Load all short URLs
  Future<void> loadShortUrls() async {
    try {
      _isLoading = true;
      notifyListeners();

      final db = await _dbService.database;
      final result = await db.query(
        'short_urls',
        orderBy: 'createdAt DESC',
      );

      _shortUrls = result.map((map) => ShortUrl.fromMap(map)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading short URLs: $e');
    }
  }

  // Delete expired short URLs
  Future<void> deleteExpiredUrls() async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.delete(
        'short_urls',
        where: 'expiresAt IS NOT NULL AND expiresAt < ?',
        whereArgs: [now],
      );

      await loadShortUrls();
      debugPrint('Deleted expired short URLs');
    } catch (e) {
      debugPrint('Error deleting expired URLs: $e');
    }
  }

  // Delete a short URL
  Future<void> deleteShortUrl(String id) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        'short_urls',
        where: 'id = ?',
        whereArgs: [id],
      );

      _shortUrls.removeWhere((url) => url.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting short URL: $e');
    }
  }

  // Get short URLs by ticket
  Future<List<ShortUrl>> getShortUrlsByTicket(String ticketId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'short_urls',
        where: 'ticketId = ?',
        whereArgs: [ticketId],
        orderBy: 'createdAt DESC',
      );

      return result.map((map) => ShortUrl.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting short URLs by ticket: $e');
      return [];
    }
  }

  // Get short URLs by customer
  Future<List<ShortUrl>> getShortUrlsByCustomer(String customerId) async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'short_urls',
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'createdAt DESC',
      );

      return result.map((map) => ShortUrl.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error getting short URLs by customer: $e');
      return [];
    }
  }
}
