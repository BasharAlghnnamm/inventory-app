import 'package:sqflite_common/sqflite.dart';

import 'db_bootstrap.dart';
import 'db_path.dart';

/// Owns the SQLite database connection.
///
/// Backend is selected at compile time: `sqflite_common_ffi` on desktop,
/// the `sqflite` plugin on Android/iOS and `sqflite_common_ffi_web` on the
/// web. All share the same [databaseFactory] global.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    await bootstrapDatabaseFactory();

    final path = await resolveDbPath();
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    return db;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Inventory_Sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        column_config TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        image_path TEXT,
        cost_price REAL,
        selling_price REAL,
        batch_no TEXT,
        note TEXT,
        expiration_date TEXT,
        color TEXT,
        other_1 TEXT,
        other_2 TEXT,
        other_3 TEXT,
        other_4 TEXT,
        other_5 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Inventory_Items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (session_id) REFERENCES Inventory_Sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES Products (id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_items_session ON Inventory_Items (session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_items_product ON Inventory_Items (product_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Fresh installs use _onCreate; upgrades from any legacy schema are
    // dropped and recreated for simplicity at this stage.
    await db.execute('DROP TABLE IF EXISTS Inventory_Items');
    await db.execute('DROP TABLE IF EXISTS Products');
    await db.execute('DROP TABLE IF EXISTS Inventory_Sessions');
    await _onCreate(db, newVersion);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}