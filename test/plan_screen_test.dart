import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/plan/presentation/screens/plan_screen.dart';
import 'package:pocket_budget/features/savings/data/models/savings_goal_model.dart';

void main() {
  SavingsGoalModel goal({required double currentAmount, required DateTime targetDate}) => SavingsGoalModel(
        id: 'goal-1',
        title: '旅行基金',
        targetAmount: 10000,
        currentAmount: currentAmount,
        targetDate: targetDate,
        createdAt: DateTime(2026, 8, 1),
      );

  Widget buildScreen({required bool privacyHidden, required SavingsGoalModel savingsGoal}) {
    return MaterialApp(
      home: Scaffold(
        body: PlanScreen(
          goals: [savingsGoal],
          privacyHidden: privacyHidden,
          currentPeriod: '2026-08',
          monthlyBudget: 10000,
          monthlyExpense: 2500,
          onEditBudget: () {},
          onAddGoal: () {},
          onArchive: (_) {},
          onEdit: (_) {},
          onRestore: (_) {},
          onPurge: (_) {},
          onHistory: (_) {},
          onDeposit: (_, __) {},
        ),
      ),
    );
  }

  testWidgets('plan screen shows grouped budget amounts and goal status', (tester) async {
    await tester.pumpWidget(buildScreen(privacyHidden: false, savingsGoal: goal(currentAmount: 6200, targetDate: DateTime(2026, 12, 31))));

    expect(find.text('¥ 10,000.00'), findsOneWidget);
    expect(find.text('¥ 2,500.00'), findsOneWidget);
    expect(find.text('进行中'), findsNWidgets(2));
  });

  testWidgets('plan screen masks budget and goal amounts in privacy mode', (tester) async {
    await tester.pumpWidget(buildScreen(privacyHidden: true, savingsGoal: goal(currentAmount: 10000, targetDate: DateTime(2026, 8, 1))));

    expect(find.text('¥ ****'), findsNWidgets(3));
    expect(find.text('已完成'), findsOneWidget);
  });
}
