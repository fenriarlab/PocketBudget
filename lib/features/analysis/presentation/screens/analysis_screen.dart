import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import 'category_detail_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<TransactionModel>? allTransactions;
  final List<CategoryModel> categories;
  final bool privacyHidden;
  final String currencyCode;
  final ValueChanged<TransactionModel>? onDelete;
  final ValueChanged<TransactionModel>? onEdit;

  const AnalysisScreen({
    super.key,
    required this.transactions,
    this.allTransactions,
    this.categories = const [],
    required this.privacyHidden,
    this.currencyCode = 'CNY',
    this.onDelete,
    this.onEdit,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  CategoryModel? _selectedCategory;
  CategoryTimeRange _selectedTimeRange = CategoryTimeRange.all;
  DateTimeRange? _customDateRange;

  String _amount(double value) => widget.privacyHidden
      ? '${CurrencyCatalog.byCode(widget.currencyCode).symbol} ****'
      : CurrencyCatalog.byCode(widget.currencyCode).format(value, 'en');

  List<TransactionModel> get _allTx =>
      widget.allTransactions ?? widget.transactions;

  List<CategoryModel> _getAvailableCategories(AppLocalizations l10n) {
    if (widget.categories.isNotEmpty) return widget.categories;

    final map = <String, CategoryModel>{};
    for (final tx in _allTx) {
      if (!map.containsKey(tx.categoryId)) {
        map[tx.categoryId] = CategoryModel(
          id: tx.categoryId,
          name: _displayCategoryName(tx.categoryId, tx.categoryName, l10n),
          icon: tx.categoryIcon,
          colorHex: '#8791A5',
          type: tx.type == TransactionType.expense
              ? CategoryType.expense
              : CategoryType.income,
          isCustom: false,
        );
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthlyExpenseCategories = <String, double>{};
    for (final transaction in widget.transactions) {
      if (transaction.type == TransactionType.expense) {
        final category = _displayCategoryName(
            transaction.categoryId, transaction.categoryName, l10n);
        monthlyExpenseCategories[category] =
            (monthlyExpenseCategories[category] ?? 0) + transaction.amount;
      }
    }
    final totalExpense = monthlyExpenseCategories.values
        .fold<double>(0, (sum, value) => sum + value);

    final availableCategories = _getAvailableCategories(l10n);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── 1. 当月类别消费占比 ───────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.monthlyCategorySpending,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (monthlyExpenseCategories.isEmpty)
                  Text(l10n.noCategorySpending,
                      style: const TextStyle(color: AppColors.textSecondary))
                else
                  ...monthlyExpenseCategories.entries.map((entry) {
                    final ratio =
                        totalExpense == 0 ? 0.0 : entry.value / totalExpense;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(
                                '${_amount(entry.value)} ${(ratio * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            color: AppColors.primaryLight,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ─── 2. 分类聚合统计卡片 ───────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.categoryAggregation,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedCategory != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedCategory = null),
                        child: Text(l10n.cancel),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.categoryAggregationHint,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),

                // 分类芯片选择器 (横向滚动)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableCategories.map((cat) {
                      final displayName = _displayCategoryName(
                          cat.id, cat.name, l10n);
                      final isSelected = _selectedCategory?.id == cat.id ||
                          (_selectedCategory?.name == cat.name &&
                              _selectedCategory?.id == cat.id);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            cat.type == CategoryType.expense
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 14,
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          label: Text(displayName),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? cat : null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (_selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // 时间范围快捷切换
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _RangeChip(
                          label: l10n.timeRangeAll,
                          selected: _selectedTimeRange == CategoryTimeRange.all,
                          onTap: () => setState(
                              () => _selectedTimeRange = CategoryTimeRange.all),
                        ),
                        const SizedBox(width: 6),
                        _RangeChip(
                          label: l10n.timeRangeThisYear,
                          selected:
                              _selectedTimeRange == CategoryTimeRange.thisYear,
                          onTap: () => setState(() =>
                              _selectedTimeRange = CategoryTimeRange.thisYear),
                        ),
                        const SizedBox(width: 6),
                        _RangeChip(
                          label: l10n.timeRangeThisMonth,
                          selected:
                              _selectedTimeRange == CategoryTimeRange.thisMonth,
                          onTap: () => setState(() =>
                              _selectedTimeRange = CategoryTimeRange.thisMonth),
                        ),
                        const SizedBox(width: 6),
                        _RangeChip(
                          label: _selectedTimeRange ==
                                      CategoryTimeRange.custom &&
                                  _customDateRange != null
                              ? '${DateFormat('MM/dd').format(_customDateRange!.start)}-${DateFormat('MM/dd').format(_customDateRange!.end)}'
                              : l10n.timeRangeCustom,
                          selected:
                              _selectedTimeRange == CategoryTimeRange.custom,
                          onTap: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030, 12, 31),
                              initialDateRange: _customDateRange ??
                                  DateTimeRange(
                                    start: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    end: DateTime.now(),
                                  ),
                            );
                            if (picked != null) {
                              setState(() {
                                _customDateRange = picked;
                                _selectedTimeRange = CategoryTimeRange.custom;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 计算聚合数据
                  Builder(
                    builder: (context) {
                      final matched = _getFilteredCategoryTx(
                          _selectedCategory!, _selectedTimeRange, _customDateRange);
                      double expenseSum = 0;
                      double incomeSum = 0;
                      for (final t in matched) {
                        if (t.type == TransactionType.expense) {
                          expenseSum += t.amount;
                        } else {
                          incomeSum += t.amount;
                        }
                      }
                      final netAmount = incomeSum - expenseSum;

                      if (matched.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              l10n.categoryNoRecords,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // 汇总卡片
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _MetricSubItem(
                                    label: l10n.monthlyExpenseShort,
                                    value: _amount(expenseSum),
                                    color: AppColors.expense,
                                  ),
                                ),
                                Container(
                                    height: 24,
                                    width: 1,
                                    color: Theme.of(context).dividerColor),
                                Expanded(
                                  child: _MetricSubItem(
                                    label: l10n.monthlyIncomeShort,
                                    value: _amount(incomeSum),
                                    color: AppColors.income,
                                  ),
                                ),
                                Container(
                                    height: 24,
                                    width: 1,
                                    color: Theme.of(context).dividerColor),
                                Expanded(
                                  child: _MetricSubItem(
                                    label: l10n.netAmount,
                                    value: widget.privacyHidden
                                        ? '${CurrencyCatalog.byCode(widget.currencyCode).symbol} ****'
                                        : '${netAmount >= 0 ? '+' : ''}${CurrencyCatalog.byCode(widget.currencyCode).format(netAmount, 'en')}',
                                    color: netAmount >= 0
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 预览最近 5 笔
                          ...matched.take(5).map((t) {
                            final isExpense = t.type == TransactionType.expense;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isExpense
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                                color: isExpense
                                    ? AppColors.expense
                                    : AppColors.income,
                                size: 18,
                              ),
                              title: Text(
                                t.note != null && t.note!.isNotEmpty
                                    ? t.note!
                                    : _displayCategoryName(
                                        t.categoryId, t.categoryName, l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd').format(t.date),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Text(
                                '${isExpense ? '-' : '+'}${_amount(t.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isExpense
                                      ? AppColors.expense
                                      : AppColors.income,
                                ),
                              ),
                              onTap: widget.onEdit != null
                                  ? () => widget.onEdit!(t)
                                  : null,
                            );
                          }),

                          if (matched.length > 5) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CategoryDetailScreen(
                                        category: _selectedCategory!,
                                        allTransactions: _allTx,
                                        privacyHidden: widget.privacyHidden,
                                        currencyCode: widget.currencyCode,
                                        onDelete: widget.onDelete,
                                        onEdit: widget.onEdit,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.viewAllRecords(matched.length),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TransactionModel> _getFilteredCategoryTx(
    CategoryModel category,
    CategoryTimeRange range,
    DateTimeRange? customRange,
  ) {
    final now = DateTime.now();
    return _allTx.where((t) {
      final isCategoryMatch = t.categoryId == category.id ||
          t.categoryName == category.name;
      if (!isCategoryMatch) return false;

      switch (range) {
        case CategoryTimeRange.thisMonth:
          return t.date.year == now.year && t.date.month == now.month;
        case CategoryTimeRange.thisYear:
          return t.date.year == now.year;
        case CategoryTimeRange.custom:
          if (customRange == null) return true;
          return t.date.isAfter(customRange.start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(customRange.end.add(const Duration(days: 1)));
        case CategoryTimeRange.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _displayCategoryName(
      String categoryId, String fallback, AppLocalizations l10n) {
    switch (categoryId) {
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
      case 'cat_salary':
        return l10n.categorySalary;
      case 'cat_bonus':
        return l10n.categoryBonus;
      default:
        return fallback;
    }
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colors.primaryContainer,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

class _MetricSubItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricSubItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
