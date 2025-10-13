import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class DeviceRepository {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  static const String _tableName = 'devices';

  Future<String> create(Device device) async {
    final id = device.id.isEmpty ? _uuid.v4() : device.id;
    final now = DateTime.now();

    final deviceWithId = device.copyWith(
      id: id,
      createdAt: device.createdAt == device.updatedAt ? now : device.createdAt,
      updatedAt: now,
    );

    await _db.insert(_tableName, deviceWithId.toMap());
    return id;
  }

  Future<Device?> getById(String id) async {
    final results = await _db.select(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return Device.fromMap(results.first);
  }

  Future<List<Device>> getAll({
    String? searchQuery,
    String? customerId,
    DeviceType? type,
    int? limit,
    int? offset,
  }) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add(
        '(brand LIKE ? OR model LIKE ? OR serialNumber LIKE ?)',
      );
      final query = '%$searchQuery%';
      whereArgs.addAll([query, query, query]);
    }

    if (customerId != null) {
      whereConditions.add('customerId = ?');
      whereArgs.add(customerId);
    }

    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type.name);
    }

    final where = whereConditions.isEmpty
        ? null
        : whereConditions.join(' AND ');

    final results = await _db.select(
      _tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'brand, model',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => Device.fromMap(map)).toList();
  }

  Future<void> update(Device device) async {
    final updatedDevice = device.copyWith(updatedAt: DateTime.now());
    await _db.update(_tableName, updatedDevice.toMap(), 'id = ?', [device.id]);
  }

  Future<void> delete(String id) async {
    await _db.delete(_tableName, 'id = ?', [id]);
  }

  Future<List<Device>> getDevicesByCustomer(String customerId) async {
    final results = await _db.select(
      _tableName,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'brand, model',
    );

    return results.map((map) => Device.fromMap(map)).toList();
  }

  Future<int> getCount({String? customerId, DeviceType? type}) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (customerId != null) {
      whereConditions.add('customerId = ?');
      whereArgs.add(customerId);
    }

    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type.name);
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

  Future<Map<String, int>> getDeviceTypeStats() async {
    final sql =
        '''
      SELECT type, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY type
      ORDER BY count DESC
    ''';

    final results = await _db.customQuery(sql);
    final Map<String, int> stats = {};

    for (final result in results) {
      stats[result['type'] as String] = result['count'] as int;
    }

    return stats;
  }

  Future<List<Device>> getDevicesUnderWarranty() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final results = await _db.select(
      _tableName,
      where: 'warrantyExpiry IS NOT NULL AND warrantyExpiry > ?',
      whereArgs: [now],
      orderBy: 'warrantyExpiry ASC',
    );

    return results.map((map) => Device.fromMap(map)).toList();
  }

  Future<List<Device>> getDevicesWithExpiredWarranty() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final results = await _db.select(
      _tableName,
      where: 'warrantyExpiry IS NOT NULL AND warrantyExpiry <= ?',
      whereArgs: [now],
      orderBy: 'warrantyExpiry DESC',
    );

    return results.map((map) => Device.fromMap(map)).toList();
  }
}
