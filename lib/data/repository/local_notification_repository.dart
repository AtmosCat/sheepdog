import 'package:path/path.dart';
import 'package:sheepdog/data/repository/user_data_identity.dart';
import 'package:sqflite/sqflite.dart';

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
    final path = join(dbPath, UserDataIdentity.notificationDbFileName);
    return await openDatabase(
      path,
      version: 1,
      onUpgrade: (db, oldVersion, newVersion) async {},
      onDowngrade: (db, oldVersion, newVersion) async {},
      onCreate: (db, version) async {
        await db.execute('''
  CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    body TEXT,
    type TEXT,
    nextNotifyDate TEXT,
    messageId TEXT,
    receivedAt TEXT,
    read INTEGER
  )
''');
      },
    );
  }

  Future<void> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    // [수정] messageId가 있으면 그것으로, 없으면 type+title+body+nextNotifyDate로 중복 체크
    String where;
    List whereArgs;
    if ((notification['messageId'] ?? '').toString().isNotEmpty) {
      where = 'messageId = ?';
      whereArgs = [notification['messageId']];
    } else {
      where = 'type = ? AND title = ? AND body = ? AND nextNotifyDate = ?';
      whereArgs = [
        notification['type'] ?? '',
        notification['title'] ?? '',
        notification['body'] ?? '',
        notification['nextNotifyDate'] ?? '',
      ];
    }
    final existing = await db.query(
      'notifications',
      where: where,
      whereArgs: whereArgs,
    );
    if (existing.isEmpty) {
      await db.insert(
        'notifications',
        notification,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      print(
        '[알림] 중복 알림 저장 시도 차단: ${notification['title']} / ${notification['type']} / ${notification['nextNotifyDate']}',
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
