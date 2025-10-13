import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class PartRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  static const String _tableName = 'parts';

  Future<String> create(Part part) async {
    final id = part.id.isEmpty ? _uuid.v4() : part.id;
    final now = DateTime.now();

    final partWithId = part.copyWith(
      id: id,
      createdAt: part.createdAt == part.updatedAt ? now : part.createdAt,
      updatedAt: now,
    );

    await _db.insert(_tableName, partWithId.toMap());
    return id;
  }

  Future<Part?> getById(String id) async {
    final results = await _db.select(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Part.fromMap(results.first);
  }

  Future<List<Part>> getAll({
    String? searchQuery,
    String? category,
    bool? lowStock,
    int? limit,
    int? offset,
  }) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add(
        '(name LIKE ? OR partNumber LIKE ? OR manufacturer LIKE ?)',
      );
      final query = '%$searchQuery%';
      whereArgs.addAll([query, query, query]);
    }

    if (category != null && category.isNotEmpty) {
      whereConditions.add('category = ?');
      whereArgs.add(category);
    }

    if (lowStock == true) {
      whereConditions.add('quantityInStock <= minimumStock');
    }

    final where = whereConditions.isEmpty
        ? null
        : whereConditions.join(' AND ');

    final results = await _db.select(
      _tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => Part.fromMap(map)).toList();
  }

  Future<void> update(Part part) async {
    final updatedPart = part.copyWith(updatedAt: DateTime.now());
    await _db.update(_tableName, updatedPart.toMap(), 'id = ?', [part.id]);
  }

  Future<void> delete(String id) async {
    await _db.delete(_tableName, 'id = ?', [id]);
  }

  Future<void> updateStock(String partId, int newQuantity) async {
    await _db.update(
      _tableName,
      {
        'quantityInStock': newQuantity,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      'id = ?',
      [partId],
    );
  }

  Future<void> adjustStock(String partId, int adjustment) async {
    final part = await getById(partId);
    if (part != null) {
      final newQuantity = part.quantityInStock + adjustment;
      await updateStock(partId, newQuantity);
    }
  }

  Future<List<Part>> getLowStockParts() async {
    final results = await _db.select(
      _tableName,
      where: 'quantityInStock <= minimumStock',
      orderBy: 'quantityInStock ASC, name',
    );

    return results.map((map) => Part.fromMap(map)).toList();
  }

  Future<List<Part>> getOutOfStockParts() async {
    final results = await _db.select(
      _tableName,
      where: 'quantityInStock <= 0',
      orderBy: 'name',
    );

    return results.map((map) => Part.fromMap(map)).toList();
  }

  Future<List<String>> getCategories() async {
    final results = await _db.customQuery('''
      SELECT DISTINCT category 
      FROM $_tableName 
      WHERE category IS NOT NULL AND category != ''
      ORDER BY category
    ''');

    return results.map((row) => row['category'] as String).toList();
  }

  Future<int> getCount({String? category, bool? lowStock}) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (category != null && category.isNotEmpty) {
      whereConditions.add('category = ?');
      whereArgs.add(category);
    }

    if (lowStock == true) {
      whereConditions.add('quantityInStock <= minimumStock');
    }

    final where = whereConditions.isEmpty
        ? ''
        : ' WHERE ${whereConditions.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM $_tableName$where';

    final results = await _db.customQuery(
      sql,
      whereArgs.isEmpty ? null : whereArgs,
    );
    return results.first['count'] as int;
  }

  Future<Map<String, int>> getCategoryCounts() async {
    final sql =
        '''
      SELECT 
        COALESCE(category, 'Uncategorized') as category, 
        COUNT(*) as count 
      FROM $_tableName 
      GROUP BY category
      ORDER BY count DESC
    ''';

    final results = await _db.customQuery(sql);
    final Map<String, int> counts = {};

    for (final result in results) {
      counts[result['category'] as String] = result['count'] as int;
    }

    return counts;
  }

  Future<double> getTotalInventoryValue() async {
    final results = await _db.customQuery('''
      SELECT SUM(cost * quantityInStock) as totalValue 
      FROM $_tableName
    ''');

    return (results.first['totalValue'] as num?)?.toDouble() ?? 0.0;
  }
}
