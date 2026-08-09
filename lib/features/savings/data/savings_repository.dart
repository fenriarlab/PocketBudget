import '../../../../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'models/savings_goal_model.dart';
import 'models/savings_log_model.dart';
import '../../transactions/data/models/transaction_model.dart';

class SavingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<double> _recalculateGoalBalance(
      DatabaseExecutor db, String goalId) async {
    final totals = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM savings_logs WHERE goal_id = ?',
      [goalId],
    );
    final total = ((totals.first['total'] as num?) ?? 0).toDouble();
    final currentAmount = total.clamp(0.0, double.infinity);
    await db.update(
      'savings_goals',
      {'current_amount': currentAmount},
      where: 'id = ?',
      whereArgs: [goalId],
    );
    return currentAmount;
  }

  Future<void> insertGoal(SavingsGoalModel goal) async {
    final db = await _dbHelper.database;
    await db.insert('savings_goals', goal.toMap());
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final title = goal.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('专项储蓄名称不能为空');
    }
    if (goal.targetAmount <= 0) {
      throw ArgumentError('目标金额必须大于 0');
    }

    final db = await _dbHelper.database;
    final updated = await db.update(
      'savings_goals',
      {
        'title': title,
        'target_amount': goal.targetAmount,
        'target_date': goal.targetDate.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    if (updated == 0) {
      throw StateError('专项储蓄不存在');
    }
  }

  Future<List<SavingsGoalModel>> getAllGoals() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'savings_goals',
      where: 'status = ?',
      whereArgs: [SavingsGoalStatus.active.name],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SavingsGoalModel.fromMap(m)).toList();
  }

  Future<List<SavingsGoalModel>> getArchivedGoals() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'savings_goals',
      where: 'status = ?',
      whereArgs: [SavingsGoalStatus.archived.name],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SavingsGoalModel.fromMap(m)).toList();
  }

  Future<List<SavingsLogModel>> getLogsForGoal(String goalId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('savings_logs',
        where: 'goal_id = ?', whereArgs: [goalId], orderBy: 'created_at DESC');
    return maps.map((m) => SavingsLogModel.fromMap(m)).toList();
  }

  Future<List<SavingsLogModel>> getAllLogs() async {
    final db = await _dbHelper.database;
    final maps = await db.query('savings_logs', orderBy: 'created_at DESC');
    return maps.map((m) => SavingsLogModel.fromMap(m)).toList();
  }

  Future<void> addSavingsLog(SavingsLogModel log,
      {bool deductFromBudget = false}) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final maps = await txn
          .query('savings_goals', where: 'id = ?', whereArgs: [log.goalId]);
      if (maps.isEmpty) return;
      if (maps.first['status'] != SavingsGoalStatus.active.name) {
        throw StateError('归档的专项储蓄需要恢复后才能记录流水');
      }

      const linkedTransactionId = null;
      final persistedLog = log.toMap()
        ..['deduct_from_budget'] = deductFromBudget && log.amount > 0 ? 1 : 0
        ..['linked_transaction_id'] = linkedTransactionId;
      await txn.insert('savings_logs', persistedLog);

      if (deductFromBudget && log.amount > 0) {
        await txn.insert('budget_allocations', {
          'id': 'allocation_${log.id}',
          'period':
              '${log.createdAt.year}-${log.createdAt.month.toString().padLeft(2, '0')}',
          'savings_log_id': log.id,
          'allocated_amount': log.amount,
          'created_at': log.createdAt.millisecondsSinceEpoch,
        });
      }

      await _recalculateGoalBalance(txn, log.goalId);
    });
  }

  Future<void> deleteSavingsLog(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final logs = await txn.query('savings_logs',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (logs.isEmpty) return;

      final log = logs.first;
      final goalId = log['goal_id'] as String;
      final goalRows = await txn.query('savings_goals',
          columns: ['status'], where: 'id = ?', whereArgs: [goalId], limit: 1);
      if (goalRows.isNotEmpty &&
          goalRows.first['status'] != SavingsGoalStatus.active.name) {
        throw StateError('归档的专项储蓄需要恢复后才能删除流水');
      }
      final transactionId = log['linked_transaction_id'] as String?;
      if (transactionId != null) {
        await txn.delete('transactions',
            where: 'id = ?', whereArgs: [transactionId]);
      }
      await txn.delete('budget_allocations',
          where: 'savings_log_id = ?', whereArgs: [id]);
      await txn.delete('savings_logs', where: 'id = ?', whereArgs: [id]);

      await _recalculateGoalBalance(txn, goalId);
    });
  }

  Future<void> updateSavingsLog(SavingsLogModel log,
      {required bool deductFromBudget}) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final existingRows = await txn.query('savings_logs',
          where: 'id = ?', whereArgs: [log.id], limit: 1);
      if (existingRows.isEmpty) return;

      final existing = SavingsLogModel.fromMap(existingRows.first);
      final goalRows = await txn.query('savings_goals',
          where: 'id = ?', whereArgs: [log.goalId], limit: 1);
      if (goalRows.isEmpty) return;
      if (goalRows.first['status'] != SavingsGoalStatus.active.name) {
        throw StateError('归档的专项储蓄需要恢复后才能编辑流水');
      }

      final totals = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM savings_logs WHERE goal_id = ? AND id != ?',
        [log.goalId, log.id],
      );
      final projectedAmount =
          (((totals.first['total'] as num?) ?? 0) + log.amount).toDouble();
      if (projectedAmount < 0) {
        throw StateError('Savings balance cannot be negative');
      }

      final goal = SavingsGoalModel.fromMap(goalRows.first);
      final linkedTransactionId = deductFromBudget && log.amount > 0
          ? existing.linkedTransactionId ?? 'tx_savings_${log.id}'
          : null;
      final persistedLog = log.toMap()
        ..['deduct_from_budget'] = linkedTransactionId == null ? 0 : 1
        ..['linked_transaction_id'] = linkedTransactionId;
      await txn.update('savings_logs', persistedLog,
          where: 'id = ?', whereArgs: [log.id]);

      await txn.delete('budget_allocations',
          where: 'savings_log_id = ?', whereArgs: [log.id]);
      if (deductFromBudget && log.amount > 0) {
        await txn.insert('budget_allocations', {
          'id': 'allocation_${log.id}',
          'period':
              '${log.createdAt.year}-${log.createdAt.month.toString().padLeft(2, '0')}',
          'savings_log_id': log.id,
          'allocated_amount': log.amount,
          'created_at': log.createdAt.millisecondsSinceEpoch,
        });
      }

      if (existing.linkedTransactionId != null &&
          existing.linkedTransactionId != linkedTransactionId) {
        await txn.delete('transactions',
            where: 'id = ?', whereArgs: [existing.linkedTransactionId]);
      }
      if (linkedTransactionId != null) {
        final tx = TransactionModel(
          id: linkedTransactionId,
          amount: log.amount,
          type: TransactionType.expense,
          categoryId: 'cat_savings',
          categoryName: '强迫存钱',
          categoryIcon: '🎯',
          date: log.createdAt,
          note:
              "存入【${goal.title}】${log.note != null && log.note!.isNotEmpty ? ' (${log.note})' : ''}",
        );
        await txn.insert('transactions', tx.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await _recalculateGoalBalance(txn, log.goalId);
    });
  }

  Future<void> deleteGoal(String id) async {
    await purgeEmptyGoal(id);
  }

  Future<void> archiveGoal(String id) async {
    final db = await _dbHelper.database;
    final updated = await db.update(
      'savings_goals',
      {'status': SavingsGoalStatus.archived.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) throw StateError('专项储蓄不存在');
  }

  Future<void> restoreGoal(String id) async {
    final db = await _dbHelper.database;
    final updated = await db.update(
      'savings_goals',
      {'status': SavingsGoalStatus.active.name},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) throw StateError('专项储蓄不存在');
  }

  Future<void> purgeEmptyGoal(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final logCount = Sqflite.firstIntValue(await txn.rawQuery(
            'SELECT COUNT(*) FROM savings_logs WHERE goal_id = ?',
            [id],
          )) ??
          0;
      if (logCount > 0) {
        throw StateError('有历史流水的专项储蓄不能永久删除');
      }

      final goalRows = await txn.query('savings_goals',
          columns: ['status'], where: 'id = ?', whereArgs: [id], limit: 1);
      if (goalRows.isEmpty ||
          (goalRows.first['status'] != SavingsGoalStatus.active.name &&
              goalRows.first['status'] != SavingsGoalStatus.archived.name)) {
        throw StateError('只有没有流水的专项储蓄可以永久删除');
      }

      final logs = await txn.query('savings_logs',
          columns: ['linked_transaction_id'],
          where: 'goal_id = ?',
          whereArgs: [id]);
      for (final log in logs) {
        final transactionId = log['linked_transaction_id'] as String?;
        if (transactionId != null) {
          await txn.delete('transactions',
              where: 'id = ?', whereArgs: [transactionId]);
        }
      }
      await txn.delete('budget_allocations',
          where:
              'savings_log_id IN (SELECT id FROM savings_logs WHERE goal_id = ?)',
          whereArgs: [id]);
      await txn.delete('savings_logs', where: 'goal_id = ?', whereArgs: [id]);
      await txn.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
    });
  }
}
