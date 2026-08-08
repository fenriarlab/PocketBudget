enum SavingsGoalStatus { active, archived }

class SavingsGoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final SavingsGoalStatus status;

  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.createdAt,
    this.status = SavingsGoalStatus.active,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final pct = (currentAmount / targetAmount) * 100;
    return pct > 100 ? 100.0 : pct;
  }

  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, targetAmount);

  int get remainingDays {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['target_date'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      status: map['status'] == SavingsGoalStatus.archived.name ? SavingsGoalStatus.archived : SavingsGoalStatus.active,
    );
  }
}
