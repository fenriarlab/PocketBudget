import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';

class BackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// 导出 SQLite 数据库中所有表的数据为 JSON 格式
  Future<String> exportBackupJson() async {
    final db = await _dbHelper.database;

    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final savingsGoals = await db.query('savings_goals');
    final savingsLogs = await db.query('savings_logs');
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
            await txn.insert('savings_goals', Map<String, dynamic>.from(item as Map));
          }
        }

        // 还原存钱流水
        if (data.containsKey('savings_logs')) {
          final logs = data['savings_logs'] as List<dynamic>;
          for (var item in logs) {
            final log = Map<String, dynamic>.from(item as Map);
            final logId = log['id'] as String;
            final inferredTransactionId = 'tx_savings_$logId';
            final linkedTransactionId = log['linked_transaction_id'] as String? ?? (transactionIds.contains(inferredTransactionId) ? inferredTransactionId : null);
            log['linked_transaction_id'] = linkedTransactionId;
            log['deduct_from_budget'] = log['deduct_from_budget'] ?? (linkedTransactionId == null ? 0 : 1);
            await txn.insert('savings_logs', log);
          }
        }

        // 还原预算
        if (data.containsKey('budgets')) {
          final budgets = data['budgets'] as List<dynamic>;
          for (var item in budgets) {
            await txn.insert('budgets', Map<String, dynamic>.from(item as Map), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
