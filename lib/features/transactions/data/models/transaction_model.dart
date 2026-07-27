enum TransactionType { expense, income }

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final DateTime date;
  final String? note;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type == TransactionType.expense ? 'EXPENSE' : 'INCOME',
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'date': date.millisecondsSinceEpoch,
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] == 'EXPENSE' ? TransactionType.expense : TransactionType.income,
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String,
      categoryIcon: map['category_icon'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
    );
  }
}
