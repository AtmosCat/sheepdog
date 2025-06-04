import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqlDatabase {
  static final SqlDatabase instance = SqlDatabase._init();
  static Database? _database;

  SqlDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sheepdog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subscription_services (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        logoUrl TEXT,
        emoji TEXT, 
        categoryId TEXT NOT NULL,
        paymentCycle INTEGER,
        paymentDate TEXT,
        paymentAmount INTEGER,
        paymentMethodId TEXT NOT NULL,
        memo TEXT NOT NULL
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
        memo TEXT NOT NULL
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
