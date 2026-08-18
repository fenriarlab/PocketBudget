import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/app_lock/presentation/screens/app_lock_screen.dart';
import 'package:pocket_budget/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:pocket_budget/features/onboarding/presentation/screens/currency_setup_screen.dart';
import 'package:pocket_budget/features/settings/presentation/screens/settings_screen.dart';
import 'package:pocket_budget/features/transactions/data/models/transaction_model.dart';
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
      home: const DashboardScreen(
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
      home: const DashboardScreen(
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

  testWidgets('dashboard calculates dual progress bars for monthly and daily spending',
      (tester) async {
    final targetDate = DateTime(2026, 8, 15);
    final txs = [
      TransactionModel(
        id: 'tx_1',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        categoryName: '餐饮',
        categoryIcon: '🍔',
        date: targetDate,
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DashboardScreen(
          monthlyBudget: 3100, // 3100 / 31 days = 100/day
          monthlyExpense: 1550, // 1550 / 3100 = 50%
          monthlyIncome: 5000,
          goals: const [],
          currentPeriod: '2026-08',
          privacyHidden: false,
          transactions: txs,
          selectedMonth: DateTime(2026, 8),
          selectedDate: targetDate,
          onMonthChanged: (_) {},
          onDateSelected: (_) {},
          onDelete: (_) {},
          onEdit: (_) {},
          onAdd: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 验证左侧月度进度：已用 50% 预算
    expect(find.text('已用 50% 预算'), findsOneWidget);
    // 验证右侧当日进度：50 / 100 = 50% -> 当日已用 50%
    expect(find.text('当日已用 50%'), findsOneWidget);
  });

  testWidgets('dashboard shows overspent status and no-budget fallback',
      (tester) async {
    final targetDate = DateTime(2026, 8, 15);
    final txs = [
      TransactionModel(
        id: 'tx_1',
        amount: 200.0,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        categoryName: '餐饮',
        categoryIcon: '🍔',
        date: targetDate,
      ),
    ];

    // 超支场景：3100 预算，花了 3720 (120%)；当日限额 100，花了 200 (200%)
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DashboardScreen(
          monthlyBudget: 3100,
          monthlyExpense: 3720,
          monthlyIncome: 5000,
          goals: const [],
          currentPeriod: '2026-08',
          privacyHidden: false,
          transactions: txs,
          selectedMonth: DateTime(2026, 8),
          selectedDate: targetDate,
          onMonthChanged: (_) {},
          onDateSelected: (_) {},
          onDelete: (_) {},
          onEdit: (_) {},
          onAdd: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('超支 120%'), findsOneWidget);
    expect(find.text('当日超额 200%'), findsOneWidget);
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

  testWidgets('onboarding screen allows choosing language, currency, and initial balance',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? selectedLang;
    String? confirmedCurrency;
    double? confirmedBalance;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CurrencySetupScreen(
        languagePreference: 'zh',
        onLanguageChanged: (lang) => selectedLang = lang,
        onConfirmed: (curr, bal) async {
          confirmedCurrency = curr;
          confirmedBalance = bal;
        },
      ),
    ));
    await tester.pumpAndSettle();

    // 验证标题与欢迎语
    expect(find.text('欢迎使用 PocketBudget'), findsOneWidget);
    expect(find.text('应用语言'), findsOneWidget);
    expect(find.text('选择记账货币'), findsOneWidget);
    expect(find.text('初始余额'), findsOneWidget);

    // 切换语言为英文
    await tester.tap(find.text('English'));
    expect(selectedLang, 'en');

    // 输入初始资金 10000
    final balanceField = find.byType(TextField);
    await tester.enterText(balanceField, '10000.50');
    await tester.pumpAndSettle();

    // 点击开启我的纯净账本
    final submitBtn = find.text('开启我的纯净账本');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(confirmedCurrency, 'CNY');
    expect(confirmedBalance, 10000.50);
  });
}
