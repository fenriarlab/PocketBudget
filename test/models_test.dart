import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/budget/data/models/budget_model.dart';
import 'package:pocket_budget/features/savings/data/models/savings_goal_model.dart';
import 'package:pocket_budget/features/savings/data/models/savings_log_model.dart';
import 'package:pocket_budget/features/transactions/data/models/transaction_model.dart';

void main() {
  test('transaction model round-trips through SQLite map', () {
    final transaction = TransactionModel(
      id: 'tx-1',
      amount: 35.5,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      categoryName: '餐饮',
      categoryIcon: '🍔',
      date: DateTime(2026, 8, 1),
      note: '午餐',
    );

    final restored = TransactionModel.fromMap(transaction.toMap());

    expect(restored.id, transaction.id);
    expect(restored.amount, transaction.amount);
    expect(restored.type, TransactionType.expense);
    expect(restored.date, transaction.date);
    expect(restored.note, '午餐');
  });

  test('budget model round-trips through SQLite map', () {
    final restored = BudgetModel.fromMap(BudgetModel(period: '2026-08', totalBudget: 5000).toMap());

    expect(restored.period, '2026-08');
    expect(restored.totalBudget, 5000);
  });

  test('savings goal exposes progress and remaining amount', () {
    final goal = SavingsGoalModel(
      id: 'goal-1',
      title: '旅行基金',
      targetAmount: 10000,
      currentAmount: 6200,
      targetDate: DateTime.now().add(const Duration(days: 20)),
      createdAt: DateTime.now(),
    );

    expect(goal.progressPercentage, 62);
    expect(goal.remainingAmount, 3800);
    expect(goal.remainingDays, greaterThanOrEqualTo(19));
  });

  test('withdrawal log is classified as withdrawal', () {
    final log = SavingsLogModel(goalId: 'goal-1', id: 'log-1', amount: -100, createdAt: DateTime(2026, 8, 1));

    expect(log.isDeposit, isFalse);
    expect(SavingsLogModel.fromMap(log.toMap()).amount, -100);
  });
}
