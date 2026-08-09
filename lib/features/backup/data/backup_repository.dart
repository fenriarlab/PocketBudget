import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../savings/data/models/savings_goal_model.dart';

class BackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 导出 SQLite 数据库中所有表的数据为 JSON 格式
  Future<String> exportBackupJson() async {
    final db = await _dbHelper.database;

    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final savingsGoals = await db.query('savings_goals');
    final savingsLogs = await db.query('savings_logs');
    final budgetAllocations = await db.query('budget_allocations');
    final budgets = await db.query('budgets');

    final backupMap = {
      'app': 'PocketBudget',
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'categories': categories,
        'transactions': transactions,
        'savings_goals': savingsGoals,
        'savings_logs': savingsLogs,
        'budget_allocations': budgetAllocations,
        'budgets': budgets,
      }
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// 从备份 JSON 字符串无缝还原所有表数据
  Future<bool> restoreBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> backupMap = jsonDecode(jsonStr);
      if (!backupMap.containsKey('data')) return false;

      final data = backupMap['data'] as Map<String, dynamic>;
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // 清空原有数据
        await txn.delete('transactions');
        await txn.delete('savings_goals');
        await txn.delete('savings_logs');
        await txn.delete('budget_allocations');
        await txn.delete('budgets');

        final transactionIds = <String>{};

        // 还原交易记录
        if (data.containsKey('transactions')) {
          final txs = data['transactions'] as List<dynamic>;
          for (var item in txs) {
            final transaction = Map<String, dynamic>.from(item as Map);
            transactionIds.add(transaction['id'] as String);
            await txn.insert('transactions', transaction);
          }
        }

        // 还原存钱目标
        if (data.containsKey('savings_goals')) {
          final goals = data['savings_goals'] as List<dynamic>;
          for (var item in goals) {
            final goal = Map<String, dynamic>.from(item as Map);
            final status = goal['status'];
            goal['status'] = status == SavingsGoalStatus.archived.name
                ? SavingsGoalStatus.archived.name
                : SavingsGoalStatus.active.name;
            goal['current_amount'] =
                (goal['current_amount'] as num?)?.toDouble() ?? 0.0;
            await txn.insert('savings_goals', goal);
          }
        }

        // 还原存钱流水
        if (data.containsKey('savings_logs')) {
          final logs = data['savings_logs'] as List<dynamic>;
          for (var item in logs) {
            final log = Map<String, dynamic>.from(item as Map);
            final logId = log['id'] as String;
            final inferredTransactionId = 'tx_savings_$logId';
            final linkedTransactionId =
                log['linked_transaction_id'] as String? ??
                    (transactionIds.contains(inferredTransactionId)
                        ? inferredTransactionId
                        : null);
            log['linked_transaction_id'] = null;
            log['deduct_from_budget'] = log['deduct_from_budget'] ??
                (linkedTransactionId == null ? 0 : 1);
            await txn.insert('savings_logs', log);
            if (linkedTransactionId != null) {
              await txn.insert(
                  'budget_allocations',
                  {
                    'id': 'allocation_$logId',
                    'period': _periodFromTimestamp(log['created_at'] as int),
                    'savings_log_id': logId,
                    'allocated_amount': log['amount'],
                    'created_at': log['created_at'],
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace);
              await txn.delete('transactions',
                  where: 'id = ?', whereArgs: [linkedTransactionId]);
            }
          }
        }

        if (data.containsKey('budget_allocations')) {
          final allocations = data['budget_allocations'] as List<dynamic>;
          for (final item in allocations) {
            await txn.insert(
                'budget_allocations', Map<String, dynamic>.from(item as Map),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // 还原预算
        if (data.containsKey('budgets')) {
          final budgets = data['budgets'] as List<dynamic>;
          for (var item in budgets) {
            await txn.insert('budgets', Map<String, dynamic>.from(item as Map),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // current_amount is a cache; restore it from the authoritative logs.
        final restoredGoals = await txn.query('savings_goals', columns: ['id']);
        for (final goal in restoredGoals) {
          final goalId = goal['id'] as String;
          final totals = await txn.rawQuery(
            'SELECT COALESCE(SUM(amount), 0) AS total FROM savings_logs WHERE goal_id = ?',
            [goalId],
          );
          final total = (totals.first['total'] as num?) ?? 0;
          await txn.update(
            'savings_goals',
            {
              'current_amount': total.toDouble().clamp(0.0, double.infinity),
            },
            where: 'id = ?',
            whereArgs: [goalId],
          );
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  String _periodFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}
