enum CategoryType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final CategoryType type;
  final bool isCustom;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
    required this.isCustom,
  });

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon_name'] as String,
      type: map['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon_name': icon,
        'color_hex': '#7E8AA2',
        'type': type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        'is_custom': isCustom ? 1 : 0,
      };
}