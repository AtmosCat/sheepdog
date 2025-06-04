import 'package:sheepdog/data/model/subscription_service.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sqflite/sqflite.dart';

class SubscriptionServiceDao {
  Future<int> insert(SubscriptionService service) async {
    final db = await SqlDatabase.instance.database;
    return await db.insert(
      'subscription_services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(SubscriptionService service) async {
    final db = await SqlDatabase.instance.database;
    return await db.update(
      'subscription_services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await SqlDatabase.instance.database;
    return await db.delete(
      'subscription_services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SubscriptionService?> getById(String id) async {
    final db = await SqlDatabase.instance.database;
    final maps = await db.query(
      'subscription_services',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SubscriptionService.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SubscriptionService>> getAll() async {
    final db = await SqlDatabase.instance.database;
    final result = await db.query('subscription_services');
    return result.map((map) => SubscriptionService.fromMap(map)).toList();
  }
}