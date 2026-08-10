import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import 'models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<CategoryModel>> getCategories({CategoryType? type}) async {
    final db = await _dbHelper.database;
    final categoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;
    if (categoryCount == 0) {
      await _insertDefaultCategories(db);
    }
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

  Future<void> _insertDefaultCategories(Database db) async {
    const defaults = [
      CategoryModel(
        id: 'cat_food',
        name: '餐饮',
        icon: '🍔',
        colorHex: '#F06B78',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_transport',
        name: '交通',
        icon: '🚌',
        colorHex: '#6E9BFF',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_shopping',
        name: '购物',
        icon: '🛍️',
        colorHex: '#F2A84B',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_housing',
        name: '居住',
        icon: '🏠',
        colorHex: '#63B978',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_entertainment',
        name: '娱乐',
        icon: '🎮',
        colorHex: '#9A75E8',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_daily',
        name: '日用',
        icon: '📦',
        colorHex: '#67B7C7',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_communication',
        name: '通讯',
        icon: '📱',
        colorHex: '#6688EA',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_education',
        name: '教育',
        icon: '📖',
        colorHex: '#5DB7A8',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_medical',
        name: '医疗',
        icon: '🩺',
        colorHex: '#E95E68',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_other',
        name: '其他',
        icon: '•••',
        colorHex: '#8791A5',
        type: CategoryType.expense,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_salary',
        name: '工资收入',
        icon: '💰',
        colorHex: '#55B98A',
        type: CategoryType.income,
        isCustom: false,
      ),
      CategoryModel(
        id: 'cat_bonus',
        name: '理财/奖金',
        icon: '📈',
        colorHex: '#58A99A',
        type: CategoryType.income,
        isCustom: false,
      ),
    ];
    for (final category in defaults) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<void> addExpenseCategory(String name) async {
    final db = await _dbHelper.database;
    const colors = [
      '#F08A8F',
      '#7296E8',
      '#E6A24C',
      '#6AB8B2',
      '#9A7BE8',
    ];
    final color = colors[DateTime.now().microsecondsSinceEpoch % colors.length];
    await db.insert(
      'categories',
      CategoryModel(
        id: 'cat_custom_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        icon: '🏷️',
        colorHex: color,
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
