import '../../../../core/database/database_helper.dart';
import 'models/savings_goal_model.dart';
import 'models/savings_log_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/data/models/transaction_model.dart';

class SavingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TransactionRepository _txRepo = TransactionRepository();

  Future<void> insertGoal(SavingsGoalModel goal) async {
    final db = await _dbHelper.database;
    await db.insert('savings_goals', goal.toMap());
  }

  Future<List<SavingsGoalModel>> getAllGoals() async {
    final db = await _dbHelper.database;
    final maps = await db.query('savings_goals', orderBy: 'created_at DESC');
    return maps.map((m) => SavingsGoalModel.fromMap(m)).toList();
  }

  Future<List<SavingsLogModel>> getLogsForGoal(String goalId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('savings_logs', where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'created_at DESC');
    return maps.map((m) => SavingsLogModel.fromMap(m)).toList();
  }

  Future<void> addSavingsLog(SavingsLogModel log, {bool deductFromBudget = false}) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Insert log
      await txn.insert('savings_logs', log.toMap());

      // 2. Update current_amount in goal
      final maps = await txn.query('savings_goals', where: 'id = ?', whereArgs: [log.goalId]);
      if (maps.isNotEmpty) {
        final goal = SavingsGoalModel.fromMap(maps.first);
        final newCurrent = (goal.currentAmount + log.amount).clamp(0.0, double.infinity);
        await txn.update(
          'savings_goals',
          {'current_amount': newCurrent},
          where: 'id = ?',
          whereArgs: [log.goalId],
        );

        // 3. If deductFromBudget is true and amount > 0, generate an automatic expense transaction!
        if (deductFromBudget && log.amount > 0) {
          final tx = TransactionModel(
            id: "tx_savings_${log.id}",
            amount: log.amount,
            type: TransactionType.expense,
            categoryId: 'cat_savings',
            categoryName: '强迫存钱',
            categoryIcon: '🎯',
            date: log.createdAt,
            note: "存入【${goal.title}】${log.note != null && log.note!.isNotEmpty ? ' (${log.note})' : ''}",
          );
          await _txRepo.insertTransaction(tx);
        }
      }
    });
  }

  Future<void> deleteGoal(String id) async {
    final db = await _dbHelper.database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    await db.delete('savings_logs', where: 'goal_id = ?', whereArgs: [id]);
  }
}
