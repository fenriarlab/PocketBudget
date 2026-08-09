import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/transaction_model.dart';
import '../models/pressure_level.dart';

class TransactionsScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final DateTime selectedMonth;
  final DateTime selectedDate;
  final double dailyQuota;
  final bool privacyHidden;
  final bool calendarView;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<TransactionModel> onDelete;
  final ValueChanged<TransactionModel> onEdit;
  final ValueChanged<DateTime> onAdd;

  const TransactionsScreen({
    super.key,
    required this.transactions,
    required this.selectedMonth,
    required this.selectedDate,
    required this.dailyQuota,
    required this.privacyHidden,
    required this.calendarView,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
  });

  String _amount(double value, {bool signed = false, bool expense = false}) {
    if (privacyHidden) return '¥ ****';
    final prefix = signed ? (expense ? '-' : '+') : '';
    return '$prefix¥ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) =>
      calendarView ? _buildCalendar(context) : _buildList(context);

  Widget _buildList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (transactions.isEmpty)
      return Center(
          child: Text(l10n.emptyTransactions,
              style: const TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) =>
          _transactionTile(context, transactions[index]),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final year = selectedMonth.year;
    final month = selectedMonth.month;
    final days = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final dailyExpenses = <String, double>{};
    final dailyIncomes = <String, double>{};
    final dailyTransactions = <String, List<TransactionModel>>{};

    for (final transaction in transactions) {
      if (transaction.date.year != year || transaction.date.month != month)
        continue;
      final key = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyTransactions.putIfAbsent(key, () => []).add(transaction);
      final totals = transaction.type == TransactionType.expense
          ? dailyExpenses
          : dailyIncomes;
      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }

    final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final selectedTransactions = dailyTransactions[selectedKey] ?? [];
    final weekCount = ((firstWeekday + days) / 7).ceil();
    final calendarHeight = weekCount * 46.0;

    return ListView(children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _surfaceShadow(context),
        ),
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var day = 0; day < 7; day++)
                        Text(
                            DateFormat.E(Localizations.localeOf(context)
                                    .toLanguageTag())
                                .format(DateTime(2024, 1, day + 7)),
                            style: TextStyle(
                                fontSize: 12,
                                color: day == 0 || day == 6
                                    ? AppColors.textSecondary
                                    : null,
                                fontWeight: FontWeight.w500)),
                    ])),
            SizedBox(
              height: calendarHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: firstWeekday + days,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, childAspectRatio: 1.25),
                itemBuilder: (context, index) {
                  if (index < firstWeekday) return const SizedBox.shrink();
                  final date = DateTime(year, month, index - firstWeekday + 1);
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final expense = dailyExpenses[key] ?? 0;
                  final income = dailyIncomes[key] ?? 0;
                  final selected = date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  return InkWell(
                    onTap: () => onDateSelected(date),
                    onDoubleTap: () => onAdd(date),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _heatColor(context, expense),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 1.5),
                        boxShadow: _dateCellShadow(context, selected),
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${date.day}',
                                style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            if (privacyHidden && (expense > 0 || income > 0))
                              const Text('****',
                                  style: TextStyle(
                                      fontSize: 8, color: AppColors.textMuted))
                            else if (expense > 0)
                              Text('-${expense.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.expense))
                            else if (income > 0)
                              Text('+${income.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 9, color: AppColors.income)),
                          ]),
                    ),
                  );
                },
              ),
            ),
            _pressureLegend(context),
          ],
        ),
      ),
      SizedBox(height: 260, child: _selectedDay(context, selectedTransactions)),
    ]);
  }

  Widget _pressureLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          Text(l10n.pressureLegend,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ...PressureLevelDetails.values.map((level) => Expanded(
                  child: Row(children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: level.color, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text(level.localizedLabel(l10n),
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ]))),
        ],
      ),
    );
  }

  Widget _selectedDay(
      BuildContext context, List<TransactionModel> selectedTransactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_selectedDateLabel(context),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextButton.icon(
              onPressed: () => onAdd(selectedDate),
              icon: const Icon(Icons.add, size: 16),
              label: Text(AppLocalizations.of(context)!.addTransaction)),
        ]),
        Expanded(
            child: selectedTransactions.isEmpty
                ? Center(
                    child: Text(
                        AppLocalizations.of(context)!.noTransactionsForDay,
                        style: const TextStyle(color: AppColors.textSecondary)))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: selectedTransactions
                        .map((transaction) => _transactionTile(
                            context, transaction,
                            compactDate: true))
                        .toList())),
      ]),
    );
  }

  Future<void> _showTransactionActions(
      BuildContext context, TransactionModel transaction) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(AppLocalizations.of(context)!.edit),
                onTap: () => Navigator.pop(context, 'edit')),
            ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(AppLocalizations.of(context)!.delete),
                onTap: () => Navigator.pop(context, 'delete')),
          ],
        ),
      ),
    );
    if (action == 'edit') onEdit(transaction);
    if (action == 'delete') onDelete(transaction);
  }

  String _selectedDateLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMMEEEEd(locale).format(selectedDate);
  }

  Widget _transactionTile(BuildContext context, TransactionModel transaction,
      {bool compactDate = false}) {
    final expense = transaction.type == TransactionType.expense;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPress: () => _showTransactionActions(context, transaction),
        child: ListTile(
          leading: CircleAvatar(
              child: Text(transaction.categoryIcon.isEmpty
                  ? (expense
                      ? AppLocalizations.of(context)!.expenseInitial
                      : AppLocalizations.of(context)!.incomeInitial)
                  : transaction.categoryIcon)),
          title: Text(transaction.categoryName),
          subtitle: Text(transaction.note?.isNotEmpty == true
              ? '${DateFormat.Hm(Localizations.localeOf(context).toLanguageTag()).format(transaction.date)} · ${transaction.note}'
              : compactDate
                  ? DateFormat.Hm(
                          Localizations.localeOf(context).toLanguageTag())
                      .format(transaction.date)
                  : DateFormat.yMd(
                          Localizations.localeOf(context).toLanguageTag())
                      .add_Hm()
                      .format(transaction.date)),
          trailing: Text(
              _amount(transaction.amount, signed: true, expense: expense),
              style: TextStyle(
                  color: expense ? AppColors.expense : AppColors.income,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Color _heatColor(BuildContext context, double expense) {
    if (expense == 0) return Theme.of(context).colorScheme.surface;
    final ratio = dailyQuota > 0 ? expense / dailyQuota : double.infinity;
    return PressureLevelDetails.fromRatio(ratio).color.withValues(alpha: 0.28);
  }

  List<BoxShadow> _surfaceShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
          color: isDark ? Colors.black38 : const Color(0x18000000),
          blurRadius: 10,
          offset: const Offset(0, 3))
    ];
  }

  List<BoxShadow> _dateCellShadow(BuildContext context, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
          color: isDark ? Colors.black26 : const Color(0x14000000),
          blurRadius: selected ? 5 : 3,
          offset: const Offset(0, 1))
    ];
  }
}
