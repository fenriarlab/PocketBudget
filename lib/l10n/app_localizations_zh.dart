// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'PocketBudget 简预算';

  @override
  String get offlineBadge => '100% 本地留存';

  @override
  String get tabDashboard => '看板';

  @override
  String get tabTransactions => '明细';

  @override
  String get tabSavings => '专项储蓄';

  @override
  String get tabBudget => '预算评估';

  @override
  String get addTransaction => '记一笔';

  @override
  String get remainingBudget => '本月剩余可用预算';

  @override
  String get totalBudget => '总预算';

  @override
  String get usedBudget => '已支出';

  @override
  String get dailyAssessmentTitle => '日均健康度控制';

  @override
  String get dailyAssessmentTip => '本月还剩 15 天，控制每日支出低于该数值即可完成专项储蓄计划。';

  @override
  String get monthlyExpense => '本月总支出';

  @override
  String get savingsAccumulated => '专项储蓄累计';

  @override
  String get transactionsTitle => '账单交易明细 (本地纯净无追踪)';

  @override
  String get savingsGoalsTitle => '专项储蓄 (目标看板)';

  @override
  String get budgetSettingTitle => '月度预算设定';

  @override
  String get save => '保存';

  @override
  String get saveToLocal => '保存到本地';

  @override
  String get amount => '金额 (¥)';

  @override
  String get note => '备注 (例如: 午餐、买书)';

  @override
  String get newTransactionTitle => '新增记账明细';
}
