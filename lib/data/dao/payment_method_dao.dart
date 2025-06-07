import 'package:sheepdog/data/model/payment_method.dart';
import 'package:sheepdog/data/repository/sql_database.dart';
import 'package:sqflite/sqflite.dart';

class PaymentMethodDao {
  Future<int> insert(PaymentMethod method) async {
    final db = await SqlDatabase.instance.database;
    return await db.insert(
      'payment_methods',
      method.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(PaymentMethod method) async {
    final db = await SqlDatabase.instance.database;
    return await db.update(
      'payment_methods',
      method.toMap(),
      where: 'id = ?',
      whereArgs: [method.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await SqlDatabase.instance.database;
    return await db.delete(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<PaymentMethod?> getById(String? id) async {
    final db = await SqlDatabase.instance.database;
    final maps = await db.query(
      'payment_methods',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PaymentMethod.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PaymentMethod>> getAll() async {
    final db = await SqlDatabase.instance.database;
    final result = await db.query('payment_methods');
    return result.map((map) => PaymentMethod.fromMap(map)).toList();
  }
}