import '../../../../core/database/database_helper.dart';
import 'models/budget_model.dart';
import 'package:sqflite/sqflite.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> setBudget(String period, double totalBudget) async {
    final db = await _dbHelper.database;
    await db.insert(
      'budgets',
      {'period': period, 'total_budget': totalBudget},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<BudgetModel?> getBudget(String period) async {
    final db = await _dbHelper.database;
    final maps = await db.query('budgets', where: 'period = ?', whereArgs: [period]);
    if (maps.isEmpty) return null;
    return BudgetModel.fromMap(maps.first);
  }
}
