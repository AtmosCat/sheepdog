import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalNotificationRepository {
  static final LocalNotificationRepository _instance =
      LocalNotificationRepository._internal();
  factory LocalNotificationRepository() => _instance;
  LocalNotificationRepository._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notification_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            body TEXT,
            receivedAt TEXT,
            read INTEGER
          )
        ''');
      },
    );
  }

  /// 알림 내역 저장
  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    // 예: title+body+receivedAt 조합으로 중복 체크
    final existing = await db.query(
      'notifications',
      where: 'title = ? AND body = ? AND receivedAt = ?',
      whereArgs: [
        notification['title'],
        notification['body'],
        notification['receivedAt'],
      ],
    );
    if (existing.isEmpty) {
      await db.insert(
        'notifications',
        notification,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// 알림 내역 전체 조회 (최신순)
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    final db = await database;
    return await db.query('notifications', orderBy: 'receivedAt DESC');
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(int id) async {
    final db = await database;
    await db.update(
      'notifications',
      {'read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 알림 전체 삭제
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('notifications');
  }
}
