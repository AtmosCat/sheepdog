import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sheepdog/data/repository/user_data_identity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sheepdog_db_');
  });

  tearDown(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  test('패키지 ID와 DB 파일명은 고정이다', () {
    expect(
      UserDataIdentity.androidApplicationId,
      'com.middlenamestudio.sheepdog',
    );
    expect(UserDataIdentity.iosBundleId, 'com.middlenamestudio.sheepdog');
    expect(UserDataIdentity.sqliteFileName, 'sheepdog.db');
    expect(UserDataIdentity.notificationDbFileName, 'notification_history.db');
    expect(SqlDatabase.fileName, UserDataIdentity.sqliteFileName);
    expect(SqlDatabase.schemaVersion, UserDataIdentity.sqliteSchemaVersion);
  });

  test('Android applicationId가 바뀌지 않았다', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(
      gradle.contains(
        'applicationId = "${UserDataIdentity.androidApplicationId}"',
      ),
      isTrue,
    );
  });

  test('iOS bundle id가 바뀌지 않았다', () {
    final project = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(
      project.contains(
        'PRODUCT_BUNDLE_IDENTIFIER = ${UserDataIdentity.iosBundleId};',
      ),
      isTrue,
    );
  });

  test('lib에 사용자 기록을 지우는 API가 없다', () {
    final hits = <String>[];
    final forbidden = <RegExp, String>{
      RegExp(r'deleteDatabase\s*\('): 'deleteDatabase',
      RegExp(r'DROP\s+TABLE', caseSensitive: false): 'DROP TABLE',
      RegExp(r'onDatabaseDowngradeDelete'): 'onDatabaseDowngradeDelete',
      RegExp(r'prefs\.clear\s*\('): 'prefs.clear',
    };

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final entry in forbidden.entries) {
        if (entry.key.hasMatch(source)) {
          hits.add('${file.path}: ${entry.value}');
        }
      }
    }

    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  for (final fromVersion in [1, 2, 3]) {
    test('schema v$fromVersion → v${SqlDatabase.schemaVersion} 업그레이드 후에도 구독 기록이 남는다',
        () async {
      final path = p.join(tmp.path, 'upgrade_$fromVersion.db');
      final seed = await openDatabase(
        path,
        version: fromVersion,
        onCreate: (db, version) async {
          await _createLegacySchema(db, version);
        },
      );
      await _insertLegacyRows(seed, fromVersion);
      await seed.close();

      final upgraded = await openDatabase(
        path,
        version: SqlDatabase.schemaVersion,
        onCreate: (db, version) async {
          fail('기존 DB인데 onCreate가 호출되면 기록이 새로 만들어지고 이전 데이터는 사라진 것이다');
        },
        onUpgrade: SqlDatabase.migrate,
        onDowngrade: (db, oldVersion, newVersion) async {
          fail('다운그레이드 경로에서 데이터를 지우면 안 된다');
        },
      );

      final services = await upgraded.query('subscription_services');
      final categories = await upgraded.query('subscription_categories');
      final methods = await upgraded.query('payment_methods');

      expect(services, hasLength(1));
      expect(services.first['id'], 'keep-sub');
      expect(services.first['name'], '넷플릭스');
      expect(categories, hasLength(1));
      expect(categories.first['id'], 'keep-cat');
      expect(methods, hasLength(1));
      expect(methods.first['id'], 'keep-pay');

      final columns = await upgraded.rawQuery(
        'PRAGMA table_info(subscription_services)',
      );
      final names = columns.map((row) => row['name']).toSet();
      expect(names, contains('isLastDayOfMonth'));
      expect(names, contains('isAmountUndetermined'));
      expect(services.first['isLastDayOfMonth'], 0);
      expect(services.first['isAmountUndetermined'], 0);

      await upgraded.close();
    });
  }
}

Future<void> _createLegacySchema(Database db, int version) async {
  final lastDayColumn =
      version >= 2 ? ',\n    isLastDayOfMonth INTEGER NOT NULL DEFAULT 0' : '';
  final amountColumn = version >= 4
      ? ',\n    isAmountUndetermined INTEGER NOT NULL DEFAULT 0'
      : '';
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
    paymentStartDate TEXT NOT NULL$lastDayColumn$amountColumn
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

Future<void> _insertLegacyRows(Database db, int version) async {
  await db.insert('subscription_categories', {
    'id': 'keep-cat',
    'name': 'OTT',
    'colorValue': 0xFFFF0000,
  });
  await db.insert('payment_methods', {
    'id': 'keep-pay',
    'serviceName': '카드',
    'alias': '주카드',
    'memo': '',
  });
  final service = <String, Object?>{
    'id': 'keep-sub',
    'name': '넷플릭스',
    'memo': '',
    'paymentStartDate': '2024-01-01T00:00:00.000',
    'categoryId': 'keep-cat',
    'paymentMethodId': 'keep-pay',
    'paymentAmount': 17000,
  };
  if (version >= 2) {
    service['isLastDayOfMonth'] = 0;
  }
  if (version >= 4) {
    service['isAmountUndetermined'] = 0;
  }
  await db.insert('subscription_services', service);
}
