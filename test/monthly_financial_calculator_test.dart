import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/core/utils/month_period.dart';
import 'package:pocket_budget/features/budget/data/models/budget_model.dart';
import 'package:pocket_budget/features/budget/data/models/budget_allocation_model.dart';
import 'package:pocket_budget/features/dashboard/domain/services/monthly_financial_calculator.dart';
import 'package:pocket_budget/features/savings/data/models/savings_log_model.dart';
import 'package:pocket_budget/features/transactions/data/models/transaction_model.dart';

void main() {
  const calculator = MonthlyFinancialCalculator();
  final period = MonthPeriod(2026, 8);

  TransactionModel transaction(String id, double amount, TransactionType type, DateTime date, {String categoryId = 'cat_food'}) => TransactionModel(
        id: id,
        amount: amount,
        type: type,
        categoryId: categoryId,
        categoryName: categoryId == 'cat_savings' ? '强迫存钱' : '餐饮',
        categoryIcon: 'x',
        date: date,
      );

  SavingsLogModel log(String id, double amount, DateTime date, {bool deduct = false}) => SavingsLogModel(id: id, goalId: 'goal', amount: amount, createdAt: date, deductFromBudget: deduct);

  test('calculates compatible monthly measures and excludes legacy savings transactions', () {
    final snapshot = calculator.calculate(
      period: period,
      transactions: [
        transaction('income', 10000, TransactionType.income, DateTime(2026, 8, 1)),
        transaction('food', 3000, TransactionType.expense, DateTime(2026, 8, 2)),
        transaction('legacy-savings', 1000, TransactionType.expense, DateTime(2026, 8, 3), categoryId: 'cat_savings'),
      ],
      savingsLogs: [log('save', 1000, DateTime(2026, 8, 4), deduct: true), log('withdraw', -200, DateTime(2026, 8, 5))],
      budget: BudgetModel(period: period.key, totalBudget: 5000),
      today: DateTime(2026, 8, 10),
    );

    expect(snapshot.income, 10000);
    expect(snapshot.consumption, 3000);
    expect(snapshot.netSavings, 800);
    expect(snapshot.budgetedSavings, 1000);
    expect(snapshot.budgetUsed, 4000);
    expect(snapshot.remainingBudget, 1000);
    expect(snapshot.cashflowSurplus, 7000);
    expect(snapshot.distributableSurplus, 6200);
    expect(snapshot.dailyAllowance, closeTo(1000 / 22, 0.000001));
  });

  test('treats missing budget as unlimited and does not calculate budget metrics', () {
    final snapshot = calculator.calculate(period: period, transactions: const [], savingsLogs: const [], budget: null);

    expect(snapshot.income, 0);
    expect(snapshot.consumption, 0);
    expect(snapshot.budget, isNull);
    expect(snapshot.budgetUsed, isNull);
    expect(snapshot.remainingBudget, isNull);
    expect(snapshot.dailyAllowance, isNull);
    expect(snapshot.dailyPressureBaseline, isNull);
  });

  test('prefers explicit budget allocations over legacy log flags', () {
    final snapshot = calculator.calculate(
      period: period,
      transactions: const [],
      savingsLogs: [log('save', 1000, DateTime(2026, 8, 4), deduct: true)],
      budgetAllocations: [
        BudgetAllocationModel(id: 'allocation-save', period: '2026-08', savingsLogId: 'save', allocatedAmount: 600, createdAt: DateTime(2026, 8, 4)),
      ],
      budget: BudgetModel(period: period.key, totalBudget: 2000),
    );

    expect(snapshot.budgetedSavings, 600);
    expect(snapshot.budgetUsed, 600);
  });

  test('does not show dynamic daily allowance for a historical month', () {
    final snapshot = calculator.calculate(
      period: MonthPeriod(2026, 7),
      transactions: const [],
      savingsLogs: const [],
      budget: BudgetModel(period: '2026-07', totalBudget: 3000),
      today: DateTime(2026, 8, 10),
    );

    expect(snapshot.dailyAllowance, isNull);
    expect(snapshot.dailyPressureBaseline, 3000 / 31);
  });
}