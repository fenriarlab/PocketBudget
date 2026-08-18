import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/analysis/presentation/screens/analysis_screen.dart';
import 'package:pocket_budget/features/analysis/presentation/screens/category_detail_screen.dart';
import 'package:pocket_budget/features/categories/data/models/category_model.dart';
import 'package:pocket_budget/features/transactions/data/models/transaction_model.dart';
import 'package:pocket_budget/l10n/app_localizations.dart';

void main() {
  final testCategories = [
    const CategoryModel(
      id: 'cat_food',
      name: '餐饮',
      icon: '🍔',
      colorHex: '#F06B78',
      type: CategoryType.expense,
      isCustom: false,
    ),
    const CategoryModel(
      id: 'cat_transport',
      name: '交通',
      icon: '🚌',
      colorHex: '#6E9BFF',
      type: CategoryType.expense,
      isCustom: false,
    ),
    const CategoryModel(
      id: 'cat_salary',
      name: '工资收入',
      icon: '💰',
      colorHex: '#55B98A',
      type: CategoryType.income,
      isCustom: false,
    ),
  ];

  final now = DateTime.now();
  final testTransactions = [
    TransactionModel(
      id: 'tx_1',
      amount: 100.0,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      categoryName: '餐饮',
      categoryIcon: '🍔',
      date: now,
      note: '午餐',
    ),
    TransactionModel(
      id: 'tx_2',
      amount: 200.0,
      type: TransactionType.expense,
      categoryId: 'cat_transport',
      categoryName: '交通',
      categoryIcon: '🚌',
      date: now,
      note: '打车',
    ),
    TransactionModel(
      id: 'tx_3',
      amount: 5000.0,
      type: TransactionType.income,
      categoryId: 'cat_salary',
      categoryName: '工资收入',
      categoryIcon: '💰',
      date: now,
      note: '月薪',
    ),
  ];

  testWidgets('AnalysisScreen renders hero metrics, donut chart and leaderboard',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AnalysisScreen(
            transactions: testTransactions,
            allTransactions: testTransactions,
            categories: testCategories,
            privacyHidden: false,
            currencyCode: 'CNY',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 验证收支切换按钮
    expect(find.text('支出分析'), findsOneWidget);
    expect(find.text('收入分析'), findsOneWidget);

    // 默认支出分析：总支出为 100 + 200 = 300
    expect(find.text('总支出'), findsOneWidget);
    expect(find.text('¥300.00'), findsOneWidget);
    expect(find.text('2 笔'), findsOneWidget);

    // 验证排行榜
    expect(find.text('分类占比排行'), findsOneWidget);
    expect(find.text('餐饮'), findsWidgets);
    expect(find.text('交通'), findsWidgets);
  });

  testWidgets('AnalysisScreen switches between Expense and Income analysis',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AnalysisScreen(
            transactions: testTransactions,
            allTransactions: testTransactions,
            categories: testCategories,
            privacyHidden: false,
            currencyCode: 'CNY',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 点击收入分析
    await tester.tap(find.text('收入分析'));
    await tester.pumpAndSettle();

    expect(find.text('总收入'), findsOneWidget);
    expect(find.text('¥5,000.00'), findsWidgets);
    expect(find.text('1 笔'), findsOneWidget);
    expect(find.text('工资'), findsWidgets);
  });

  testWidgets('AnalysisScreen supports tapping category to navigate to CategoryDetailScreen',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AnalysisScreen(
            transactions: testTransactions,
            allTransactions: testTransactions,
            categories: testCategories,
            privacyHidden: false,
            currencyCode: 'CNY',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 滚动并点击餐饮行
    final foodFinder = find.text('餐饮').first;
    await tester.ensureVisible(foodFinder);
    await tester.tap(foodFinder);
    await tester.pumpAndSettle();

    // 验证直接进入 CategoryDetailScreen
    expect(find.text('餐饮 的交易明细'), findsOneWidget);
    expect(find.text('午餐'), findsOneWidget);
    expect(find.text('¥100.00'), findsWidgets);
  });

  testWidgets('CategoryDetailScreen renders category metrics and transactions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CategoryDetailScreen(
          category: testCategories.first,
          allTransactions: testTransactions,
          privacyHidden: false,
          currencyCode: 'CNY',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('餐饮 的交易明细'), findsOneWidget);
    expect(find.text('¥100.00'), findsWidgets);
    expect(find.text('午餐'), findsOneWidget);
  });

  testWidgets('AnalysisScreen hides sensitive amounts when privacyHidden is true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AnalysisScreen(
            transactions: testTransactions,
            allTransactions: testTransactions,
            categories: testCategories,
            privacyHidden: true,
            currencyCode: 'CNY',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¥ ****'), findsWidgets);
    expect(find.text('¥300.00'), findsNothing);
  });
}
