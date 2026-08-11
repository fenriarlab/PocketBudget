import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
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
  final String currencyCode;

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
      required this.onDeposit,
      this.currencyCode = 'CNY'});

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
            onDeposit: onDeposit,
            currencyCode: currencyCode)
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
  final String currencyCode;

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
      required this.onDeposit,
      this.currencyCode = 'CNY'});

  String _amount(double value) => privacyHidden
      ? '${CurrencyCatalog.byCode(currencyCode).symbol} ****'
      : CurrencyCatalog.byCode(currencyCode).format(value, 'en');

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
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.track_changes_outlined,
                size: 22, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(goal.title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999)),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor)),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.goalActions,
            icon: Icon(Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant),
            padding: EdgeInsets.zero,
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
              if (goal.currentAmount == 0)
                PopupMenuItem(
                    value: 'purge',
                    child: Text(archived
                        ? l10n.purgeSavingsGoal
                        : l10n.deleteSavingsGoal)),
            ],
          ),
        ]),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.goalDeadline(
                    DateFormat.yMd(
                            Localizations.localeOf(context).toLanguageTag())
                        .format(goal.targetDate),
                    remainingDays),
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SavingsAmount(
                label: l10n.savedAmountLabel,
                value: _amount(goal.currentAmount),
                color: AppColors.income,
              ),
              _SavingsAmount(
                label: l10n.targetAmountLabel,
                value: _amount(goal.targetAmount),
                color: colorScheme.onSurface,
                alignEnd: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${goal.progressPercentage.round()}%',
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            minHeight: 9,
            color: completed ? AppColors.income : colorScheme.primary,
            backgroundColor: colorScheme.outlineVariant.withValues(alpha: 0.14),
          ),
        ),
        if (!completed && remainingDays > 0) ...[
          const SizedBox(height: 10),
          _DailyDepositHint(
            text: l10n.dailyDepositNeeded(_amount(dailyNeeded)),
            amount: _amount(dailyNeeded),
            color: colorScheme.primary,
          ),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onHistory(goal),
                style: _secondarySavingsButtonStyle(colorScheme),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: Text(l10n.savingsHistory),
              ),
            ),
            if (!archived) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onDeposit(goal, true),
                style: _secondarySavingsButtonStyle(colorScheme),
                child: Text(l10n.withdraw),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => onDeposit(goal, false),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(l10n.deposit),
              ),
            ],
          ],
        ),
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

ButtonStyle _secondarySavingsButtonStyle(ColorScheme colorScheme) {
  return ButtonStyle(
    side: WidgetStatePropertyAll(
      BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.52),
      ),
    ),
    foregroundColor: WidgetStatePropertyAll(colorScheme.primary),
  );
}

class _SavingsAmount extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _SavingsAmount({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
    );
  }
}

class _DailyDepositHint extends StatelessWidget {
  final String text;
  final String amount;
  final Color color;

  const _DailyDepositHint({
    required this.text,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split(amount);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.first),
          TextSpan(
              text: amount,
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          if (parts.length > 1) TextSpan(text: parts.sublist(1).join(amount)),
        ],
      ),
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
    );
  }
}

class _SectionContentState extends State<_SectionContent> {
  bool showingArchived = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goals = showingArchived ? widget.archivedGoals : widget.goals;
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Row(
            children: [
              Icon(Icons.savings_outlined, color: colors.primary, size: 24),
              const SizedBox(width: 8),
              Text(l10n.savingsGoalsTitle,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface)),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: widget.onAddGoal,
          icon: const Icon(Icons.add_rounded, size: 17),
          label: Text(l10n.newSavingsGoal),
        ),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          style: ButtonStyle(
            side: WidgetStatePropertyAll(BorderSide.none),
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11))),
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? colors.surface
                  : Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant;
            }),
            elevation: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected) ? 2 : 0;
            }),
          ),
          segments: [
            ButtonSegment(value: false, label: Text(l10n.goalActive)),
            ButtonSegment(value: true, label: Text(l10n.archived)),
          ],
          selected: {showingArchived},
          onSelectionChanged: (selection) =>
              setState(() => showingArchived = selection.first),
        ),
      ),
      const SizedBox(height: 16),
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
