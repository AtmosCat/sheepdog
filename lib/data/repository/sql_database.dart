import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sheepdog/data/repository/user_data_identity.dart';
import 'package:sqflite/sqflite.dart';

class SqlDatabase {
  static final SqlDatabase instance = SqlDatabase._init();
  static Database? _database;

  SqlDatabase._init();

  static const fileName = UserDataIdentity.sqliteFileName;
  static const schemaVersion = UserDataIdentity.sqliteSchemaVersion;

  /// 앱 시작 시 DB 연결을 새로 엽니다. 파일을 삭제하거나 비우지 않습니다.
  Future<void> reopen() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(fileName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _createDB,
      onUpgrade: migrate,
      onDowngrade: _keepDataOnDowngrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE subscription_services (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    logoUrl TEXT,
    emoji TEXT, 
    categoryId TEXT,
    paymentCycle INTEGER,
    paymentDate TEXT,
    paymentAmount INTEGER,
    paymentMethodId TEXT,
    memo TEXT NOT NULL,
    createdAt TEXT,
    paymentStartDate TEXT NOT NULL,
    isLastDayOfMonth INTEGER NOT NULL DEFAULT 0,
    isAmountUndetermined INTEGER NOT NULL DEFAULT 0
  )
''');

    await db.execute('''
    CREATE TABLE subscription_categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      colorValue INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE payment_methods (
      id TEXT PRIMARY KEY,
      serviceName TEXT,
      logoUrl TEXT,
      alias TEXT NOT NULL,
      memo TEXT NOT NULL,
      createdAt TEXT
    )
  ''');
  }

  /// Additive-only migrations. Never DROP/recreate tables.
  static Future<void> migrate(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _ensureColumn(
        db,
        'subscription_services',
        'isLastDayOfMonth',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await _ensureColumn(
        db,
        'subscription_services',
        'isAmountUndetermined',
        'INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  static Future<void> _keepDataOnDowngrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint(
      '[SqlDatabase] skip downgrade $oldVersion -> $newVersion; keep user rows',
    );
  }

  static Future<void> _ensureColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
