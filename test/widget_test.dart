import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/app_lock/presentation/screens/app_lock_screen.dart';
import 'package:pocket_budget/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pocket_budget/features/settings/presentation/screens/settings_screen.dart';
import 'package:pocket_budget/l10n/app_localizations.dart';

void main() {
  testWidgets('app lock retries after biometric authentication fails',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppLockScreen(onAuthenticate: () async => false),
    ));
    await tester.pumpAndSettle();

    expect(find.text('应用锁'), findsOneWidget);
    expect(find.text('验证未成功，请重试'), findsOneWidget);
    expect(find.text('验证并解锁'), findsOneWidget);
  });

  testWidgets('dashboard shows remaining budget and daily quota',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
    expect(find.text('¥3,750.00'), findsOneWidget);
    expect(find.text('每日建议消费上限'), findsOneWidget);
  });

  testWidgets('dashboard hides sensitive amounts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: GeneralSettingsScreen(
        themeMode: ThemeMode.light,
        onThemeModeChanged: (_) {},
        languagePreference: 'system',
        onLanguageChanged: (_) {},
        privacyDefaultHidden: true,
        onPrivacyDefaultChanged: (value) => updatedValue = value,
      ),
    ));

    expect(find.text('默认隐藏金额'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    expect(updatedValue, isFalse);
  });
}
