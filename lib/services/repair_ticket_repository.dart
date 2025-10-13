import 'package:intl/intl.dart';
import '../models/models.dart';
import 'database_service.dart';

class RepairTicketRepository {
  final DatabaseService _db = DatabaseService();

  static const String _tableName = 'repair_tickets';

  /// Generate ticket number in format: NA-DDMMYY###
  /// Example: NA-121025001
  Future<String> _generateTicketNumber(DateTime createdAt) async {
    // Format: NA-DDMMYY
    final dateFormat = DateFormat('ddMMyy');
    final datePrefix = 'NA-${dateFormat.format(createdAt)}';
    
    // Find all tickets created on the same day
    final startOfDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final existingTickets = await _db.select(
      _tableName,
      where: 'id LIKE ? AND createdAt >= ? AND createdAt < ?',
      whereArgs: [
        '$datePrefix%',
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );
    
    // Get the next sequence number
    int maxSequence = 0;
    for (var ticket in existingTickets) {
      final id = ticket['id'] as String;
      if (id.length >= 12) { // NA-DDMMYY### = 12 characters minimum
        final sequencePart = id.substring(9); // Get the ### part
        final sequence = int.tryParse(sequencePart) ?? 0;
        if (sequence > maxSequence) {
          maxSequence = sequence;
        }
      }
    }
    
    // Increment and format with leading zeros (3 digits)
    final nextSequence = (maxSequence + 1).toString().padLeft(3, '0');
    
    return '$datePrefix$nextSequence';
  }

  Future<String> create(RepairTicket ticket) async {
    final now = DateTime.now();
    final createdAt = ticket.createdAt == ticket.updatedAt ? now : ticket.createdAt;
    
    // Generate ticket number if ID is empty or is a UUID
    final id = ticket.id.isEmpty || ticket.id.contains('-') 
        ? await _generateTicketNumber(createdAt)
        : ticket.id;

    final ticketWithId = ticket.copyWith(
      id: id,
      createdAt: createdAt,
      updatedAt: now,
    );

    await _db.insert(_tableName, ticketWithId.toMap());
    return id;
  }

  Future<RepairTicket?> getById(String id) async {
    final results = await _db.select(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return RepairTicket.fromMap(results.first);
  }

  Future<List<RepairTicket>> getAll({
    String? searchQuery,
    RepairStatus? status,
    String? customerId,
    String? technicianId,
    int? limit,
    int? offset,
  }) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereConditions.add('(title LIKE ? OR description LIKE ?)');
      final query = '%$searchQuery%';
      whereArgs.addAll([query, query]);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status.name);
    }

    if (customerId != null) {
      whereConditions.add('customerId = ?');
      whereArgs.add(customerId);
    }

    if (technicianId != null) {
      whereConditions.add('technicianId = ?');
      whereArgs.add(technicianId);
    }

    final where = whereConditions.isEmpty
        ? null
        : whereConditions.join(' AND ');

    final results = await _db.select(
      _tableName,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => RepairTicket.fromMap(map)).toList();
  }

  Future<void> update(RepairTicket ticket) async {
    final updatedTicket = ticket.copyWith(updatedAt: DateTime.now());
    await _db.update(_tableName, updatedTicket.toMap(), 'id = ?', [ticket.id]);
  }

  Future<void> delete(String id) async {
    await _db.delete(_tableName, 'id = ?', [id]);
  }

  Future<int> getCount({
    RepairStatus? status,
    String? customerId,
    String? technicianId,
  }) async {
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status.name);
    }

    if (customerId != null) {
      whereConditions.add('customerId = ?');
      whereArgs.add(customerId);
    }

    if (technicianId != null) {
      whereConditions.add('technicianId = ?');
      whereArgs.add(technicianId);
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

  Future<List<RepairTicket>> getActiveTickets() async {
    final activeStatuses = RepairStatus.values
        .where((status) => status.isActive)
        .map((status) => "'${status.name}'")
        .join(',');

    final sql =
        '''
      SELECT * FROM $_tableName 
      WHERE status IN ($activeStatuses)
      ORDER BY priority DESC, createdAt ASC
    ''';

    final results = await _db.customQuery(sql);
    return results.map((map) => RepairTicket.fromMap(map)).toList();
  }

  Future<List<RepairTicket>> getOverdueTickets() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeStatuses = RepairStatus.values
        .where((status) => status.isActive)
        .map((status) => "'${status.name}'")
        .join(',');

    final sql =
        '''
      SELECT * FROM $_tableName 
      WHERE status IN ($activeStatuses) 
      AND estimatedCompletion IS NOT NULL 
      AND estimatedCompletion < ?
      ORDER BY estimatedCompletion ASC
    ''';

    final results = await _db.customQuery(sql, [now]);
    return results.map((map) => RepairTicket.fromMap(map)).toList();
  }

  Future<List<RepairTicket>> getTicketsByCustomer(String customerId) async {
    final results = await _db.select(
      _tableName,
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );

    return results.map((map) => RepairTicket.fromMap(map)).toList();
  }

  Future<List<RepairTicket>> getTicketsByTechnician(String technicianId) async {
    final results = await _db.select(
      _tableName,
      where: 'technicianId = ?',
      whereArgs: [technicianId],
      orderBy: 'createdAt DESC',
    );

    return results.map((map) => RepairTicket.fromMap(map)).toList();
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
}
