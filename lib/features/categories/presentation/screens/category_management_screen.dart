import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';

/// 独立全屏分类管理页面，用于增删消费分类
class CategoryManagementScreen extends StatelessWidget {
  final List<CategoryModel> categories;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(CategoryModel category)? onDelete;

  const CategoryManagementScreen({
    super.key,
    required this.categories,
    required this.onAdd,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryManagementTitle),
        actions: [
          IconButton(
            tooltip: l10n.addCategory,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 56, color: colors.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(l10n.expenseCategoriesSubtitle,
                      style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 64,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final color = _categoryColor(category.colorHex);
                return _CategoryTile(
                  category: category,
                  color: color,
                  onDelete:
                      (category.isCustom && onDelete != null) ? onDelete : null,
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.addExpenseCategory),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(labelText: l10n.categoryNameLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    await WidgetsBinding.instance.endOfFrame;
    controller.dispose();
    if (name != null && name.isNotEmpty && context.mounted) {
      await onAdd(name);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final Color color;
  final Future<void> Function(CategoryModel category)? onDelete;

  const _CategoryTile({
    required this.category,
    required this.color,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: _CategoryGlyph(category: category),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: l10n.delete,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(Icons.close_rounded,
                  size: 18, color: colors.onSurfaceVariant),
              onPressed: () async {
                await onDelete!(category);
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryGlyph extends StatelessWidget {
  final CategoryModel category;

  const _CategoryGlyph({required this.category});

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[category.id];
    if (icon != null) {
      return Icon(icon, size: 19, color: _categoryColor(category.colorHex));
    }
    return Text(category.icon, style: const TextStyle(fontSize: 17));
  }
}

const _categoryIcons = <String, IconData>{
  'cat_food': Icons.restaurant_outlined,
  'cat_transport': Icons.directions_car_outlined,
  'cat_shopping': Icons.shopping_bag_outlined,
  'cat_daily': Icons.inventory_2_outlined,
  'cat_entertainment': Icons.sports_esports_outlined,
  'cat_housing': Icons.home_outlined,
  'cat_communication': Icons.phone_iphone_outlined,
  'cat_education': Icons.menu_book_outlined,
  'cat_medical': Icons.medical_services_outlined,
  'cat_other': Icons.category_outlined,
};

Color _categoryColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  return value == null
      ? AppColors.textSecondary
      : Color(0xFF000000 | value);
}
