import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDatabase {
  static final SqlDatabase instance = SqlDatabase._init();
  static Database? _database;

  SqlDatabase._init();

  /// 앱 시작 시 DB 연결을 새로 열어 마이그레이션이 반영되도록 합니다.
  Future<void> reopen() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sheepdog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
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

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
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

  Future<void> _ensureColumn(
    Database db,
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
