import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/transaction_model.dart';

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
    required this.onAdd,
  });

  String _amount(double value, {bool signed = false, bool expense = false}) {
    if (privacyHidden) return '¥ ****';
    final prefix = signed ? (expense ? '-' : '+') : '';
    return '$prefix¥ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) => calendarView ? _buildCalendar(context) : _buildList();

  Widget _buildList() {
    if (transactions.isEmpty) return const Center(child: Text('暂无记账明细，点击右下角“记一笔”开始记录！', style: TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) => _transactionTile(transactions[index]),
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
      if (transaction.date.year != year || transaction.date.month != month) continue;
      final key = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyTransactions.putIfAbsent(key, () => []).add(transaction);
      final totals = transaction.type == TransactionType.expense ? dailyExpenses : dailyIncomes;
      totals[key] = (totals[key] ?? 0) + transaction.amount;
    }

    final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final selectedTransactions = dailyTransactions[selectedKey] ?? [];
    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;

    final weekCount = ((firstWeekday + days) / 7).ceil();
    final calendarHeight = weekCount * 52.0;

    return ListView(children: [
      _monthBar(context, year, month, isCurrentMonth, now),
      Padding(padding: const EdgeInsets.fromLTRB(12, 2, 12, 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        for (final label in const ['日', '一', '二', '三', '四', '五', '六']) Text(label, style: TextStyle(fontSize: 12, color: label == '日' || label == '六' ? AppColors.textSecondary : null, fontWeight: FontWeight.w500)),
      ])),
      SizedBox(
        height: calendarHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          itemCount: firstWeekday + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.25),
          itemBuilder: (context, index) {
          if (index < firstWeekday) return const SizedBox.shrink();
          final date = DateTime(year, month, index - firstWeekday + 1);
          final key = DateFormat('yyyy-MM-dd').format(date);
          final expense = dailyExpenses[key] ?? 0;
          final income = dailyIncomes[key] ?? 0;
          final selected = date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
          return InkWell(
            onTap: () => onDateSelected(date),
            onDoubleTap: () => onAdd(date),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: _heatColor(context, expense), borderRadius: BorderRadius.circular(8), border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${date.day}', style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                if (privacyHidden && (expense > 0 || income > 0)) const Text('****', style: TextStyle(fontSize: 8, color: AppColors.textMuted))
                else if (expense > 0) Text('-${expense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: AppColors.expense))
                else if (income > 0) Text('+${income.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, color: AppColors.income)),
              ]),
            ),
          );
          },
        ),
      ),
      _pressureLegend(context),
      SizedBox(height: 260, child: _selectedDay(selectedTransactions)),
    ]);
  }

  Widget _pressureLegend(BuildContext context) {
    const levels = [
      ('很低', Color(0xFF65C99A)),
      ('偏低', Color(0xFFA8D96D)),
      ('适中', Color(0xFFF3B34C)),
      ('偏高', Color(0xFFE96A68)),
      ('过高', Color(0xFF9C65D6)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          Text('压力图例：', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ...levels.map((level) => Expanded(child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: level.$2, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Text(level.$1, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]))),
        ],
      ),
    );
  }

  Widget _monthBar(BuildContext context, int year, int month, bool isCurrentMonth, DateTime now) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onMonthChanged(DateTime(year, month - 1))),
        Text(DateFormat('yyyy 年 MM 月').format(selectedMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (!isCurrentMonth) TextButton(onPressed: () => onMonthChanged(DateTime(now.year, now.month)), child: const Text('今天')),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onMonthChanged(DateTime(year, month + 1))),
        ]),
      ]),
    );
  }

  Widget _selectedDay(List<TransactionModel> selectedTransactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('MM月dd日').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: () => onAdd(selectedDate), icon: const Icon(Icons.add, size: 16), label: const Text('补记')),
        ]),
        Expanded(child: selectedTransactions.isEmpty ? const Center(child: Text('当天暂无记录', style: TextStyle(color: AppColors.textSecondary))) : ListView(children: selectedTransactions.map(_transactionTile).toList())),
      ]),
    );
  }

  Widget _transactionTile(TransactionModel transaction) {
    final expense = transaction.type == TransactionType.expense;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text(transaction.categoryIcon.isEmpty ? (expense ? '支' : '收') : transaction.categoryIcon)),
        title: Text(transaction.categoryName),
        subtitle: Text(transaction.note?.isNotEmpty == true ? '${transaction.note} · ${DateFormat('HH:mm').format(transaction.date)}' : DateFormat('yyyy-MM-dd HH:mm').format(transaction.date)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_amount(transaction.amount, signed: true, expense: expense), style: TextStyle(color: expense ? AppColors.expense : AppColors.income, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => onDelete(transaction)),
        ]),
      ),
    );
  }

  Color _heatColor(BuildContext context, double expense) {
    if (expense == 0) return AppColors.income.withValues(alpha: 0.12);
    final ratio = dailyQuota > 0 ? expense / dailyQuota : 1;
    if (ratio <= 0.5) return const Color(0xFFF1C40F).withValues(alpha: 0.4);
    if (ratio <= 1) return const Color(0xFFE67E22).withValues(alpha: 0.55);
    return AppColors.expense.withValues(alpha: 0.7);
  }
}
