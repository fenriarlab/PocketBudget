import '../../../../core/database/database_helper.dart';
import 'models/transaction_model.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insertTransaction(TransactionModel tx) async {
    final db = await _dbHelper.database;
    await db.insert('transactions', tx.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(String yyyyMM) async {
    final db = await _dbHelper.database;
    final all = await getAllTransactions();
    return all.where((tx) {
      final monthStr = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
      return monthStr == yyyyMM;
    }).toList();
  }

  Future<double> getTotalExpenseByMonth(String yyyyMM) async {
    final txs = await getTransactionsByMonth(yyyyMM);
    return txs
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<double> getTotalIncomeByMonth(String yyyyMM) async {
    final txs = await getTransactionsByMonth(yyyyMM);
    return txs
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
