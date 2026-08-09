import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../savings/presentation/screens/savings_screen.dart';

class PlanScreen extends StatelessWidget {
  final List<SavingsGoalModel> goals;
  final List<SavingsGoalModel> archivedGoals;
  final bool privacyHidden;
  final String currentPeriod;
  final double? monthlyBudget;
  final double monthlyExpense;
  final double monthlyBudgetedSavings;
  final VoidCallback onEditBudget;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onArchive;
  final ValueChanged<SavingsGoalModel> onEdit;
  final ValueChanged<SavingsGoalModel> onRestore;
  final ValueChanged<SavingsGoalModel> onPurge;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;

  const PlanScreen({
    super.key,
    required this.goals,
    this.archivedGoals = const [],
    required this.privacyHidden,
    required this.currentPeriod,
    required this.monthlyBudget,
    required this.monthlyExpense,
    this.monthlyBudgetedSavings = 0,
    required this.onEditBudget,
    required this.onAddGoal,
    required this.onArchive,
    required this.onEdit,
    required this.onRestore,
    required this.onPurge,
    required this.onHistory,
    required this.onDeposit,
  });

  String _amount(double value) => privacyHidden
      ? '¥ ****'
      : '¥ ${NumberFormat('#,##0.00', 'en_US').format(value)}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetUsed = monthlyExpense + monthlyBudgetedSavings;
    final remaining =
        monthlyBudget == null ? null : monthlyBudget! - budgetUsed;
    final progress = monthlyBudget == null
        ? null
        : (monthlyBudget! > 0
            ? (budgetUsed / monthlyBudget!).clamp(0.0, 1.0)
            : 0.0);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BudgetPlanCard(
          period: currentPeriod,
          budget: monthlyBudget,
          expense: budgetUsed,
          remaining: remaining,
          progress: progress,
          amount: _amount,
          onEdit: onEditBudget,
          l10n: l10n,
        ),
        const SizedBox(height: 20),
        SavingsGoalsSection(
          goals: goals,
          archivedGoals: archivedGoals,
          privacyHidden: privacyHidden,
          onAddGoal: onAddGoal,
          onArchive: onArchive,
          onEdit: onEdit,
          onRestore: onRestore,
          onPurge: onPurge,
          onHistory: onHistory,
          onDeposit: onDeposit,
        ),
      ],
    );
  }
}

class _BudgetPlanCard extends StatelessWidget {
  final String period;
  final double? budget;
  final double expense;
  final double? remaining;
  final double? progress;
  final String Function(double) amount;
  final VoidCallback onEdit;
  final AppLocalizations l10n;

  const _BudgetPlanCard(
      {required this.period,
      required this.budget,
      required this.expense,
      required this.remaining,
      required this.progress,
      required this.amount,
      required this.onEdit,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.monthlyBudgetTitle,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface)),
              const SizedBox(height: 3),
              Text(period,
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant)),
            ]),
            TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.edit)),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _BudgetMetric(
                label: l10n.budgetLabel,
                value: budget == null ? l10n.noBudgetLimit : amount(budget!),
                color: colorScheme.onSurface),
            _BudgetMetric(
                label: l10n.usedLabel,
                value: amount(expense),
                color: AppColors.expense),
            _BudgetMetric(
                label: l10n.remainingLabel,
                value:
                    remaining == null ? l10n.notApplicable : amount(remaining!),
                color: remaining == null || remaining! >= 0
                    ? AppColors.income
                    : AppColors.expense),
          ]),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: progress! >= 1
                        ? AppColors.expense
                        : colorScheme.primary,
                    backgroundColor:
                        colorScheme.outlineVariant.withValues(alpha: 0.3))),
            const SizedBox(height: 6),
            Text(l10n.monthlyUsedPercent((progress! * 100).round()),
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ] else
            Text(l10n.budgetNotSetHint,
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetMetric(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color))
      ]);
}
