import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/dashboard/presentation/screens/dashboard_screen.dart';
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
          onEdit: (_) {},
          onAdd: (_) {},
          ),
        ),
      ),
    ));

    expect(find.text('-¥ 35.00'), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);
  });

  testWidgets('calendar month title opens a date picker', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardScreen(
        monthlyBudget: 5000,
        monthlyExpense: 0,
        monthlyIncome: 0,
        goals: const [],
        currentPeriod: '2026-08',
        privacyHidden: false,
        transactions: const [],
        selectedMonth: DateTime(2026, 8),
        selectedDate: DateTime(2026, 8, 1),
        dailyQuota: 250,
        onMonthChanged: (_) {},
        onDateSelected: (_) {},
        onDelete: (_) {},
        onEdit: (_) {},
        onAdd: (_) {},
        ),
      ),
    ));

    await tester.tap(find.text('2026 年 08 月'));
    await tester.pumpAndSettle();

    expect(find.text('选择月份'), findsOneWidget);
  });

  testWidgets('long pressing a transaction opens edit and delete actions', (tester) async {
    final transaction = TransactionModel(
      id: 'tx-2',
      amount: 100,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      categoryName: '餐饮',
      categoryIcon: '🍔',
      date: DateTime(2026, 8, 11),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 900,
          child: TransactionsScreen(
            transactions: [transaction],
            selectedMonth: DateTime(2026, 8),
            selectedDate: DateTime(2026, 8, 11),
            dailyQuota: 250,
            privacyHidden: false,
            calendarView: true,
            onMonthChanged: (_) {},
            onDateSelected: (_) {},
            onDelete: (_) {},
            onEdit: (_) {},
            onAdd: (_) {},
          ),
        ),
      ),
    ));

    await tester.longPress(find.text('餐饮'));
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}
