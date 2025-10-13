import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== Driven Repairs Database Debug Tool ===');
  print('');

  try {
    // Initialize database factory for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Get database path
    final databasesPath = await getDatabasesPath();
    print('Database directory: $databasesPath');

    // Check if directory exists
    final dbDir = Directory(databasesPath);
    if (await dbDir.exists()) {
      print('✓ Database directory exists');
    } else {
      print('✗ Database directory does not exist');
      print('  Attempting to create...');
      await dbDir.create(recursive: true);
      print('✓ Database directory created');
    }

    // Check database file
    final dbPath = join(databasesPath, 'driven_repairs.db');
    print('Database file path: $dbPath');

    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      final stat = await dbFile.stat();
      print('✓ Database file exists (${stat.size} bytes)');
    } else {
      print('✗ Database file does not exist');
    }

    // Try to open database
    print('');
    print('Attempting to open database...');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        print('Creating database tables...');
        // Create a simple test table
        await db.execute('''
          CREATE TABLE test_table (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        print('✓ Test table created');
      },
    );

    print('✓ Database opened successfully');

    // Test insert
    print('');
    print('Testing database operations...');
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('test_table', {'name': 'Test Entry', 'created_at': now});
    print('✓ Insert operation successful');

    // Test select
    final results = await db.query('test_table');
    print('✓ Select operation successful (${results.length} rows)');

    // Cleanup
    await db.delete('test_table', where: '1=1');
    await db.close();

    print('');
    print('🎉 All database operations completed successfully!');
    print('The database is working properly.');
  } catch (e, stackTrace) {
    print('');
    print('❌ ERROR: $e');
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Possible solutions:');
    print('1. Run the app as Administrator');
    print('2. Check Windows permissions for the AppData folder');
    print('3. Temporarily disable antivirus software');
    print('4. Check if the path contains special characters');
  }

  print('');
  print('Press any key to exit...');
  stdin.readLineSync();
}
