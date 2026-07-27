class BudgetModel {
  final String period; // YYYY-MM
  final double totalBudget;

  BudgetModel({
    required this.period,
    required this.totalBudget,
  });

  Map<String, dynamic> toMap() {
    return {
      'period': period,
      'total_budget': totalBudget,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      period: map['period'] as String,
      totalBudget: (map['total_budget'] as num).toDouble(),
    );
  }
}
