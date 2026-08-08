import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:pocket_budget/features/savings/data/models/savings_goal_model.dart';
import 'package:pocket_budget/features/savings/data/models/savings_log_model.dart';

void main() {
  testWidgets('savings goal sheet closes after creating a goal', (tester) async {
    SavingsGoalModel? savedGoal;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheetContext) => SavingsGoalSheet(onSave: (goal) async {
                savedGoal = goal;
                Navigator.pop(sheetContext);
              }),
            ),
            child: const Text('打开计划'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('打开计划'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '旅行基金');
    await tester.enterText(find.byType(TextField).at(1), '5000');
    await tester.tap(find.text('创建目标'));
    await tester.pumpAndSettle();

    expect(savedGoal?.title, '旅行基金');
    expect(savedGoal?.targetAmount, 5000);
    expect(find.text('新建存钱目标'), findsNothing);
  });

  testWidgets('savings goal sheet shows validation errors for empty input', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SavingsGoalSheet(onSave: (_) async {}),
      ),
    ));

    await tester.tap(find.text('创建目标'));
    await tester.pump();

    expect(find.text('请输入目标名称'), findsOneWidget);
    expect(find.text('请输入大于 0 的目标金额'), findsOneWidget);
  });

  testWidgets('withdrawal sheet blocks amounts above the current balance', (tester) async {
    final goal = SavingsGoalModel(
      id: 'goal-1',
      title: '旅行基金',
      targetAmount: 1000,
      currentAmount: 100,
      targetDate: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 8, 1),
    );
    var saved = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SavingsDepositSheet(goal: goal, isWithdraw: true, onSave: (_, __) async => saved = true),
      ),
    ));

    await tester.enterText(find.byType(TextField).first, '101');
    await tester.tap(find.text('确认提取'));
    await tester.pump();

    expect(find.text('提取金额不能超过当前余额 ¥100.00'), findsOneWidget);
    expect(saved, isFalse);
  });

  testWidgets('editing a savings log prefills values and keeps its identity', (tester) async {
    final goal = SavingsGoalModel(
      id: 'goal-1',
      title: '旅行基金',
      targetAmount: 1000,
      currentAmount: 100,
      targetDate: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 8, 1),
    );
    final initialLog = SavingsLogModel(
      id: 'log-1',
      goalId: goal.id,
      amount: 100,
      note: '月初存入',
      createdAt: DateTime(2026, 8, 2),
      deductFromBudget: true,
      linkedTransactionId: 'tx_savings_log-1',
    );
    SavingsLogModel? savedLog;
    bool? savedDeductFromBudget;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SavingsDepositSheet(
          goal: goal,
          isWithdraw: false,
          initialLog: initialLog,
          onSave: (log, deductFromBudget) async {
            savedLog = log;
            savedDeductFromBudget = deductFromBudget;
          },
        ),
      ),
    ));

    expect(find.text('编辑「旅行基金」流水'), findsOneWidget);
    expect(find.text('月初存入'), findsOneWidget);
    await tester.tap(find.text('保存修改'));
    await tester.pump();

    expect(savedLog?.id, 'log-1');
    expect(savedLog?.amount, 100);
    expect(savedDeductFromBudget, isTrue);
  });

  testWidgets('deposit sheet recovers when saving fails', (tester) async {
    final goal = SavingsGoalModel(
      id: 'goal-1',
      title: '旅行基金',
      targetAmount: 1000,
      currentAmount: 0,
      targetDate: DateTime(2026, 12, 31),
      createdAt: DateTime(2026, 8, 1),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SavingsDepositSheet(
          goal: goal,
          isWithdraw: false,
          onSave: (_, __) async => throw StateError('database unavailable'),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField).first, '2000');
    await tester.tap(find.text('确认存入'));
    await tester.pump();

    expect(find.textContaining('保存失败，请重试'), findsOneWidget);
    expect(find.text('确认存入'), findsOneWidget);
  });
}