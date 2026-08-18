import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/categories/data/category_repository.dart';
import 'package:pocket_budget/features/categories/data/models/category_model.dart';
import 'package:pocket_budget/features/categories/presentation/screens/category_management_screen.dart';
import 'package:pocket_budget/l10n/app_localizations.dart';

void main() {
  test('CategoryRepository default categories contains expanded income categories', () {
    final incomeDefaults = CategoryRepository.defaultCategories
        .where((c) => c.type == CategoryType.income)
        .toList();

    expect(incomeDefaults.length, greaterThanOrEqualTo(9));
    final ids = incomeDefaults.map((c) => c.id).toSet();
    expect(ids, containsAll([
      'cat_salary',
      'cat_bonus',
      'cat_part_time',
      'cat_investment',
      'cat_business',
      'cat_gift_income',
      'cat_secondhand',
      'cat_reimbursement',
      'cat_other_income',
    ]));
  });

  testWidgets('CategoryManagementScreen switches between expense and income tabs and adds custom category',
      (tester) async {
    final expenseCategories = [
      const CategoryModel(
        id: 'cat_food',
        name: '餐饮',
        icon: '🍔',
        colorHex: '#F06B78',
        type: CategoryType.expense,
        isCustom: false,
      ),
      const CategoryModel(
        id: 'cat_custom_pet',
        name: '宠物用品',
        icon: '🏷️',
        colorHex: '#F08A8F',
        type: CategoryType.expense,
        isCustom: true,
      ),
    ];

    final incomeCategories = [
      const CategoryModel(
        id: 'cat_salary',
        name: '工资收入',
        icon: '💰',
        colorHex: '#55B98A',
        type: CategoryType.income,
        isCustom: false,
      ),
      const CategoryModel(
        id: 'cat_part_time',
        name: '兼职副业',
        icon: '💼',
        colorHex: '#4CAF50',
        type: CategoryType.income,
        isCustom: false,
      ),
      const CategoryModel(
        id: 'cat_custom_rent',
        name: '房租收入',
        icon: '🏷️',
        colorHex: '#26A69A',
        type: CategoryType.income,
        isCustom: true,
      ),
    ];

    String? addedName;
    CategoryType? addedType;
    CategoryModel? deletedCategory;

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CategoryManagementScreen(
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
        onAdd: (name, type) async {
          addedName = name;
          addedType = type;
        },
        onDelete: (category) async {
          deletedCategory = category;
        },
      ),
    ));
    await tester.pumpAndSettle();

    // 默认展示支出分类
    expect(find.text('支出分类'), findsOneWidget);
    expect(find.text('收入分类'), findsOneWidget);
    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('宠物用品'), findsOneWidget);

    // 切换到收入分类 Tab
    await tester.tap(find.text('收入分类'));
    await tester.pumpAndSettle();

    expect(find.text('工资'), findsOneWidget);
    expect(find.text('兼职副业'), findsOneWidget);
    expect(find.text('房租收入'), findsOneWidget);

    // 点击删除自定义收入分类
    final deleteButtons = find.byIcon(Icons.close_rounded);
    expect(deleteButtons, findsOneWidget);
    await tester.tap(deleteButtons);
    await tester.pumpAndSettle();
    expect(deletedCategory?.name, '房租收入');

    // 点击浮动按钮添加新的收入分类
    final fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.text('新增收入类别'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '股息分红');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(addedName, '股息分红');
    expect(addedType, CategoryType.income);
  });
}
