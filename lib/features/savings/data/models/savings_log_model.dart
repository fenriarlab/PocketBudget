class SavingsLogModel {
  final String id;
  final String goalId;
  final double amount; // Positive = Deposit (+), Negative = Withdraw (-)
  final String? note;
  final DateTime createdAt;
  final bool deductFromBudget;
  final String? linkedTransactionId;

  SavingsLogModel({
    required this.id,
    required this.goalId,
    required this.amount,
    this.note,
    required this.createdAt,
    this.deductFromBudget = false,
    this.linkedTransactionId,
  });

  bool get isDeposit => amount >= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'deduct_from_budget': deductFromBudget ? 1 : 0,
      'linked_transaction_id': linkedTransactionId,
    };
  }

  factory SavingsLogModel.fromMap(Map<String, dynamic> map) {
    return SavingsLogModel(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      deductFromBudget: (map['deduct_from_budget'] as num?)?.toInt() == 1,
      linkedTransactionId: map['linked_transaction_id'] as String?,
    );
  }
}
