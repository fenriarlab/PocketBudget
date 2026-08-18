import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../transactions/data/models/transaction_model.dart';

enum CategoryTimeRange { all, thisYear, thisMonth, custom }

Color parseHexColor(String? hex, {Color fallback = const Color(0xFF8791A5)}) {
  if (hex == null || hex.isEmpty) return fallback;
  var clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) clean = 'FF$clean';
  final value = int.tryParse(clean, radix: 16);
  return value != null ? Color(value) : fallback;
}

Widget buildCategoryIconWidget(
  String iconStr, {
  double size = 20,
  Color? iconColor,
}) {
  if (iconStr.isEmpty) {
    return Icon(Icons.category_rounded, size: size, color: iconColor);
  }
  final runes = iconStr.runes.toList();
  if (runes.length <= 2 && runes.first > 127) {
    return Text(
      iconStr,
      style: TextStyle(fontSize: size, height: 1.1),
    );
  }
  switch (iconStr.toLowerCase()) {
    case 'food':
    case 'restaurant':
      return Icon(Icons.restaurant_rounded, size: size, color: iconColor);
    case 'transport':
    case 'directions_bus':
      return Icon(Icons.directions_bus_rounded, size: size, color: iconColor);
    case 'shopping':
    case 'shopping_bag':
      return Icon(Icons.shopping_bag_rounded, size: size, color: iconColor);
    case 'housing':
    case 'home':
      return Icon(Icons.home_rounded, size: size, color: iconColor);
    case 'entertainment':
    case 'sports_esports':
      return Icon(Icons.sports_esports_rounded, size: size, color: iconColor);
    case 'salary':
    case 'attach_money':
      return Icon(Icons.attach_money_rounded, size: size, color: iconColor);
    case 'bonus':
    case 'trending_up':
      return Icon(Icons.trending_up_rounded, size: size, color: iconColor);
    default:
      return Icon(Icons.category_rounded, size: size, color: iconColor);
  }
}

/// 分类聚合全量账单明细页
class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;
  final List<TransactionModel> allTransactions;
  final bool privacyHidden;
  final String currencyCode;
  final CategoryTimeRange initialTimeRange;
  final DateTimeRange? initialCustomRange;
  final ValueChanged<TransactionModel>? onDelete;
  final ValueChanged<TransactionModel>? onEdit;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.allTransactions,
    required this.privacyHidden,
    this.currencyCode = 'CNY',
    this.initialTimeRange = CategoryTimeRange.all,
    this.initialCustomRange,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late CategoryTimeRange _selectedRange = widget.initialTimeRange;
  late DateTimeRange? _customDateRange = widget.initialCustomRange;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _getFilteredTransactions();
    final catColor = parseHexColor(widget.category.colorHex);
    final isExpense = widget.category.type == CategoryType.expense;

    double totalSum = 0;
    for (final t in filtered) {
      totalSum += t.amount;
    }
    final avgAmount = filtered.isEmpty ? 0.0 : totalSum / filtered.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryDetailTitle(widget.category.name)),
      ),
      body: Column(
        children: [
          // ─── 顶部 Hero 统计与筛选卡片 ─────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 类别标头与主要金额
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: buildCategoryIconWidget(
                        widget.category.icon,
                        size: 24,
                        iconColor: catColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.category.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isExpense
                                          ? AppColors.expense
                                          : AppColors.income)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isExpense ? l10n.expenseType : l10n.incomeType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isExpense
                                        ? AppColors.expense
                                        : AppColors.income,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatAmount(totalSum),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isExpense
                                  ? (isDark ? const Color(0xFFFF8B8B) : AppColors.expense)
                                  : (isDark ? const Color(0xFF4EE8A2) : AppColors.income),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 统计小指标行
                Row(
                  children: [
                    Expanded(
                      child: _MetricBadge(
                        label: l10n.transactionCountLabel,
                        value: '${filtered.length}',
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                    Expanded(
                      child: _MetricBadge(
                        label: l10n.averagePerTx,
                        value: _formatAmount(avgAmount),
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 时间范围选择
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterCapsule(
                        label: l10n.timeRangeAll,
                        selected: _selectedRange == CategoryTimeRange.all,
                        onTap: () => setState(
                            () => _selectedRange = CategoryTimeRange.all),
                      ),
                      const SizedBox(width: 8),
                      _FilterCapsule(
                        label: l10n.timeRangeThisYear,
                        selected: _selectedRange == CategoryTimeRange.thisYear,
                        onTap: () => setState(
                            () => _selectedRange = CategoryTimeRange.thisYear),
                      ),
                      const SizedBox(width: 8),
                      _FilterCapsule(
                        label: l10n.timeRangeThisMonth,
                        selected: _selectedRange == CategoryTimeRange.thisMonth,
                        onTap: () => setState(
                            () => _selectedRange = CategoryTimeRange.thisMonth),
                      ),
                      const SizedBox(width: 8),
                      _FilterCapsule(
                        label: _selectedRange == CategoryTimeRange.custom &&
                                _customDateRange != null
                            ? '${DateFormat('MM/dd').format(_customDateRange!.start)} - ${DateFormat('MM/dd').format(_customDateRange!.end)}'
                            : l10n.timeRangeCustom,
                        selected: _selectedRange == CategoryTimeRange.custom,
                        onTap: _selectCustomRange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── 交易流水列表 ─────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.categoryNoRecords,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final itemIsExpense =
                          item.type == TransactionType.expense;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onEdit != null
                              ? () => widget.onEdit!(item)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: (itemIsExpense
                                            ? AppColors.expense
                                            : AppColors.income)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    itemIsExpense
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: itemIsExpense
                                        ? AppColors.expense
                                        : AppColors.income,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.note != null &&
                                                item.note!.isNotEmpty
                                            ? item.note!
                                            : item.categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('yyyy-MM-dd HH:mm')
                                            .format(item.date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${itemIsExpense ? '-' : '+'}${_formatAmount(item.amount)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: itemIsExpense
                                        ? AppColors.expense
                                        : AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _FilterCapsule extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterCapsule({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? const Color(0xFF232730)
                    : const Color(0xFFEEF2F8)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? Colors.white
                  : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
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
        const SizedBox(height: 2),
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
