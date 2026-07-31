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

  String _amount(double value) => privacyHidden ? '¥ ****' : '¥ ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('存钱目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(onPressed: onAddGoal, icon: const Icon(Icons.add), label: const Text('新建目标')),
      ]),
      const SizedBox(height: 14),
      if (goals.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('还没有存钱目标', style: TextStyle(color: AppColors.textSecondary))))
      else ...goals.map(_goalCard),
    ]);
  }

  Widget _goalCard(SavingsGoalModel goal) {
    final completed = goal.currentAmount >= goal.targetAmount;
    final remainingDays = goal.remainingDays;
    final dailyNeeded = remainingDays > 0 ? goal.remainingAmount / remainingDays : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: completed ? AppColors.income : AppColors.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => onDelete(goal)),
        ]),
        Text('目标日期: ${DateFormat('yyyy-MM-dd').format(goal.targetDate)} · 剩余 $remainingDays 天', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('已存: ${_amount(goal.currentAmount)}', style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold)), Text('目标: ${_amount(goal.targetAmount)}')]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: goal.progressPercentage / 100, minHeight: 8, color: completed ? AppColors.income : AppColors.primaryLight),
        if (!completed && remainingDays > 0) ...[
          const SizedBox(height: 10),
          Text('按照当前目标，每日存入 ${_amount(dailyNeeded)} 可按时完成', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(onPressed: () => onHistory(goal), icon: const Icon(Icons.history, size: 16), label: const Text('流水明细')),
          OutlinedButton(onPressed: () => onDeposit(goal, true), child: const Text('提取')),
          const SizedBox(width: 8),
          ElevatedButton.icon(onPressed: () => onDeposit(goal, false), icon: const Icon(Icons.add), label: const Text('存入一笔')),
        ]),
      ]),
    );
  }
}
