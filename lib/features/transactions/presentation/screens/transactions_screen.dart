import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
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
  Widget build(BuildContext context) => calendarView ? _buildCalendar(context) : _buildList();

  Widget _buildList() {
    if (transactions.isEmpty) return const Center(child: Text('暂无记账明细，点击右下角“记一笔”开始记录！', style: TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) => _transactionTile(context, transactions[index]),
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
    final calendarHeight = weekCount * 46.0;

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
      SizedBox(height: 260, child: _selectedDay(context, selectedTransactions)),
    ]);
  }

  Widget _pressureLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          Text('压力图例：', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ...PressureLevelDetails.values.map((level) => Expanded(child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: level.color, shape: BoxShape.circle)),
            const SizedBox(width: 3),
            Text(level.label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]))),
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
      helpText: '选择月份',
    );
    if (picked != null) onMonthChanged(DateTime(picked.year, picked.month));
  }

  Widget _monthBar(BuildContext context, int year, int month, bool isCurrentMonth, DateTime now) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onMonthChanged(DateTime(year, month - 1))),
        InkWell(
          onTap: () => _pickMonth(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('yyyy 年 MM 月').format(selectedMonth), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_month_outlined, size: 18),
              ],
            ),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (!isCurrentMonth) TextButton(onPressed: () => onMonthChanged(DateTime(now.year, now.month)), child: const Text('今天')),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onMonthChanged(DateTime(year, month + 1))),
        ]),
      ]),
    );
  }

  Widget _selectedDay(BuildContext context, List<TransactionModel> selectedTransactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_selectedDateLabel(), style: const TextStyle(fontWeight: FontWeight.bold)),
          TextButton.icon(onPressed: () => onAdd(selectedDate), icon: const Icon(Icons.add, size: 16), label: const Text('记一笔')),
        ]),
        Expanded(child: selectedTransactions.isEmpty ? const Center(child: Text('当天暂无记录', style: TextStyle(color: AppColors.textSecondary))) : ListView(children: selectedTransactions.map((transaction) => _transactionTile(context, transaction, compactDate: true)).toList())),
      ]),
    );
  }

  Future<void> _showTransactionActions(BuildContext context, TransactionModel transaction) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('编辑'), onTap: () => Navigator.pop(context, 'edit')),
            ListTile(leading: const Icon(Icons.delete_outline), title: const Text('删除'), onTap: () => Navigator.pop(context, 'delete')),
          ],
        ),
      ),
    );
    if (action == 'edit') onEdit(transaction);
    if (action == 'delete') onDelete(transaction);
  }

  String _selectedDateLabel() {
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${selectedDate.month}月${selectedDate.day}日 ${weekdays[selectedDate.weekday - 1]}';
  }

  Widget _transactionTile(BuildContext context, TransactionModel transaction, {bool compactDate = false}) {
    final expense = transaction.type == TransactionType.expense;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPress: () => _showTransactionActions(context, transaction),
        child: ListTile(
          leading: CircleAvatar(child: Text(transaction.categoryIcon.isEmpty ? (expense ? '支' : '收') : transaction.categoryIcon)),
          title: Text(transaction.categoryName),
          subtitle: Text(transaction.note?.isNotEmpty == true ? '${DateFormat('HH:mm').format(transaction.date)} · ${transaction.note}' : compactDate ? DateFormat('HH:mm').format(transaction.date) : DateFormat('yyyy-MM-dd HH:mm').format(transaction.date)),
          trailing: Text(_amount(transaction.amount, signed: true, expense: expense), style: TextStyle(color: expense ? AppColors.expense : AppColors.income, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Color _heatColor(BuildContext context, double expense) {
    if (expense == 0) return Theme.of(context).colorScheme.surface;
    final ratio = dailyQuota > 0 ? expense / dailyQuota : 1.0;
    return PressureLevelDetails.fromRatio(ratio).color.withValues(alpha: 0.28);
  }
}
