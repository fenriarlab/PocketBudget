import 'package:sqflite/sqflite.dart';

class BackupPayloadMigrator {
  static const int currentSchemaVersion = 1;

  static Map<String, dynamic> normalize(Map<String, dynamic> payload) {
    if (payload['schema_version'] != currentSchemaVersion) {
      throw const FormatException('Unsupported backup payload schema');
    }
    final data = payload['data'];
    if (data is! Map) throw const FormatException('Backup data is missing');
    for (final table in [
      'categories',
      'transactions',
      'savings_goals',
      'savings_logs',
      'budget_allocations',
      'budgets',
    ]) {
      if (data[table] is! List) {
        throw FormatException('Backup table is invalid: $table');
      }
    }
    return {
      'schema_version': currentSchemaVersion,
      'data': Map<String, dynamic>.from(data),
    };
  }

  static Future<void> restoreData(
    Transaction txn,
    Map<String, dynamic> payload,
  ) async {
    final data = normalize(payload)['data'] as Map<String, dynamic>;
    await txn.delete('transactions');
    await txn.delete('savings_goals');
    await txn.delete('savings_logs');
    await txn.delete('budget_allocations');
    await txn.delete('budgets');

    final transactions = [
      for (final item in data['transactions'] as List)
        Map<String, dynamic>.from(item as Map),
    ];
    final transactionIds = {
      for (final item in transactions) item['id'] as String,
    };
    for (final item in transactions) {
      await txn.insert('transactions', item);
    }

    for (final item in data['savings_goals'] as List) {
      final goal = Map<String, dynamic>.from(item as Map);
      goal['status'] = goal['status'] == 'archived' ? 'archived' : 'active';
      goal['current_amount'] =
          (goal['current_amount'] as num?)?.toDouble() ?? 0;
      await txn.insert('savings_goals', goal);
    }

    for (final item in data['savings_logs'] as List) {
      final log = Map<String, dynamic>.from(item as Map);
      final logId = log['id'] as String;
      final linkedId = log['linked_transaction_id'] as String? ??
          (transactionIds.contains('tx_savings_$logId')
              ? 'tx_savings_$logId'
              : null);
      log['linked_transaction_id'] = null;
      log['deduct_from_budget'] =
          log['deduct_from_budget'] ?? (linkedId == null ? 0 : 1);
      await txn.insert('savings_logs', log);
      if (linkedId != null) {
        await txn.insert(
          'budget_allocations',
          {
            'id': 'allocation_$logId',
            'period': _periodFromTimestamp(log['created_at'] as int),
            'savings_log_id': logId,
            'allocated_amount': log['amount'],
            'created_at': log['created_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn
            .delete('transactions', where: 'id = ?', whereArgs: [linkedId]);
      }
    }

    for (final item in data['budget_allocations'] as List) {
      await txn.insert(
        'budget_allocations',
        Map<String, dynamic>.from(item as Map),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final item in data['budgets'] as List) {
      await txn.insert(
        'budgets',
        Map<String, dynamic>.from(item as Map),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final goals = await txn.query('savings_goals', columns: ['id']);
    for (final goal in goals) {
      final goalId = goal['id'] as String;
      final totals = await txn.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM savings_logs WHERE goal_id = ?',
        [goalId],
      );
      final total = (totals.first['total'] as num?) ?? 0;
      await txn.update(
        'savings_goals',
        {'current_amount': total.toDouble().clamp(0.0, double.infinity)},
        where: 'id = ?',
        whereArgs: [goalId],
      );
    }
  }

  static String _periodFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}
