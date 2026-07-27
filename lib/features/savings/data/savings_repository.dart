import '../../../../core/database/database_helper.dart';
import 'models/savings_goal_model.dart';

class SavingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insertGoal(SavingsGoalModel goal) async {
    final db = await _dbHelper.database;
    await db.insert('savings_goals', goal.toMap());
  }

  Future<List<SavingsGoalModel>> getAllGoals() async {
    final db = await _dbHelper.database;
    final maps = await db.query('savings_goals', orderBy: 'created_at DESC');
    return maps.map((m) => SavingsGoalModel.fromMap(m)).toList();
  }

  Future<void> updateGoalProgress(String id, double addedAmount) async {
    final db = await _dbHelper.database;
    final maps = await db.query('savings_goals', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final goal = SavingsGoalModel.fromMap(maps.first);
      final newCurrent = goal.currentAmount + addedAmount;
      await db.update(
        'savings_goals',
        {'current_amount': newCurrent},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteGoal(String id) async {
    final db = await _dbHelper.database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
