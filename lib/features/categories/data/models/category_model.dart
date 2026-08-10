enum CategoryType { expense, income }

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final CategoryType type;
  final bool isCustom;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
    required this.isCustom,
  });

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon_name'] as String,
      colorHex: map['color_hex'] as String? ?? '#8791A5',
      type: map['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'icon_name': icon,
        'color_hex': colorHex,
        'type': type == CategoryType.income ? 'INCOME' : 'EXPENSE',
        'is_custom': isCustom ? 1 : 0,
      };
}