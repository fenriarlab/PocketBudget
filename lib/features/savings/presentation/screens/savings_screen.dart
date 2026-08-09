import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/savings_goal_model.dart';

class SavingsScreen extends StatelessWidget {
  final List<SavingsGoalModel> goals;
  final List<SavingsGoalModel> archivedGoals;
  final bool privacyHidden;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onArchive;
  final ValueChanged<SavingsGoalModel> onEdit;
  final ValueChanged<SavingsGoalModel> onRestore;
  final ValueChanged<SavingsGoalModel> onPurge;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;

  const SavingsScreen(
      {super.key,
      required this.goals,
      this.archivedGoals = const [],
      required this.privacyHidden,
      required this.onAddGoal,
      required this.onArchive,
      required this.onEdit,
      required this.onRestore,
      required this.onPurge,
      required this.onHistory,
      required this.onDeposit});

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(16), children: [
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
            onDeposit: onDeposit)
      ]);
}

class SavingsGoalsSection extends StatelessWidget {
  final List<SavingsGoalModel> goals;
  final List<SavingsGoalModel> archivedGoals;
  final bool privacyHidden;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onArchive;
  final ValueChanged<SavingsGoalModel> onEdit;
  final ValueChanged<SavingsGoalModel> onRestore;
  final ValueChanged<SavingsGoalModel> onPurge;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;

  const SavingsGoalsSection(
      {super.key,
      required this.goals,
      this.archivedGoals = const [],
      required this.privacyHidden,
      required this.onAddGoal,
      required this.onArchive,
      required this.onEdit,
      required this.onRestore,
      required this.onPurge,
      required this.onHistory,
      required this.onDeposit});

  String _amount(double value) => privacyHidden
      ? '¥ ****'
      : '¥ ${NumberFormat('#,##0.00', 'en_US').format(value)}';

  @override
  Widget build(BuildContext context) => _SectionContent(
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
        buildCard: (goal, archived) => _goalCard(context, goal, archived),
      );

  Widget _goalCard(BuildContext context, SavingsGoalModel goal, bool archived) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final completed = goal.currentAmount >= goal.targetAmount;
    final remainingDays = goal.remainingDays;
    final dailyNeeded =
        remainingDays > 0 ? goal.remainingAmount / remainingDays : 0.0;
    final expired = !completed && remainingDays == 0;
    final statusLabel = completed
        ? l10n.goalCompleted
        : expired
            ? l10n.goalExpired
            : l10n.goalActive;
    final statusColor = completed
        ? AppColors.income
        : expired
            ? AppColors.warning
            : colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black38
                : const Color(0x18000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(goal.title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.goalActions,
            onSelected: (value) async {
              if (value == 'edit') {
                onEdit(goal);
              }
              if (value == 'archive') {
                final confirmed = await _confirmArchive(context, goal);
                if (context.mounted && confirmed) {
                  onArchive(goal);
                }
              }
              if (value == 'restore') {
                onRestore(goal);
              }
              if (value == 'purge') {
                if (!context.mounted) return;
                final confirmed = await _confirmPurge(context, goal);
                if (context.mounted && confirmed) {
                  onPurge(goal);
                }
              }
            },
            itemBuilder: (context) => [
              if (!archived)
                PopupMenuItem(value: 'edit', child: Text(l10n.editSavingsGoal)),
              if (!archived)
                PopupMenuItem(
                    value: 'archive', child: Text(l10n.archiveSavingsGoal)),
              if (archived)
                PopupMenuItem(
                    value: 'restore', child: Text(l10n.restoreSavingsGoal)),
              if (archived && goal.currentAmount == 0)
                PopupMenuItem(
                    value: 'purge', child: Text(l10n.purgeSavingsGoal)),
            ],
          ),
        ]),
        Text(
            l10n.goalDeadline(
                DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
                    .format(goal.targetDate),
                remainingDays),
            style:
                TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.savedAmount(_amount(goal.currentAmount)),
              style: const TextStyle(
                  color: AppColors.income, fontWeight: FontWeight.bold)),
          Text(l10n.targetAmount(_amount(goal.targetAmount)),
              style: TextStyle(color: colorScheme.onSurface))
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            minHeight: 8,
            color: completed ? AppColors.income : colorScheme.primary),
        if (!completed && remainingDays > 0) ...[
          const SizedBox(height: 10),
          Text(l10n.dailyDepositNeeded(_amount(dailyNeeded)),
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
        if (expired) ...[
          const SizedBox(height: 10),
          Text(l10n.goalExpiredRemaining(_amount(goal.remainingAmount)),
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
        if (archived)
          Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(l10n.archivedGoalHint,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        const SizedBox(height: 12),
        Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                  onPressed: () => onHistory(goal),
                  icon: const Icon(Icons.history, size: 16),
                  label: Text(l10n.savingsHistory)),
              if (!archived) ...[
                OutlinedButton(
                    onPressed: () => onDeposit(goal, true),
                    child: Text(l10n.withdraw)),
                ElevatedButton.icon(
                    onPressed: () => onDeposit(goal, false),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.deposit)),
              ],
            ]),
      ]),
    );
  }

  Future<bool> _confirmArchive(
      BuildContext context, SavingsGoalModel goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveSavingsGoalQuestion),
        content: Text(l10n.archiveSavingsGoalMessage(goal.title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.archive)),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _confirmPurge(
      BuildContext context, SavingsGoalModel goal) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.purgeSavingsGoalQuestion),
        content: Text(l10n.purgeSavingsGoalMessage(goal.title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.purge)),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _SectionContent extends StatefulWidget {
  final List<SavingsGoalModel> goals;
  final List<SavingsGoalModel> archivedGoals;
  final bool privacyHidden;
  final VoidCallback onAddGoal;
  final ValueChanged<SavingsGoalModel> onArchive;
  final ValueChanged<SavingsGoalModel> onEdit;
  final ValueChanged<SavingsGoalModel> onRestore;
  final ValueChanged<SavingsGoalModel> onPurge;
  final ValueChanged<SavingsGoalModel> onHistory;
  final void Function(SavingsGoalModel, bool) onDeposit;
  final Widget Function(SavingsGoalModel, bool) buildCard;

  const _SectionContent(
      {required this.goals,
      required this.archivedGoals,
      required this.privacyHidden,
      required this.onAddGoal,
      required this.onArchive,
      required this.onEdit,
      required this.onRestore,
      required this.onPurge,
      required this.onHistory,
      required this.onDeposit,
      required this.buildCard});

  @override
  State<_SectionContent> createState() => _SectionContentState();
}

class _SectionContentState extends State<_SectionContent> {
  bool showingArchived = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goals = showingArchived ? widget.archivedGoals : widget.goals;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l10n.savingsGoalsTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
            onPressed: widget.onAddGoal,
            icon: const Icon(Icons.add),
            label: Text(l10n.newSavingsGoal)),
      ]),
      const SizedBox(height: 14),
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, label: Text(l10n.goalActive)),
          ButtonSegment(value: true, label: Text(l10n.archived)),
        ],
        selected: {showingArchived},
        onSelectionChanged: (selection) =>
            setState(() => showingArchived = selection.first),
      ),
      const SizedBox(height: 14),
      if (goals.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
                child: Text(
                    showingArchived ? l10n.noArchivedGoals : l10n.noActiveGoals,
                    style: const TextStyle(color: AppColors.textSecondary))))
      else
        ...goals.map((goal) => widget.buildCard(goal, showingArchived)),
    ]);
  }
}
