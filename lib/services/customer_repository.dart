import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class CustomerRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  static const String _tableName = 'customers';

  Future<String> create(Customer customer) async {
    try {
      final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
      final now = DateTime.now();

      final customerWithId = customer.copyWith(
        id: id,
        createdAt: customer.createdAt == customer.updatedAt
            ? now
            : customer.createdAt,
        updatedAt: now,
      );

      debugPrint('Attempting to insert customer: ${customerWithId.toMap()}');
      await _db.insert(_tableName, customerWithId.toMap());
      debugPrint('Customer created successfully with ID: $id');
      return id;
    } catch (e, stackTrace) {
      debugPrint('Customer repository create error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Customer?> getById(String id) async {
    final results = await _db.select(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Customer.fromMap(results.first);
  }

  Future<List<Customer>> getAll({
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where =
          'firstName LIKE ? OR lastName LIKE ? OR email LIKE ? OR phone LIKE ?';
      final query = '%$searchQuery%';
      whereArgs = [query, query, query, query];
    }

    final results = await _db.select(
      _tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'lastName, firstName',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => Customer.fromMap(map)).toList();
  }

  Future<void> update(Customer customer) async {
    final updatedCustomer = customer.copyWith(updatedAt: DateTime.now());
    await _db.update(_tableName, updatedCustomer.toMap(), 'id = ?', [
      customer.id,
    ]);
  }

  Future<void> delete(String id) async {
    await _db.delete(_tableName, 'id = ?', [id]);
  }

  Future<int> getCount({String? searchQuery}) async {
    String sql = 'SELECT COUNT(*) as count FROM $_tableName';
    List<dynamic>? args;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      sql +=
          ' WHERE firstName LIKE ? OR lastName LIKE ? OR email LIKE ? OR phone LIKE ?';
      final query = '%$searchQuery%';
      args = [query, query, query, query];
    }

    final results = await _db.customQuery(sql, args);
    return results.first['count'] as int;
  }

  Future<List<Customer>> getRecentCustomers({int limit = 10}) async {
    final results = await _db.select(
      _tableName,
      orderBy: 'createdAt DESC',
      limit: limit,
    );

    return results.map((map) => Customer.fromMap(map)).toList();
  }
}
