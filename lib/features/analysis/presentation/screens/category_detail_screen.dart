import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../transactions/data/models/transaction_model.dart';

enum CategoryTimeRange { all, thisYear, thisMonth, custom }

/// 分类聚合全量账单明细页
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  final List<TransactionModel> allTransactions;
  final bool privacyHidden;
  final String currencyCode;
  final ValueChanged<TransactionModel>? onDelete;
  final ValueChanged<TransactionModel>? onEdit;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.allTransactions,
    required this.privacyHidden,
    this.currencyCode = 'CNY',
    this.onDelete,
    this.onEdit,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  CategoryTimeRange _selectedRange = CategoryTimeRange.all;
  DateTimeRange? _customDateRange;

  String _formatAmount(double value) {
    if (widget.privacyHidden) {
      return '${CurrencyCatalog.byCode(widget.currencyCode).symbol} ****';
    }
    return CurrencyCatalog.byCode(widget.currencyCode).format(value, 'en');
  }

  List<TransactionModel> _getFilteredTransactions() {
    final now = DateTime.now();
    final matching = widget.allTransactions.where((t) {
      if (t.categoryId != widget.category.id &&
          t.categoryName != widget.category.name) {
        return false;
      }
      switch (_selectedRange) {
        case CategoryTimeRange.thisMonth:
          return t.date.year == now.year && t.date.month == now.month;
        case CategoryTimeRange.thisYear:
          return t.date.year == now.year;
        case CategoryTimeRange.custom:
          if (_customDateRange == null) return true;
          return t.date.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
        case CategoryTimeRange.all:
          return true;
      }
    }).toList();

    matching.sort((a, b) => b.date.compareTo(a.date));
    return matching;
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedRange = CategoryTimeRange.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _getFilteredTransactions();

    double expenseSum = 0;
    double incomeSum = 0;
    for (final t in filtered) {
      if (t.type == TransactionType.expense) {
        expenseSum += t.amount;
      } else {
        incomeSum += t.amount;
      }
    }
    final netAmount = incomeSum - expenseSum;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryDetailTitle(widget.category.name)),
      ),
      body: Column(
        children: [
          // ─── 过滤器 + 统计卡片 ─────────────────────────────────────
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // 时间范围选择
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _RangeChip(
                        label: l10n.timeRangeAll,
                        selected: _selectedRange == CategoryTimeRange.all,
                        onTap: () => setState(() => _selectedRange = CategoryTimeRange.all),
                      ),
                      const SizedBox(width: 8),
                      _RangeChip(
                        label: l10n.timeRangeThisYear,
                        selected: _selectedRange == CategoryTimeRange.thisYear,
                        onTap: () => setState(() => _selectedRange = CategoryTimeRange.thisYear),
                      ),
                      const SizedBox(width: 8),
                      _RangeChip(
                        label: l10n.timeRangeThisMonth,
                        selected: _selectedRange == CategoryTimeRange.thisMonth,
                        onTap: () => setState(() => _selectedRange = CategoryTimeRange.thisMonth),
                      ),
                      const SizedBox(width: 8),
                      _RangeChip(
                        label: _selectedRange == CategoryTimeRange.custom && _customDateRange != null
                            ? '${DateFormat('MM/dd').format(_customDateRange!.start)}-${DateFormat('MM/dd').format(_customDateRange!.end)}'
                            : l10n.timeRangeCustom,
                        selected: _selectedRange == CategoryTimeRange.custom,
                        onTap: _selectCustomRange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 汇总指标卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricItem(
                          label: l10n.monthlyExpenseShort,
                          value: _formatAmount(expenseSum),
                          color: AppColors.expense,
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _MetricItem(
                          label: l10n.monthlyIncomeShort,
                          value: _formatAmount(incomeSum),
                          color: AppColors.income,
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _MetricItem(
                          label: l10n.netAmount,
                          value: widget.privacyHidden
                              ? '${CurrencyCatalog.byCode(widget.currencyCode).symbol} ****'
                              : '${netAmount >= 0 ? '+' : ''}${CurrencyCatalog.byCode(widget.currencyCode).format(netAmount, 'en')}',
                          color: netAmount >= 0 ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── 交易明细列表 ─────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.categoryNoRecords,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isExpense = item.type == TransactionType.expense;
                      return Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isExpense
                                ? AppColors.expense.withValues(alpha: 0.12)
                                : AppColors.income.withValues(alpha: 0.12),
                            child: Icon(
                              isExpense ? Icons.north_east : Icons.south_west,
                              color: isExpense ? AppColors.expense : AppColors.income,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.note != null && item.note!.isNotEmpty
                                ? item.note!
                                : item.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
                                .format(item.date),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            '${isExpense ? '-' : '+'}${_formatAmount(item.amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpense ? AppColors.expense : AppColors.income,
                            ),
                          ),
                          onTap: widget.onEdit != null ? () => widget.onEdit!(item) : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
      labelStyle: TextStyle(
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
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
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
