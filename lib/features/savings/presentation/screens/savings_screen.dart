import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/savings_goal_model.dart';

class SavingsScreen extends StatelessWidget {
  final List<SavingsGoalModel> goals;
  final bool privacyHidden;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onDelete;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;

  const SavingsScreen({super.key, required this.goals, required this.privacyHidden, required this.onAddGoal, required this.onDelete, required this.onHistory, required this.onDeposit});

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [SavingsGoalsSection(goals: goals, privacyHidden: privacyHidden, onAddGoal: onAddGoal, onDelete: onDelete, onHistory: onHistory, onDeposit: onDeposit)]);
}

class SavingsGoalsSection extends StatelessWidget {
  final List<SavingsGoalModel> goals;
  final bool privacyHidden;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onDelete;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;

  const SavingsGoalsSection({super.key, required this.goals, required this.privacyHidden, required this.onAddGoal, required this.onDelete, required this.onHistory, required this.onDeposit});

  String _amount(double value) => privacyHidden ? '¥ ****' : '¥ ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('存钱目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(onPressed: onAddGoal, icon: const Icon(Icons.add), label: const Text('新建目标')),
      ]),
      const SizedBox(height: 14),
      if (goals.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('还没有存钱目标', style: TextStyle(color: AppColors.textSecondary))))
      else ...goals.map((goal) => _goalCard(context, goal)),
    ]);
  }

  Widget _goalCard(BuildContext context, SavingsGoalModel goal) {
    final colorScheme = Theme.of(context).colorScheme;
    final completed = goal.currentAmount >= goal.targetAmount;
    final remainingDays = goal.remainingDays;
    final dailyNeeded = remainingDays > 0 ? goal.remainingAmount / remainingDays : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: completed ? AppColors.income : colorScheme.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(goal.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface), overflow: TextOverflow.ellipsis)),
          PopupMenuButton<String>(
            tooltip: '目标操作',
            onSelected: (value) async {
              if (value == 'delete' && await _confirmDelete(context, goal)) onDelete(goal);
            },
            itemBuilder: (context) => const [PopupMenuItem(value: 'delete', child: Text('删除目标'))],
          ),
        ]),
        Text('目标日期: ${DateFormat('yyyy-MM-dd').format(goal.targetDate)} · 剩余 $remainingDays 天', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('已存: ${_amount(goal.currentAmount)}', style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold)), Text('目标: ${_amount(goal.targetAmount)}', style: TextStyle(color: colorScheme.onSurface))]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: goal.progressPercentage / 100, minHeight: 8, color: completed ? AppColors.income : colorScheme.primary),
        if (!completed && remainingDays > 0) ...[
          const SizedBox(height: 10),
          Text('按照当前目标，每日存入 ${_amount(dailyNeeded)} 可按时完成', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
          TextButton.icon(onPressed: () => onHistory(goal), icon: const Icon(Icons.history, size: 16), label: const Text('流水明细')),
          OutlinedButton(onPressed: () => onDeposit(goal, true), child: const Text('提取')),
          ElevatedButton.icon(onPressed: () => onDeposit(goal, false), icon: const Icon(Icons.add), label: const Text('存入一笔')),
        ]),
      ]),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, SavingsGoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除存钱目标？'),
        content: Text('将同时删除“${goal.title}”的存取记录和已关联的预算支出。此操作无法撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('删除')),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
