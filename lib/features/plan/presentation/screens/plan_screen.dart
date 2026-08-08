import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../savings/presentation/screens/savings_screen.dart';

class PlanScreen extends StatelessWidget {
  final List<SavingsGoalModel> goals;
  final bool privacyHidden;
  final String currentPeriod;
  final double monthlyBudget;
  final double monthlyExpense;
  final VoidCallback onEditBudget;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onDelete;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;

  const PlanScreen({
    super.key,
    required this.goals,
    required this.privacyHidden,
    required this.currentPeriod,
    required this.monthlyBudget,
    required this.monthlyExpense,
    required this.onEditBudget,
    required this.onAddGoal,
    required this.onDelete,
    required this.onHistory,
    required this.onDeposit,
  });

  String _amount(double value) => privacyHidden ? '¥ ****' : '¥ ${NumberFormat('#,##0.00', 'en_US').format(value)}';

  @override
  Widget build(BuildContext context) {
    final remaining = monthlyBudget - monthlyExpense;
    final progress = monthlyBudget > 0 ? (monthlyExpense / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BudgetPlanCard(
          period: currentPeriod,
          budget: monthlyBudget,
          expense: monthlyExpense,
          remaining: remaining,
          progress: progress,
          amount: _amount,
          onEdit: onEditBudget,
        ),
        const SizedBox(height: 20),
        SavingsGoalsSection(
          goals: goals,
          privacyHidden: privacyHidden,
          onAddGoal: onAddGoal,
          onDelete: onDelete,
          onHistory: onHistory,
          onDeposit: onDeposit,
        ),
      ],
    );
  }
}

class _BudgetPlanCard extends StatelessWidget {
  final String period;
  final double budget;
  final double expense;
  final double remaining;
  final double progress;
  final String Function(double) amount;
  final VoidCallback onEdit;

  const _BudgetPlanCard({required this.period, required this.budget, required this.expense, required this.remaining, required this.progress, required this.amount, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('本月预算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 3),
              Text(period, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ]),
            TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('编辑')),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _BudgetMetric(label: '预算', value: amount(budget), color: colorScheme.onSurface),
            _BudgetMetric(label: '已使用', value: amount(expense), color: AppColors.expense),
            _BudgetMetric(label: '剩余', value: amount(remaining), color: remaining >= 0 ? AppColors.income : AppColors.expense),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: progress, minHeight: 8, color: progress >= 1 ? AppColors.expense : colorScheme.primary, backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.3))),
          const SizedBox(height: 6),
          Text('本月已使用 ${(progress * 100).round()}%', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)), const SizedBox(height: 3), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color))]);
}