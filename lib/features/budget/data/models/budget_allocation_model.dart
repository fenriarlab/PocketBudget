class BudgetAllocationModel {
  final String id;
  final String period;
  final String savingsLogId;
  final double allocatedAmount;
  final DateTime createdAt;

  const BudgetAllocationModel({
    required this.id,
    required this.period,
    required this.savingsLogId,
    required this.allocatedAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'period': period,
        'savings_log_id': savingsLogId,
        'allocated_amount': allocatedAmount,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory BudgetAllocationModel.fromMap(Map<String, dynamic> map) => BudgetAllocationModel(
        id: map['id'] as String,
        period: map['period'] as String,
        savingsLogId: map['savings_log_id'] as String,
        allocatedAmount: (map['allocated_amount'] as num).toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}