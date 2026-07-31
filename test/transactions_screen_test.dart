import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/transactions/data/models/transaction_model.dart';
import 'package:pocket_budget/features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  testWidgets('calendar screen renders selected month and transaction', (tester) async {
    final transaction = TransactionModel(
      id: 'tx-1',
      amount: 35,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      categoryName: '餐饮',
      categoryIcon: '🍔',
      date: DateTime(2026, 8, 1, 12),
      note: '午餐',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 900,
          child: TransactionsScreen(
          transactions: [transaction],
          selectedMonth: DateTime(2026, 8),
          selectedDate: DateTime(2026, 8, 1),
          dailyQuota: 250,
          privacyHidden: false,
          calendarView: true,
          onMonthChanged: (_) {},
          onDateSelected: (_) {},
          onDelete: (_) {},
          onAdd: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('2026 年 08 月'), findsOneWidget);
    expect(find.text('月支出: ¥ 35.00'), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);
  });
}
