import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Initialize databaseFactory for desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // For Windows, explicitly use AppData/Local instead of letting sqflite choose
      String databasesPath;
      if (Platform.isWindows) {
        final appDataPath =
            Platform.environment['LOCALAPPDATA'] ??
            Platform.environment['APPDATA'] ??
            Directory.current.path;
        databasesPath = join(appDataPath, 'driven_repairs', 'databases');
      } else {
        databasesPath = await getDatabasesPath();
      }

      debugPrint('Database path: $databasesPath');

      // Ensure the directory exists
      final dbDir = Directory(databasesPath);
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
        debugPrint('Created database directory: $databasesPath');
      }

      final path = join(databasesPath, 'driven_repairs.db');
      debugPrint('Full database file path: $path');

      final db = await openDatabase(
        path,
        version: 4,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );

      debugPrint('Database opened successfully');
      return db;
    } catch (e, stackTrace) {
      debugPrint('Database initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Create Customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        address TEXT,
        city TEXT,
        state TEXT,
        zipCode TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create Technicians table
    await db.execute('''
      CREATE TABLE technicians (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        status TEXT NOT NULL,
        skills TEXT,
        certifications TEXT,
        hourlyRate REAL NOT NULL,
        maxActiveTickets INTEGER DEFAULT 5,
        notes TEXT,
        hireDate INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create Devices table
    await db.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        type TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        serialNumber TEXT,
        operatingSystem TEXT,
        specifications TEXT,
        purchaseDate INTEGER,
        warrantyExpiry INTEGER,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Create Parts table
    await db.execute('''
      CREATE TABLE parts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        partNumber TEXT,
        manufacturer TEXT,
        category TEXT,
        description TEXT,
        cost REAL NOT NULL,
        quantityInStock INTEGER NOT NULL DEFAULT 0,
        minimumStock INTEGER DEFAULT 0,
        supplier TEXT,
        location TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create Repair Tickets table
    await db.execute('''
      CREATE TABLE repair_tickets (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        deviceId TEXT NOT NULL,
        technicianId TEXT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        priority TEXT NOT NULL,
        estimatedCost REAL,
        finalCost REAL,
        estimatedCompletion INTEGER,
        actualCompletion INTEGER,
        diagnosis TEXT,
        resolution TEXT,
        notes TEXT,
        parts TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id),
        FOREIGN KEY (deviceId) REFERENCES devices (id),
        FOREIGN KEY (technicianId) REFERENCES technicians (id)
      )
    ''');

    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        passwordHash TEXT NOT NULL,
        profileImageUrl TEXT,
        phone TEXT,
        department TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        lastLoginAt INTEGER,
        createdBy TEXT
      )
    ''');

    // Create Activity Logs table
    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        username TEXT NOT NULL,
        userRole TEXT NOT NULL,
        activityType TEXT NOT NULL,
        entityType TEXT NOT NULL,
        entityId TEXT,
        description TEXT NOT NULL,
        metadata TEXT,
        ipAddress TEXT,
        userAgent TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Create Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'MEDIUM',
        userId TEXT,
        fromUserId TEXT,
        fromUsername TEXT,
        targetRole TEXT,
        entityType TEXT,
        entityId TEXT,
        actionData TEXT,
        isRead INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        readAt INTEGER,
        expiresAt INTEGER
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_devices_customer ON devices(customerId)',
    );
    await db.execute(
      'CREATE INDEX idx_tickets_customer ON repair_tickets(customerId)',
    );
    await db.execute(
      'CREATE INDEX idx_tickets_device ON repair_tickets(deviceId)',
    );
    await db.execute(
      'CREATE INDEX idx_tickets_technician ON repair_tickets(technicianId)',
    );
    await db.execute(
      'CREATE INDEX idx_tickets_status ON repair_tickets(status)',
    );
    await db.execute('CREATE INDEX idx_parts_category ON parts(category)');

    // New table indexes
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');
    await db.execute('CREATE INDEX idx_users_status ON users(status)');
    await db.execute(
      'CREATE INDEX idx_activity_logs_user ON activity_logs(userId)',
    );
    await db.execute(
      'CREATE INDEX idx_activity_logs_timestamp ON activity_logs(timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_activity_logs_entity ON activity_logs(entityType, entityId)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_user ON notifications(userId)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_read ON notifications(isRead)',
    );
    await db.execute(
      'CREATE INDEX idx_notifications_created ON notifications(createdAt)',
    );

    // Create Service Ratings table
    await db.execute('''
      CREATE TABLE service_ratings (
        id TEXT PRIMARY KEY,
        ticketId TEXT NOT NULL,
        customerId TEXT NOT NULL,
        satisfactionRating INTEGER NOT NULL,
        timelinessRating INTEGER NOT NULL,
        communicationRating INTEGER NOT NULL,
        qualityRating INTEGER NOT NULL,
        feedback TEXT,
        wouldRecommend INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (ticketId) REFERENCES repair_tickets (id),
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Create Ticket Resolution Metrics table
    await db.execute('''
      CREATE TABLE ticket_resolution_metrics (
        id TEXT PRIMARY KEY,
        ticketId TEXT NOT NULL,
        resolvedOnFirstCall INTEGER NOT NULL,
        callbackCount INTEGER NOT NULL,
        firstResponseTime INTEGER,
        resolutionTime INTEGER,
        deliveredOnTime INTEGER NOT NULL,
        scheduledDeliveryDate INTEGER,
        actualDeliveryDate INTEGER,
        delayReason TEXT,
        techniciansAssigned TEXT,
        totalLaborHours REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (ticketId) REFERENCES repair_tickets (id)
      )
    ''');

    // Create Short URLs table
    await db.execute('''
      CREATE TABLE short_urls (
        id TEXT PRIMARY KEY,
        shortCode TEXT NOT NULL UNIQUE,
        fullUrl TEXT NOT NULL,
        ticketId TEXT,
        customerId TEXT,
        createdAt INTEGER NOT NULL,
        expiresAt INTEGER,
        clickCount INTEGER DEFAULT 0,
        FOREIGN KEY (ticketId) REFERENCES repair_tickets (id),
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Create indexes for new tables
    await db.execute(
      'CREATE INDEX idx_service_ratings_ticket ON service_ratings(ticketId)',
    );
    await db.execute(
      'CREATE INDEX idx_service_ratings_customer ON service_ratings(customerId)',
    );
    await db.execute(
      'CREATE INDEX idx_resolution_metrics_ticket ON ticket_resolution_metrics(ticketId)',
    );
    await db.execute(
      'CREATE INDEX idx_short_urls_code ON short_urls(shortCode)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables for version 2
      debugPrint('Upgrading database from version $oldVersion to $newVersion');

      // Create Users table
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          firstName TEXT NOT NULL,
          lastName TEXT NOT NULL,
          role TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          passwordHash TEXT NOT NULL,
          profileImageUrl TEXT,
          phone TEXT,
          department TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          lastLoginAt INTEGER,
          createdBy TEXT
        )
      ''');

      // Create Activity Logs table
      await db.execute('''
        CREATE TABLE activity_logs (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          username TEXT NOT NULL,
          userRole TEXT NOT NULL,
          activityType TEXT NOT NULL,
          entityType TEXT NOT NULL,
          entityId TEXT,
          description TEXT NOT NULL,
          metadata TEXT,
          ipAddress TEXT,
          userAgent TEXT,
          timestamp INTEGER NOT NULL
        )
      ''');

      // Create Notifications table
      await db.execute('''
        CREATE TABLE notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          priority TEXT NOT NULL DEFAULT 'MEDIUM',
          userId TEXT,
          fromUserId TEXT,
          fromUsername TEXT,
          targetRole TEXT,
          entityType TEXT,
          entityId TEXT,
          actionData TEXT,
          isRead INTEGER NOT NULL DEFAULT 0,
          isArchived INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          readAt INTEGER,
          expiresAt INTEGER
        )
      ''');

      // Create indexes for new tables
      await db.execute('CREATE INDEX idx_users_username ON users(username)');
      await db.execute('CREATE INDEX idx_users_role ON users(role)');
      await db.execute('CREATE INDEX idx_users_status ON users(status)');
      await db.execute(
        'CREATE INDEX idx_activity_logs_user ON activity_logs(userId)',
      );
      await db.execute(
        'CREATE INDEX idx_activity_logs_timestamp ON activity_logs(timestamp)',
      );
      await db.execute(
        'CREATE INDEX idx_activity_logs_entity ON activity_logs(entityType, entityId)',
      );
      await db.execute(
        'CREATE INDEX idx_notifications_user ON notifications(userId)',
      );
      await db.execute(
        'CREATE INDEX idx_notifications_read ON notifications(isRead)',
      );
      await db.execute(
        'CREATE INDEX idx_notifications_created ON notifications(createdAt)',
      );
    }

    if (oldVersion < 3) {
      // Add performance tracking tables for version 3
      debugPrint('Adding performance tracking tables...');

      // Create Service Ratings table
      await db.execute('''
        CREATE TABLE service_ratings (
          id TEXT PRIMARY KEY,
          ticketId TEXT NOT NULL,
          customerId TEXT NOT NULL,
          satisfactionRating INTEGER NOT NULL,
          timelinessRating INTEGER NOT NULL,
          communicationRating INTEGER NOT NULL,
          qualityRating INTEGER NOT NULL,
          feedback TEXT,
          wouldRecommend INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (ticketId) REFERENCES repair_tickets (id),
          FOREIGN KEY (customerId) REFERENCES customers (id)
        )
      ''');

      // Create Ticket Resolution Metrics table
      await db.execute('''
        CREATE TABLE ticket_resolution_metrics (
          id TEXT PRIMARY KEY,
          ticketId TEXT NOT NULL,
          resolvedOnFirstCall INTEGER NOT NULL,
          callbackCount INTEGER NOT NULL,
          firstResponseTime INTEGER,
          resolutionTime INTEGER,
          deliveredOnTime INTEGER NOT NULL,
          scheduledDeliveryDate INTEGER,
          actualDeliveryDate INTEGER,
          delayReason TEXT,
          techniciansAssigned TEXT,
          totalLaborHours REAL NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY (ticketId) REFERENCES repair_tickets (id)
        )
      ''');

      // Create indexes for new tables
      await db.execute(
        'CREATE INDEX idx_service_ratings_ticket ON service_ratings(ticketId)',
      );
      await db.execute(
        'CREATE INDEX idx_service_ratings_customer ON service_ratings(customerId)',
      );
      await db.execute(
        'CREATE INDEX idx_resolution_metrics_ticket ON ticket_resolution_metrics(ticketId)',
      );

      debugPrint('Performance tracking tables created successfully');
    }

    if (oldVersion < 4) {
      // Add short_urls table for version 4
      debugPrint('Upgrading database to version 4: Adding short URLs table');

      await db.execute('''
        CREATE TABLE short_urls (
          id TEXT PRIMARY KEY,
          shortCode TEXT NOT NULL UNIQUE,
          fullUrl TEXT NOT NULL,
          ticketId TEXT,
          customerId TEXT,
          createdAt INTEGER NOT NULL,
          expiresAt INTEGER,
          clickCount INTEGER DEFAULT 0,
          FOREIGN KEY (ticketId) REFERENCES repair_tickets (id),
          FOREIGN KEY (customerId) REFERENCES customers (id)
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_short_urls_code ON short_urls(shortCode)',
      );

      debugPrint('Short URLs table created successfully');
    }

    debugPrint('Database upgrade completed successfully');
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> select(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table,
    String where,
    List<dynamic> whereArgs,
  ) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Custom queries for complex operations
  Future<List<Map<String, dynamic>>> customQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> customExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  // Get the database file path for backup/restore operations
  Future<String> getDatabasePath() async {
    String databasesPath;
    if (Platform.isWindows) {
      final appDataPath =
          Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.current.path;
      databasesPath = join(appDataPath, 'driven_repairs', 'databases');
    } else {
      databasesPath = await getDatabasesPath();
    }

    return join(databasesPath, 'driven_repairs.db');
  }
}
