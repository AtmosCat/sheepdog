import 'package:sheepdog/data/model/subscription_category.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sqflite/sqflite.dart';

class SubscriptionCategoryDao {
  Future<int> insert(SubscriptionCategory category) async {
    final db = await SqlDatabase.instance.database;
    return await db.insert(
      'subscription_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(SubscriptionCategory category) async {
    final db = await SqlDatabase.instance.database;
    return await db.update(
      'subscription_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await SqlDatabase.instance.database;
    return await db.delete(
      'subscription_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SubscriptionCategory?> getById(String? id) async {
    final db = await SqlDatabase.instance.database;
    final maps = await db.query(
      'subscription_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SubscriptionCategory.fromMap(maps.first);
    }
    return null;
  }

  Future<List<SubscriptionCategory>> getAll() async {
    final db = await SqlDatabase.instance.database;
    final result = await db.query('subscription_categories');
    return result.map((map) => SubscriptionCategory.fromMap(map)).toList();
  }
}