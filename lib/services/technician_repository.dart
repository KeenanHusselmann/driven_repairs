import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class TechnicianRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  static const String _tableName = 'technicians';

  Future<String> create(Technician technician) async {
    final id = technician.id.isEmpty ? _uuid.v4() : technician.id;
    final now = DateTime.now();

    final technicianWithId = technician.copyWith(
      id: id,
      createdAt: technician.createdAt == technician.updatedAt
          ? now
          : technician.createdAt,
      updatedAt: now,
    );

    await _db.insert(_tableName, technicianWithId.toMap());
    return id;
  }

  Future<Technician?> getById(String id) async {
    final results = await _db.select(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Technician.fromMap(results.first);
  }

  Future<List<Technician>> getAll({
    String? searchQuery,
    TechnicianStatus? status,
    int? limit,
    int? offset,
  }) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add(
        '(firstName LIKE ? OR lastName LIKE ? OR email LIKE ? OR skills LIKE ?)',
      );
      final query = '%$searchQuery%';
      whereArgs.addAll([query, query, query, query]);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status.name);
    }

    final where = whereConditions.isEmpty
        ? null
        : whereConditions.join(' AND ');

    final results = await _db.select(
      _tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'lastName, firstName',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => Technician.fromMap(map)).toList();
  }

  Future<void> update(Technician technician) async {
    final updatedTechnician = technician.copyWith(updatedAt: DateTime.now());
    await _db.update(_tableName, updatedTechnician.toMap(), 'id = ?', [
      technician.id,
    ]);
  }

  Future<void> delete(String id) async {
    await _db.delete(_tableName, 'id = ?', [id]);
  }

  Future<List<Technician>> getAvailableTechnicians() async {
    final results = await _db.select(
      _tableName,
      where: 'status = ?',
      whereArgs: [TechnicianStatus.active.name],
      orderBy: 'firstName, lastName',
    );

    return results.map((map) => Technician.fromMap(map)).toList();
  }

  Future<int> getCount({TechnicianStatus? status}) async {
    String sql = 'SELECT COUNT(*) as count FROM $_tableName';
    List<dynamic>? args;

    if (status != null) {
      sql += ' WHERE status = ?';
      args = [status.name];
    }

    final results = await _db.customQuery(sql, args);
    return results.first['count'] as int;
  }

  Future<Map<String, int>> getStatusCounts() async {
    final sql =
        '''
      SELECT status, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY status
    ''';

    final results = await _db.customQuery(sql);
    final Map<String, int> counts = {};

    for (final result in results) {
      counts[result['status'] as String] = result['count'] as int;
    }

    return counts;
  }

  Future<List<Map<String, dynamic>>> getTechnicianWorkload() async {
    final sql =
        '''
      SELECT 
        t.id,
        t.firstName,
        t.lastName,
        t.maxActiveTickets,
        COUNT(rt.id) as activeTickets,
        (t.maxActiveTickets - COUNT(rt.id)) as availableCapacity
      FROM $_tableName t
      LEFT JOIN repair_tickets rt ON t.id = rt.technicianId 
        AND rt.status IN ('pending', 'diagnosed', 'inProgress', 'waitingForParts', 'testing')
      WHERE t.status = 'active'
      GROUP BY t.id, t.firstName, t.lastName, t.maxActiveTickets
      ORDER BY availableCapacity DESC, t.firstName, t.lastName
    ''';

    return await _db.customQuery(sql);
  }

  Future<List<Technician>> getTechniciansBySkill(String skill) async {
    final results = await _db.select(
      _tableName,
      where: 'skills LIKE ? AND status = ?',
      whereArgs: ['%$skill%', TechnicianStatus.active.name],
      orderBy: 'firstName, lastName',
    );

    return results.map((map) => Technician.fromMap(map)).toList();
  }
}
