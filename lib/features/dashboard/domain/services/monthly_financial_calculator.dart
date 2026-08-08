import '../../../../core/utils/month_period.dart';
import '../../../budget/data/models/budget_model.dart';
import '../../../savings/data/models/savings_log_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../models/monthly_financial_snapshot.dart';

class MonthlyFinancialCalculator {
  const MonthlyFinancialCalculator();

  MonthlyFinancialSnapshot calculate({
    required MonthPeriod period,
    required Iterable<TransactionModel> transactions,
    required Iterable<SavingsLogModel> savingsLogs,
    required BudgetModel? budget,
    DateTime? today,
  }) {
    var income = 0.0;
    var consumption = 0.0;
    for (final transaction in transactions) {
      if (!period.contains(transaction.date)) continue;
      if (transaction.type == TransactionType.income) {
        income += transaction.amount;
      } else if (transaction.categoryId != 'cat_savings') {
        consumption += transaction.amount;
      }
    }

    var netSavings = 0.0;
    var budgetedSavings = 0.0;
    for (final log in savingsLogs) {
      if (!period.contains(log.createdAt)) continue;
      netSavings += log.amount;
      if (log.amount > 0 && log.deductFromBudget) budgetedSavings += log.amount;
    }

    final budgetValue = budget?.totalBudget;
    final budgetUsed = budgetValue == null ? null : consumption + budgetedSavings;
    final remainingBudget = budgetUsed == null ? null : budgetValue! - budgetUsed;
    final cashflowSurplus = income - consumption;
    final distributableSurplus = cashflowSurplus - netSavings;

    double? dailyAllowance;
    double? dailyPressureBaseline;
    if (budgetValue != null) {
      dailyPressureBaseline = (budgetValue - budgetedSavings) / period.daysInMonth;
      if (period.isCurrent) {
        final referenceDate = today ?? DateTime.now();
        final remainingDays = (period.daysInMonth - referenceDate.day + 1).clamp(1, period.daysInMonth);
        dailyAllowance = remainingBudget! > 0 ? remainingBudget / remainingDays : 0.0;
      }
    }

    return MonthlyFinancialSnapshot(
      period: period,
      income: income,
      consumption: consumption,
      netSavings: netSavings,
      budgetedSavings: budgetedSavings,
      budget: budgetValue,
      budgetUsed: budgetUsed,
      remainingBudget: remainingBudget,
      cashflowSurplus: cashflowSurplus,
      distributableSurplus: distributableSurplus,
      dailyAllowance: dailyAllowance,
      dailyPressureBaseline: dailyPressureBaseline,
    );
  }
}