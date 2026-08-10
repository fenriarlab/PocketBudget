import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import 'models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getCategories({CategoryType? type}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null
          ? null
          : [type == CategoryType.income ? 'INCOME' : 'EXPENSE'],
      orderBy: 'is_custom ASC, name ASC',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<void> addExpenseCategory(String name) async {
    final db = await _dbHelper.database;
    await db.insert(
      'categories',
      CategoryModel(
        id: 'cat_custom_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        icon: '🏷️',
        type: CategoryType.expense,
        isCustom: true,
      ).toMap(),
    );
  }

  Future<bool> deleteCategory(CategoryModel category) async {
    if (!category.isCustom) return false;
    final db = await _dbHelper.database;
    final usage = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM transactions WHERE category_id = ?',
          [category.id],
        )) ??
        0;
    if (usage > 0) return false;
    await db.delete('categories', where: 'id = ?', whereArgs: [category.id]);
    return true;
  }
}