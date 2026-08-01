import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  final double monthlyBudget;
  final double monthlyExpense;
  final double monthlyIncome;
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
  final ValueChanged<DateTime>? onAdd;

  const DashboardScreen({
    super.key,
    required this.monthlyBudget,
    required this.monthlyExpense,
    required this.monthlyIncome,
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
    this.onAdd,
  });

  String _amount(double value) => privacyHidden ? '¥ ****' : '¥ ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final remainingBudget = monthlyBudget - monthlyExpense;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, daysInMonth);
    final dailyQuota = remainingBudget > 0 ? remainingBudget / remainingDays : 0.0;
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
          monthlyExpense: monthlyExpense,
          amount: _amount,
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
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
              Text('${_amount(dailyQuota)} / 天', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income)),
              const SizedBox(height: 4),
              Text('本月还剩 $remainingDays 天，控制每日开销即可保持当前计划。', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(child: _SummaryMetric(label: '月支出', value: _amount(monthlyExpense), color: AppColors.expense)),
              Expanded(child: _SummaryMetric(label: '月收入', value: _amount(monthlyIncome), color: AppColors.income)),
              Expanded(child: _SummaryMetric(label: '结余', value: _amount(liquidBalance), color: AppColors.textPrimary)),
            ],
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
            onAdd: onAdd!,
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(alignment: Alignment.centerLeft, fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      ],
    );
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
  final double remainingBudget;
  final double monthlyBudget;
  final double monthlyExpense;
  final String Function(double) amount;

  const _BudgetCard({required this.period, required this.remainingBudget, required this.monthlyBudget, required this.monthlyExpense, required this.amount});

  @override
  Widget build(BuildContext context) {
    final progress = monthlyBudget > 0 ? (monthlyExpense / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('本月剩余可用预算 ($period)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Text(amount(remainingBudget), style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: remainingBudget >= 0 ? AppColors.textPrimary : AppColors.expense)),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white10, color: progress > 0.9 ? AppColors.expense : AppColors.primaryLight)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('预算: ${amount(monthlyBudget)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text('已支出: ${amount(monthlyExpense)}', style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}
