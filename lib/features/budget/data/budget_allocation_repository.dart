import '../../../../core/database/database_helper.dart';
import 'models/budget_allocation_model.dart';

class BudgetAllocationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<BudgetAllocationModel>> getByPeriod(String period) async {
    final db = await _dbHelper.database;
    final maps = await db.query('budget_allocations', where: 'period = ?', whereArgs: [period], orderBy: 'created_at DESC');
    return maps.map(BudgetAllocationModel.fromMap).toList();
  }
}