import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import 'models/category_model.dart';

class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const List<CategoryModel> defaultCategories = [
    // ─── 支出分类 ─────────────────────────────────────────
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

    // ─── 收入分类 ─────────────────────────────────────────
    CategoryModel(
      id: 'cat_salary',
      name: '工资薪酬',
      icon: '💰',
      colorHex: '#55B98A',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_bonus',
      name: '奖金津贴',
      icon: '🎁',
      colorHex: '#58A99A',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_part_time',
      name: '兼职副业',
      icon: '💼',
      colorHex: '#4CAF50',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_investment',
      name: '投资理财',
      icon: '📈',
      colorHex: '#26A69A',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_business',
      name: '经营所得',
      icon: '🏪',
      colorHex: '#00897B',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_gift_income',
      name: '礼金红包',
      icon: '🧧',
      colorHex: '#E91E63',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_secondhand',
      name: '闲置变现',
      icon: '♻️',
      colorHex: '#8BC34A',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_reimbursement',
      name: '报销返还',
      icon: '🧾',
      colorHex: '#00ACC1',
      type: CategoryType.income,
      isCustom: false,
    ),
    CategoryModel(
      id: 'cat_other_income',
      name: '其他收入',
      icon: '🪙',
      colorHex: '#8791A5',
      type: CategoryType.income,
      isCustom: false,
    ),
  ];

  Future<List<CategoryModel>> getCategories({CategoryType? type}) async {
    final db = await _dbHelper.database;
    await _ensureDefaultCategories(db);
    final maps = await db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null
          ? null
          : [type == CategoryType.income ? 'INCOME' : 'EXPENSE'],
      orderBy: 'is_custom ASC, id ASC',
    );
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<void> _ensureDefaultCategories(Database db) async {
    for (final category in defaultCategories) {
      await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<CategoryModel> addCategory(
    String name, {
    CategoryType type = CategoryType.expense,
  }) async {
    final db = await _dbHelper.database;
    final isIncome = type == CategoryType.income;
    final colors = isIncome
        ? const ['#55B98A', '#4CAF50', '#26A69A', '#00897B', '#8BC34A', '#00ACC1']
        : const ['#F08A8F', '#7296E8', '#E6A24C', '#6AB8B2', '#9A7BE8'];
    final color = colors[DateTime.now().microsecondsSinceEpoch % colors.length];
    final category = CategoryModel(
      id: 'cat_custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      icon: '🏷️',
      colorHex: color,
      type: type,
      isCustom: true,
    );
    await db.insert(
      'categories',
      category.toMap(),
    );
    return category;
  }

  Future<CategoryModel> addExpenseCategory(String name) =>
      addCategory(name, type: CategoryType.expense);

  Future<CategoryModel> addIncomeCategory(String name) =>
      addCategory(name, type: CategoryType.income);

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
