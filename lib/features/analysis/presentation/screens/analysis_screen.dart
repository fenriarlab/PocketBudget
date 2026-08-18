import 'dart:math' as math;
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
  TransactionType _analysisType = TransactionType.expense;
  CategoryTimeRange _selectedTimeRange = CategoryTimeRange.thisMonth;
  DateTimeRange? _customDateRange;

  String _formatAmount(double value) {
    if (widget.privacyHidden) {
      return '${CurrencyCatalog.byCode(widget.currencyCode).symbol} ****';
    }
    return CurrencyCatalog.byCode(widget.currencyCode).format(value, 'en');
  }

  List<TransactionModel> get _allTx =>
      widget.allTransactions ?? widget.transactions;

  Map<String, CategoryModel> _getCategoryLookup(AppLocalizations l10n) {
    final map = <String, CategoryModel>{};
    for (final cat in widget.categories) {
      map[cat.id] = cat;
    }
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
    return map;
  }

  List<TransactionModel> _getFilteredTransactions() {
    final now = DateTime.now();
    return _allTx.where((t) {
      if (t.type != _analysisType) return false;

      switch (_selectedTimeRange) {
        case CategoryTimeRange.thisMonth:
          return t.date.year == now.year && t.date.month == now.month;
        case CategoryTimeRange.thisYear:
          return t.date.year == now.year;
        case CategoryTimeRange.custom:
          if (_customDateRange == null) return true;
          return t.date.isAfter(
                  _customDateRange!.start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(
                  _customDateRange!.end.add(const Duration(days: 1)));
        case CategoryTimeRange.all:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int _calculateDaysInPeriod() {
    final now = DateTime.now();
    switch (_selectedTimeRange) {
      case CategoryTimeRange.thisMonth:
        return now.day.clamp(1, 31);
      case CategoryTimeRange.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        return now.difference(startOfYear).inDays + 1;
      case CategoryTimeRange.custom:
        if (_customDateRange == null) return 30;
        final days = _customDateRange!.end.difference(_customDateRange!.start).inDays + 1;
        return days.clamp(1, 3650);
      case CategoryTimeRange.all:
        if (_allTx.isEmpty) return 1;
        final dates = _allTx.map((e) => e.date).toList()..sort();
        final days = dates.last.difference(dates.first).inDays + 1;
        return days.clamp(1, 36500);
    }
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
        return fallback;
    }
  }

  Future<void> _pickCustomDateRange() async {
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
        _selectedTimeRange = CategoryTimeRange.custom;
      });
    }
  }

  void _navigateToCategoryDetail(CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryDetailScreen(
          category: category,
          allTransactions: _allTx,
          privacyHidden: widget.privacyHidden,
          currencyCode: widget.currencyCode,
          initialTimeRange: _selectedTimeRange,
          initialCustomRange: _customDateRange,
          onDelete: widget.onDelete,
          onEdit: widget.onEdit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryLookup = _getCategoryLookup(l10n);

    final filteredTx = _getFilteredTransactions();

    // 聚合各分类金额与笔数
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};
    double totalSum = 0;
    double maxSingleTxAmount = 0;
    TransactionModel? maxSingleTx;

    for (final tx in filteredTx) {
      categoryTotals[tx.categoryId] =
          (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
      categoryCounts[tx.categoryId] =
          (categoryCounts[tx.categoryId] ?? 0) + 1;
      totalSum += tx.amount;
      if (tx.amount > maxSingleTxAmount) {
        maxSingleTxAmount = tx.amount;
        maxSingleTx = tx;
      }
    }

    final days = _calculateDaysInPeriod();
    final dailyAvg = days > 0 ? totalSum / days : 0.0;

    // 构造排行榜项数据
    final statList = <_CategoryStat>[];
    for (final entry in categoryTotals.entries) {
      final cat = categoryLookup[entry.key] ??
          CategoryModel(
            id: entry.key,
            name: entry.key,
            icon: '🏷️',
            colorHex: '#8791A5',
            type: _analysisType == TransactionType.expense
                ? CategoryType.expense
                : CategoryType.income,
            isCustom: false,
          );
      final ratio = totalSum > 0 ? entry.value / totalSum : 0.0;
      statList.add(_CategoryStat(
        category: cat,
        displayName: _displayCategoryName(cat.id, cat.name, l10n),
        amount: entry.value,
        count: categoryCounts[entry.key] ?? 0,
        ratio: ratio,
        color: parseHexColor(cat.colorHex),
      ));
    }
    statList.sort((a, b) => b.amount.compareTo(a.amount));

    final isExpense = _analysisType == TransactionType.expense;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ─── 1. 顶部时间范围胶囊与收支切换器 ─────────────────────────
        _buildTopControls(context, l10n, isDark),
        const SizedBox(height: 14),

        // ─── 2. Hero 数据图表与指标大卡 ──────────────────────────────
        _buildHeroChartCard(
          context,
          l10n,
          isDark,
          statList,
          totalSum,
          filteredTx.length,
          dailyAvg,
          maxSingleTxAmount,
          maxSingleTx,
          isExpense,
        ),
        const SizedBox(height: 16),

        // ─── 3. 分类占比排行榜 ─────────────────────────────────────────
        if (statList.isEmpty)
          _buildEmptyState(context, l10n, isDark)
        else
          _buildLeaderboardSection(
            context,
            l10n,
            isDark,
            statList,
            totalSum,
          ),
      ],
    );
  }

  // 顶部时间与收支分段器
  Widget _buildTopControls(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 收支 Segmented Button
        Row(
          children: [
            Expanded(
              child: _TypeSegmentButton(
                label: l10n.expenseAnalysis,
                icon: Icons.north_east_rounded,
                selected: _analysisType == TransactionType.expense,
                activeColor: AppColors.expense,
                onTap: () {
                  if (_analysisType != TransactionType.expense) {
                    setState(() {
                      _analysisType = TransactionType.expense;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TypeSegmentButton(
                label: l10n.incomeAnalysis,
                icon: Icons.south_west_rounded,
                selected: _analysisType == TransactionType.income,
                activeColor: AppColors.income,
                onTap: () {
                  if (_analysisType != TransactionType.income) {
                    setState(() {
                      _analysisType = TransactionType.income;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 时间快捷胶囊滚动条
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterCapsule(
                label: l10n.timeRangeThisMonth,
                selected: _selectedTimeRange == CategoryTimeRange.thisMonth,
                onTap: () => setState(() =>
                    _selectedTimeRange = CategoryTimeRange.thisMonth),
              ),
              const SizedBox(width: 8),
              _FilterCapsule(
                label: l10n.timeRangeThisYear,
                selected: _selectedTimeRange == CategoryTimeRange.thisYear,
                onTap: () => setState(
                    () => _selectedTimeRange = CategoryTimeRange.thisYear),
              ),
              const SizedBox(width: 8),
              _FilterCapsule(
                label: l10n.timeRangeAll,
                selected: _selectedTimeRange == CategoryTimeRange.all,
                onTap: () =>
                    setState(() => _selectedTimeRange = CategoryTimeRange.all),
              ),
              const SizedBox(width: 8),
              _FilterCapsule(
                label: _selectedTimeRange == CategoryTimeRange.custom &&
                        _customDateRange != null
                    ? '${DateFormat('MM/dd').format(_customDateRange!.start)} - ${DateFormat('MM/dd').format(_customDateRange!.end)}'
                    : l10n.timeRangeCustom,
                selected: _selectedTimeRange == CategoryTimeRange.custom,
                onTap: _pickCustomDateRange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Hero 图表与指标卡片
  Widget _buildHeroChartCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    List<_CategoryStat> statList,
    double totalSum,
    int count,
    double dailyAvg,
    double maxAmount,
    TransactionModel? maxTx,
    bool isExpense,
  ) {
    final theme = Theme.of(context);
    final totalLabel = isExpense ? l10n.totalSpending : l10n.totalIncome;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 环形图与中心总额
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  stats: statList,
                  backgroundColor: isDark
                      ? const Color(0xFF242832)
                      : const Color(0xFFE9EDF5),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatAmount(totalSum),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isExpense
                                  ? (isDark
                                      ? const Color(0xFFFF8A8A)
                                      : AppColors.expense)
                                  : (isDark
                                      ? const Color(0xFF4EE8A2)
                                      : AppColors.income),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 核心 4 宫格指标
          Row(
            children: [
              Expanded(
                child: _HeroMetricItem(
                  icon: Icons.receipt_long_rounded,
                  label: l10n.transactionCountLabel,
                  value: '$count 笔',
                  isDark: isDark,
                ),
              ),
              Container(
                height: 32,
                width: 1,
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
              Expanded(
                child: _HeroMetricItem(
                  icon: Icons.calendar_today_rounded,
                  label: l10n.dailyAverage,
                  value: _formatAmount(dailyAvg),
                  isDark: isDark,
                ),
              ),
              Container(
                height: 32,
                width: 1,
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
              Expanded(
                child: _HeroMetricItem(
                  icon: Icons.arrow_upward_rounded,
                  label: l10n.maxSingleTransaction,
                  value: _formatAmount(maxAmount),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 空状态提示
  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noTransactionsInPeriod,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 分类占比排行榜卡片列表
  Widget _buildLeaderboardSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    List<_CategoryStat> statList,
    double totalSum,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标头
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.categoryLeaderboard,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${statList.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tapCategoryToFilter,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // 榜单行
          ...List.generate(statList.length, (index) {
            final item = statList[index];
            return _LeaderboardRow(
              rank: index + 1,
              stat: item,
              amountText: _formatAmount(item.amount),
              isDark: isDark,
              onTap: () => _navigateToCategoryDetail(item.category),
            );
          }),
        ],
      ),
    );
  }
}

// ─── 辅助组件与数据模型 ────────────────────────────────────────────────

class _CategoryStat {
  final CategoryModel category;
  final String displayName;
  final double amount;
  final int count;
  final double ratio;
  final Color color;

  const _CategoryStat({
    required this.category,
    required this.displayName,
    required this.amount,
    required this.count,
    required this.ratio,
    required this.color,
  });
}

/// 环形占比图 Painter
class _DonutChartPainter extends CustomPainter {
  final List<_CategoryStat> stats;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.stats,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 16.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 绘制底环
    canvas.drawCircle(center, radius, bgPaint);

    if (stats.isEmpty) return;

    var startAngle = -math.pi / 2;
    const totalAngle = 2 * math.pi;
    const gapAngle = 0.04; // 弧段间隙

    for (final stat in stats) {
      if (stat.ratio <= 0) continue;
      final sweepAngle = stat.ratio * totalAngle;
      final actualSweep = math.max(0.01, sweepAngle - gapAngle);

      final paint = Paint()
        ..color = stat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + (gapAngle / 2),
        actualSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}

/// 顶部收支切换按钮
class _TypeSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: isDark ? 0.22 : 0.14)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? activeColor.withValues(alpha: 0.6)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? activeColor
                    : (isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isDark
                          ? AppColors.textSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 过滤胶囊
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
          duration: const Duration(milliseconds: 180),
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
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero 指标子项
class _HeroMetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _HeroMetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// 排行榜单行
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final _CategoryStat stat;
  final String amountText;
  final bool isDark;
  final VoidCallback onTap;

  const _LeaderboardRow({
    required this.rank,
    required this.stat,
    required this.amountText,
    required this.isDark,
    required this.onTap,
  });

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB300); // 金
      case 2:
        return const Color(0xFFB0BEC5); // 银
      case 3:
        return const Color(0xFFCD7F32); // 铜
      default:
        return const Color(0xFF8791A5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pctText = '${(stat.ratio * 100).toStringAsFixed(1)}%';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1B1E26)
                  : const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.02),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Rank 徽章
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? _rankColor().withValues(alpha: 0.18)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _rankColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 分类图标
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: stat.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: buildCategoryIconWidget(stat.category.icon,
                          size: 16, iconColor: stat.color),
                    ),
                    const SizedBox(width: 10),

                    // 分类名称与笔数
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              stat.displayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${stat.count}笔',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 金额与百分比
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          pctText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: stat.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondary.withValues(alpha: 0.5)
                          : AppColors.lightTextSecondary
                              .withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 进度条
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stat.ratio.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark
                        ? const Color(0xFF262B36)
                        : const Color(0xFFE4E9F2),
                    valueColor: AlwaysStoppedAnimation<Color>(stat.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
