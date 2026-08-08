import '../../../../core/utils/month_period.dart';

class MonthlyFinancialSnapshot {
  final MonthPeriod period;
  final double income;
  final double consumption;
  final double netSavings;
  final double budgetedSavings;
  final double? budget;
  final double? budgetUsed;
  final double? remainingBudget;
  final double cashflowSurplus;
  final double distributableSurplus;
  final double? dailyAllowance;
  final double? dailyPressureBaseline;

  const MonthlyFinancialSnapshot({
    required this.period,
    required this.income,
    required this.consumption,
    required this.netSavings,
    required this.budgetedSavings,
    required this.budget,
    required this.budgetUsed,
    required this.remainingBudget,
    required this.cashflowSurplus,
    required this.distributableSurplus,
    required this.dailyAllowance,
    required this.dailyPressureBaseline,
  });

  bool get hasBudget => budget != null;

  bool get hasEvaluablePressure => dailyPressureBaseline != null && dailyPressureBaseline! > 0;
}