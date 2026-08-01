import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:pocket_budget/features/savings/data/models/savings_goal_model.dart';

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
}