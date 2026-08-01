import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pocket_budget/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('dashboard shows remaining budget and daily quota', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DashboardScreen(
        monthlyBudget: 5000,
        monthlyExpense: 1250,
        monthlyIncome: 6000,
        goals: [],
        currentPeriod: '2026-08',
        privacyHidden: false,
      ),
    ));

    expect(find.text('本月剩余可用预算 (2026-08)'), findsOneWidget);
    expect(find.text('¥ 3750.00'), findsOneWidget);
    expect(find.text('每日建议消费上限'), findsOneWidget);
  });

  testWidgets('dashboard hides sensitive amounts', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: DashboardScreen(
        monthlyBudget: 5000,
        monthlyExpense: 1250,
        monthlyIncome: 6000,
        goals: [],
        currentPeriod: '2026-08',
        privacyHidden: true,
      ),
    ));

    expect(find.text('¥ ****'), findsWidgets);
    expect(find.text('¥ 3750.00'), findsNothing);
  });

  testWidgets('settings updates default privacy preference', (tester) async {
    bool? updatedValue;
    await tester.pumpWidget(MaterialApp(
      home: SettingsScreen(
        themeMode: ThemeMode.light,
        onThemeModeChanged: (_) {},
        privacyDefaultHidden: true,
        onPrivacyDefaultChanged: (value) => updatedValue = value,
      ),
    ));

    expect(find.text('默认隐藏金额'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    expect(updatedValue, isFalse);
  });
}
