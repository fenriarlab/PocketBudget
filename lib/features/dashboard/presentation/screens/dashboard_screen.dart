import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  final double? monthlyBudget;
  final double monthlyExpense;
  final double monthlyIncome;
  final double budgetedSavings;
  final List<SavingsGoalModel> goals;
  final String currentPeriod;
  final bool privacyHidden;
  final List<TransactionModel>? transactions;
  final DateTime? selectedMonth;
  final DateTime? selectedDate;
  final double? dailyQuota;
  final ValueChanged<DateTime>? onMonthChanged;
  final ValueChanged<DateTime>? onDateSelected;
  final ValueChanged<TransactionModel>? onDelete;
  final ValueChanged<TransactionModel>? onEdit;
  final ValueChanged<DateTime>? onAdd;

  const DashboardScreen({
    super.key,
    required this.monthlyBudget,
    required this.monthlyExpense,
    required this.monthlyIncome,
    this.budgetedSavings = 0,
    required this.goals,
    required this.currentPeriod,
    required this.privacyHidden,
    this.transactions,
    this.selectedMonth,
    this.selectedDate,
    this.dailyQuota,
    this.onMonthChanged,
    this.onDateSelected,
    this.onDelete,
    this.onEdit,
    this.onAdd,
  });

  String _amount(double value) => privacyHidden ? '¥ ****' : '¥ ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final budgetUsed = monthlyExpense + budgetedSavings;
    final remainingBudget = monthlyBudget == null ? null : monthlyBudget! - budgetUsed;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, daysInMonth);
    final dailyQuota = remainingBudget != null && remainingBudget > 0 ? remainingBudget / remainingDays : 0.0;
    final totalSavings = goals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);
    final liquidBalance = monthlyIncome - monthlyExpense;

    final summary = [
        _AssetBanner(
          totalAssets: liquidBalance + totalSavings,
          liquidBalance: liquidBalance,
          totalSavings: totalSavings,
          amount: _amount,
          privacyHidden: privacyHidden,
        ),
        _BudgetCard(
          period: currentPeriod,
          remainingBudget: remainingBudget,
          monthlyBudget: monthlyBudget,
          monthlyExpense: budgetUsed,
          amount: _amount,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text('每日建议消费上限', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(monthlyBudget == null ? '无预算限制' : '${_amount(dailyQuota)} / 天', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income)),
              const SizedBox(height: 4),
              Text(monthlyBudget == null ? '设置月度预算后可获得每日消费建议。' : '本月还剩 $remainingDays 天，控制每日开销即可保持当前计划。', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
    ];

    if (transactions == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        summary[0],
        const SizedBox(height: 16),
        summary[1],
        const SizedBox(height: 16),
        summary[2],
      ]);
    }

    final progress = monthlyBudget == null ? 0.0 : (monthlyBudget! > 0 ? (budgetUsed / monthlyBudget!).clamp(0.0, 1.0) : 0.0);

    return Column(
      children: [
        _MonthToolbar(selectedMonth: selectedMonth!, onMonthChanged: onMonthChanged!),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _MonthlySummaryCard(
            expense: _amount(monthlyExpense),
            income: _amount(monthlyIncome),
            balance: _amount(liquidBalance),
            expenseProgress: progress,
            incomeProgress: monthlyBudget == null ? 0.0 : (monthlyBudget! > 0 ? (monthlyIncome / monthlyBudget!).clamp(0.0, 1.0) : 0.0),
          ),
        ),
        Expanded(
          child: TransactionsScreen(
            transactions: transactions!,
            selectedMonth: selectedMonth!,
            selectedDate: selectedDate!,
            dailyQuota: this.dailyQuota ?? dailyQuota,
            privacyHidden: privacyHidden,
            calendarView: true,
            onMonthChanged: onMonthChanged!,
            onDateSelected: onDateSelected!,
            onDelete: onDelete!,
            onEdit: onEdit!,
            onAdd: onAdd!,
          ),
        ),
      ],
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final String expense;
  final String income;
  final String balance;
  final double expenseProgress;
  final double incomeProgress;

  const _MonthlySummaryCard({required this.expense, required this.income, required this.balance, required this.expenseProgress, required this.incomeProgress});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black38 : const Color(0x18000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
      children: [
          Row(
            children: [
              Expanded(child: _Metric(label: '月支出', value: expense, color: AppColors.expense)),
              Expanded(child: _Metric(label: '月收入', value: income, color: AppColors.income)),
              Expanded(child: _Metric(label: '结余', value: balance, color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ProgressLine(label: '${(expenseProgress * 100).round()}% 预算', value: expenseProgress, color: AppColors.expense)),
              const SizedBox(width: 18),
              Expanded(child: _ProgressLine(label: '${(incomeProgress * 100).round()}% 预算', value: incomeProgress, color: AppColors.income)),
            ],
          ),
      ],
      ),
    );
  }
}

class _MonthToolbar extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthToolbar({required this.selectedMonth, required this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1))),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: selectedMonth, firstDate: DateTime(2020), lastDate: DateTime(2030, 12, 31), helpText: '选择月份');
              if (picked != null) onMonthChanged(DateTime(picked.year, picked.month));
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(DateFormat('yyyy 年 MM 月').format(selectedMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_month_outlined, size: 18),
              ]),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (!isCurrentMonth) TextButton(onPressed: () => onMonthChanged(DateTime(now.year, now.month)), child: const Text('今天')),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1))),
          ]),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      const SizedBox(height: 5),
      FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
    ]);
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressLine({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
      const SizedBox(height: 5),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value, minHeight: 5, backgroundColor: color.withValues(alpha: 0.14), color: color)),
    ]);
  }
}

class _AssetBanner extends StatelessWidget {
  final double totalAssets;
  final double liquidBalance;
  final double totalSavings;
  final String Function(double) amount;
  final bool privacyHidden;

  const _AssetBanner({required this.totalAssets, required this.liquidBalance, required this.totalSavings, required this.amount, required this.privacyHidden});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('个人总资产', style: TextStyle(color: Colors.white70, fontSize: 13)),
            Icon(privacyHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 16),
          ]),
          const SizedBox(height: 6),
          Text(amount(totalAssets), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('流动余额: ${amount(liquidBalance)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('存钱积蓄: ${amount(totalSavings)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String period;
  final double? remainingBudget;
  final double? monthlyBudget;
  final double monthlyExpense;
  final String Function(double) amount;

  const _BudgetCard({required this.period, required this.remainingBudget, required this.monthlyBudget, required this.monthlyExpense, required this.amount});

  @override
  Widget build(BuildContext context) {
    final progress = monthlyBudget == null ? null : (monthlyBudget! > 0 ? (monthlyExpense / monthlyBudget!).clamp(0.0, 1.0) : 0.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.black38 : const Color(0x18000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(monthlyBudget == null ? '本月预算 ($period)' : '本月剩余可用预算 ($period)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 8),
        Text(monthlyBudget == null ? '无预算限制' : amount(remainingBudget!), style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: remainingBudget == null || remainingBudget! >= 0 ? Theme.of(context).colorScheme.onSurface : AppColors.expense)),
        if (progress != null) ...[
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35), color: progress > 0.9 ? AppColors.expense : AppColors.primaryLight)),
        ],
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(monthlyBudget == null ? '预算：未设置' : '预算: ${amount(monthlyBudget!)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          Text('已支出: ${amount(monthlyExpense)}', style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}
