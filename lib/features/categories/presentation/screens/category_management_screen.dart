import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';

/// 独立全屏分类管理页面，用于增删支出与收入分类
class CategoryManagementScreen extends StatefulWidget {
  final List<CategoryModel> expenseCategories;
  final List<CategoryModel> incomeCategories;
  final Future<void> Function(String name, CategoryType type) onAdd;
  final Future<void> Function(CategoryModel category)? onDelete;

  const CategoryManagementScreen({
    super.key,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.onAdd,
    this.onDelete,
  });

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryManagementTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          tabs: [
            Tab(text: l10n.categoriesTabExpense),
            Tab(text: l10n.categoriesTabIncome),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.addCategory,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryListTab(
            categories: widget.expenseCategories,
            emptySubtitle: l10n.expenseCategoriesSubtitle,
            onDelete: widget.onDelete,
          ),
          _CategoryListTab(
            categories: widget.incomeCategories,
            emptySubtitle: l10n.incomeCategoriesSubtitle,
            onDelete: widget.onDelete,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabController.index == 0
              ? l10n.addExpenseCategory
              : l10n.addIncomeCategory,
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isIncomeTab = _tabController.index == 1;
    final currentType =
        isIncomeTab ? CategoryType.income : CategoryType.expense;
    final title =
        isIncomeTab ? l10n.addIncomeCategory : l10n.addExpenseCategory;

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: l10n.categoryNameLabel,
              hintText: isIncomeTab ? '如：房租收入、股息' : '如：宠物、零食',
            ),
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
      await widget.onAdd(name, currentType);
    }
  }
}

class _CategoryListTab extends StatelessWidget {
  final List<CategoryModel> categories;
  final String emptySubtitle;
  final Future<void> Function(CategoryModel category)? onDelete;

  const _CategoryListTab({
    required this.categories,
    required this.emptySubtitle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 56, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(emptySubtitle,
                style: TextStyle(color: colors.onSurfaceVariant)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
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
    final displayName = _localizedCategoryName(category, l10n);

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
              displayName,
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
  // 支出
  'cat_food': Icons.restaurant_outlined,
  'cat_transport': Icons.directions_car_outlined,
  'cat_shopping': Icons.shopping_bag_outlined,
  'cat_housing': Icons.home_outlined,
  'cat_entertainment': Icons.sports_esports_outlined,
  'cat_daily': Icons.inventory_2_outlined,
  'cat_communication': Icons.phone_iphone_outlined,
  'cat_education': Icons.menu_book_outlined,
  'cat_medical': Icons.medical_services_outlined,
  'cat_other': Icons.category_outlined,

  // 收入
  'cat_salary': Icons.account_balance_wallet_outlined,
  'cat_bonus': Icons.card_giftcard_outlined,
  'cat_part_time': Icons.work_outline,
  'cat_investment': Icons.trending_up,
  'cat_business': Icons.storefront_outlined,
  'cat_gift_income': Icons.redeem_outlined,
  'cat_secondhand': Icons.swap_horizontal_circle_outlined,
  'cat_reimbursement': Icons.receipt_long_outlined,
  'cat_other_income': Icons.monetization_on_outlined,
};

String _localizedCategoryName(CategoryModel category, AppLocalizations l10n) {
  switch (category.id) {
    case 'cat_food':
      return l10n.categoryFood;
    case 'cat_transport':
      return l10n.categoryTransport;
    case 'cat_shopping':
      return l10n.categoryShopping;
    case 'cat_housing':
      return l10n.categoryHousing;
    case 'cat_entertainment':
      return l10n.categoryEntertainment;
    case 'cat_daily':
      return '日用';
    case 'cat_communication':
      return '通讯';
    case 'cat_education':
      return '教育';
    case 'cat_medical':
      return '医疗';
    case 'cat_other':
      return '其他';
    case 'cat_salary':
      return l10n.categorySalary;
    case 'cat_bonus':
      return l10n.categoryBonus;
    case 'cat_part_time':
      return l10n.categoryPartTime;
    case 'cat_investment':
      return l10n.categoryInvestment;
    case 'cat_business':
      return l10n.categoryBusiness;
    case 'cat_gift_income':
      return l10n.categoryGiftIncome;
    case 'cat_secondhand':
      return l10n.categorySecondhand;
    case 'cat_reimbursement':
      return l10n.categoryReimbursement;
    case 'cat_other_income':
      return l10n.categoryOtherIncome;
    default:
      return category.name;
  }
}

Color _categoryColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  return value == null
      ? AppColors.textSecondary
      : Color(0xFF000000 | value);
}
