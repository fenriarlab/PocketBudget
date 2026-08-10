import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';

class InitialBalanceRepository {
  static const _recordId = 'account';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<double> getInitialBalance() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'initial_balance',
      columns: ['amount'],
      where: 'id = ?',
      whereArgs: [_recordId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.single['amount'] as num).toDouble();
  }

  Future<void> setInitialBalance(double amount) async {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be a finite non-negative number');
    }
    final db = await _dbHelper.database;
    await db.insert(
      'initial_balance',
      {
        'id': _recordId,
        'amount': amount,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}