import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'PocketBudget'**
  String get appTitle;

  /// No description provided for @offlineBadge.
  ///
  /// In zh, this message translates to:
  /// **'100% 本地留存'**
  String get offlineBadge;

  /// No description provided for @tabDashboard.
  ///
  /// In zh, this message translates to:
  /// **'看板'**
  String get tabDashboard;

  /// No description provided for @tabTransactions.
  ///
  /// In zh, this message translates to:
  /// **'明细'**
  String get tabTransactions;

  /// No description provided for @tabSavings.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄'**
  String get tabSavings;

  /// No description provided for @tabBudget.
  ///
  /// In zh, this message translates to:
  /// **'预算评估'**
  String get tabBudget;

  /// No description provided for @addTransaction.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get addTransaction;

  /// No description provided for @remainingBudget.
  ///
  /// In zh, this message translates to:
  /// **'本月剩余可用预算'**
  String get remainingBudget;

  /// No description provided for @totalBudget.
  ///
  /// In zh, this message translates to:
  /// **'总预算'**
  String get totalBudget;

  /// No description provided for @usedBudget.
  ///
  /// In zh, this message translates to:
  /// **'已支出'**
  String get usedBudget;

  /// No description provided for @dailyAssessmentTitle.
  ///
  /// In zh, this message translates to:
  /// **'日均健康度控制'**
  String get dailyAssessmentTitle;

  /// No description provided for @dailyAssessmentTip.
  ///
  /// In zh, this message translates to:
  /// **'本月还剩 15 天，控制每日支出低于该数值即可完成专项储蓄计划。'**
  String get dailyAssessmentTip;

  /// No description provided for @monthlyExpense.
  ///
  /// In zh, this message translates to:
  /// **'本月总支出'**
  String get monthlyExpense;

  /// No description provided for @savingsAccumulated.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄累计'**
  String get savingsAccumulated;

  /// No description provided for @transactionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'账单交易明细 (本地纯净无追踪)'**
  String get transactionsTitle;

  /// No description provided for @savingsGoalsTitle.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄 (目标看板)'**
  String get savingsGoalsTitle;

  /// No description provided for @budgetSettingTitle.
  ///
  /// In zh, this message translates to:
  /// **'月度预算设定'**
  String get budgetSettingTitle;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @saveToLocal.
  ///
  /// In zh, this message translates to:
  /// **'保存到本地'**
  String get saveToLocal;

  /// No description provided for @timeLabel.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get timeLabel;

  /// No description provided for @amount.
  ///
  /// In zh, this message translates to:
  /// **'金额 (¥)'**
  String get amount;

  /// No description provided for @note.
  ///
  /// In zh, this message translates to:
  /// **'备注 (例如: 午餐、买书)'**
  String get note;

  /// No description provided for @newTransactionTitle.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get newTransactionTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理显示偏好和本地数据'**
  String get settingsSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'外观模式'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选择应用的显示主题'**
  String get appearanceSubtitle;

  /// No description provided for @lightTheme.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get darkTheme;

  /// No description provided for @privacyDefaultHidden.
  ///
  /// In zh, this message translates to:
  /// **'默认隐藏金额'**
  String get privacyDefaultHidden;

  /// No description provided for @privacyDefaultHiddenSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'打开应用时先隐藏所有金额，适合在公共场合使用'**
  String get privacyDefaultHiddenSubtitle;

  /// No description provided for @localStorageTitle.
  ///
  /// In zh, this message translates to:
  /// **'本地存储'**
  String get localStorageTitle;

  /// No description provided for @localStorageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'财务数据仅保存在本机'**
  String get localStorageSubtitle;

  /// No description provided for @languageTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用语言'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选择界面显示语言'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @currencyTitle.
  ///
  /// In zh, this message translates to:
  /// **'记账货币'**
  String get currencyTitle;

  /// No description provided for @currencyLockedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用于所有金额和报表，已有数据后不可更改'**
  String get currencyLockedSubtitle;

  /// No description provided for @initialBalanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'初始余额'**
  String get initialBalanceTitle;

  /// No description provided for @initialBalanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'开始使用时已有的资金，不计入收入统计'**
  String get initialBalanceSubtitle;

  /// No description provided for @initialBalanceLabel.
  ///
  /// In zh, this message translates to:
  /// **'起始金额'**
  String get initialBalanceLabel;

  /// No description provided for @initialBalanceHint.
  ///
  /// In zh, this message translates to:
  /// **'输入开始使用 PocketBudget 时已有的可用资金'**
  String get initialBalanceHint;

  /// No description provided for @initialBalanceInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入大于或等于 0 的有效金额'**
  String get initialBalanceInvalid;

  /// No description provided for @initialBalanceSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始余额保存失败'**
  String get initialBalanceSaveFailed;

  /// No description provided for @currencySetupTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择记账货币'**
  String get currencySetupTitle;

  /// No description provided for @currencySetupMessage.
  ///
  /// In zh, this message translates to:
  /// **'该货币将用于所有预算、交易、专项储蓄和统计。'**
  String get currencySetupMessage;

  /// No description provided for @currencyLabel.
  ///
  /// In zh, this message translates to:
  /// **'货币'**
  String get currencyLabel;

  /// No description provided for @currencyPreview.
  ///
  /// In zh, this message translates to:
  /// **'金额示例'**
  String get currencyPreview;

  /// No description provided for @currencySetupWarning.
  ///
  /// In zh, this message translates to:
  /// **'创建财务数据后，PocketBudget 不会换算或迁移货币。如需更换，请先备份并重置数据。'**
  String get currencySetupWarning;

  /// No description provided for @confirmCurrency.
  ///
  /// In zh, this message translates to:
  /// **'使用{currency}'**
  String confirmCurrency(Object currency);

  /// No description provided for @resetFinancialData.
  ///
  /// In zh, this message translates to:
  /// **'重置财务数据'**
  String get resetFinancialData;

  /// No description provided for @resetFinancialDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'删除交易、预算和专项储蓄，并重新选择货币'**
  String get resetFinancialDataSubtitle;

  /// No description provided for @resetFinancialDataMessage.
  ///
  /// In zh, this message translates to:
  /// **'此操作将永久删除当前设备上的交易、预算、专项储蓄和自定义分类，且不可撤销。请先导出备份。'**
  String get resetFinancialDataMessage;

  /// No description provided for @reset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get reset;

  /// No description provided for @currencyMismatch.
  ///
  /// In zh, this message translates to:
  /// **'备份货币与当前记账货币不一致，无法恢复。'**
  String get currencyMismatch;

  /// No description provided for @dailySpendingLimit.
  ///
  /// In zh, this message translates to:
  /// **'每日建议消费上限'**
  String get dailySpendingLimit;

  /// No description provided for @selectMonth.
  ///
  /// In zh, this message translates to:
  /// **'选择月份'**
  String get selectMonth;

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @noBudgetLimit.
  ///
  /// In zh, this message translates to:
  /// **'无预算限制'**
  String get noBudgetLimit;

  /// No description provided for @perDay.
  ///
  /// In zh, this message translates to:
  /// **'{amount} / 天'**
  String perDay(Object amount);

  /// No description provided for @dailySpendingLimitHint.
  ///
  /// In zh, this message translates to:
  /// **'设置月度预算后可获得每日消费建议。'**
  String get dailySpendingLimitHint;

  /// No description provided for @remainingDaysHint.
  ///
  /// In zh, this message translates to:
  /// **'本月还剩 {days} 天，控制每日开销即可保持当前计划。'**
  String remainingDaysHint(Object days);

  /// No description provided for @monthlyExpenseShort.
  ///
  /// In zh, this message translates to:
  /// **'月支出'**
  String get monthlyExpenseShort;

  /// No description provided for @monthlyIncomeShort.
  ///
  /// In zh, this message translates to:
  /// **'月收入'**
  String get monthlyIncomeShort;

  /// No description provided for @balanceShort.
  ///
  /// In zh, this message translates to:
  /// **'结余'**
  String get balanceShort;

  /// No description provided for @budgetPercent.
  ///
  /// In zh, this message translates to:
  /// **'{percent}% 预算'**
  String budgetPercent(Object percent);

  /// No description provided for @totalAssets.
  ///
  /// In zh, this message translates to:
  /// **'个人总资产'**
  String get totalAssets;

  /// No description provided for @liquidBalance.
  ///
  /// In zh, this message translates to:
  /// **'流动余额: {amount}'**
  String liquidBalance(Object amount);

  /// No description provided for @totalSavings.
  ///
  /// In zh, this message translates to:
  /// **'存钱积蓄: {amount}'**
  String totalSavings(Object amount);

  /// No description provided for @monthlyBudget.
  ///
  /// In zh, this message translates to:
  /// **'本月预算 ({period})'**
  String monthlyBudget(Object period);

  /// No description provided for @remainingBudgetForPeriod.
  ///
  /// In zh, this message translates to:
  /// **'本月剩余可用预算 ({period})'**
  String remainingBudgetForPeriod(Object period);

  /// No description provided for @budgetNotSet.
  ///
  /// In zh, this message translates to:
  /// **'预算：未设置'**
  String get budgetNotSet;

  /// No description provided for @budgetAmount.
  ///
  /// In zh, this message translates to:
  /// **'预算: {amount}'**
  String budgetAmount(Object amount);

  /// No description provided for @spentAmount.
  ///
  /// In zh, this message translates to:
  /// **'已支出: {amount}'**
  String spentAmount(Object amount);

  /// No description provided for @emptyTransactions.
  ///
  /// In zh, this message translates to:
  /// **'暂无记账明细，点击右下角“记一笔”开始记录！'**
  String get emptyTransactions;

  /// No description provided for @pressureLegend.
  ///
  /// In zh, this message translates to:
  /// **'压力图例：'**
  String get pressureLegend;

  /// No description provided for @noTransactionsForDay.
  ///
  /// In zh, this message translates to:
  /// **'当天暂无记录'**
  String get noTransactionsForDay;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @expenseInitial.
  ///
  /// In zh, this message translates to:
  /// **'支'**
  String get expenseInitial;

  /// No description provided for @incomeInitial.
  ///
  /// In zh, this message translates to:
  /// **'收'**
  String get incomeInitial;

  /// No description provided for @pressureVeryLow.
  ///
  /// In zh, this message translates to:
  /// **'很低'**
  String get pressureVeryLow;

  /// No description provided for @pressureLow.
  ///
  /// In zh, this message translates to:
  /// **'偏低'**
  String get pressureLow;

  /// No description provided for @pressureMedium.
  ///
  /// In zh, this message translates to:
  /// **'适中'**
  String get pressureMedium;

  /// No description provided for @pressureHigh.
  ///
  /// In zh, this message translates to:
  /// **'偏高'**
  String get pressureHigh;

  /// No description provided for @pressureVeryHigh.
  ///
  /// In zh, this message translates to:
  /// **'过高'**
  String get pressureVeryHigh;

  /// No description provided for @monthlyBudgetTitle.
  ///
  /// In zh, this message translates to:
  /// **'本月预算'**
  String get monthlyBudgetTitle;

  /// No description provided for @budgetLabel.
  ///
  /// In zh, this message translates to:
  /// **'预算'**
  String get budgetLabel;

  /// No description provided for @usedLabel.
  ///
  /// In zh, this message translates to:
  /// **'已使用'**
  String get usedLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get remainingLabel;

  /// No description provided for @notApplicable.
  ///
  /// In zh, this message translates to:
  /// **'不适用'**
  String get notApplicable;

  /// No description provided for @monthlyUsedPercent.
  ///
  /// In zh, this message translates to:
  /// **'本月已使用 {percent}%'**
  String monthlyUsedPercent(Object percent);

  /// No description provided for @budgetNotSetHint.
  ///
  /// In zh, this message translates to:
  /// **'当前未设置月度预算，消费不会受到预算上限限制。'**
  String get budgetNotSetHint;

  /// No description provided for @monthlyCategorySpending.
  ///
  /// In zh, this message translates to:
  /// **'本月消费分类'**
  String get monthlyCategorySpending;

  /// No description provided for @noCategorySpending.
  ///
  /// In zh, this message translates to:
  /// **'本月尚无消费支出数据'**
  String get noCategorySpending;

  /// No description provided for @offlineBackup.
  ///
  /// In zh, this message translates to:
  /// **'离线数据备份'**
  String get offlineBackup;

  /// No description provided for @offlineBackupHint.
  ///
  /// In zh, this message translates to:
  /// **'所有数据保存在本地，可导出 JSON 备份或恢复已有备份。'**
  String get offlineBackupHint;

  /// No description provided for @exportJson.
  ///
  /// In zh, this message translates to:
  /// **'导出 JSON'**
  String get exportJson;

  /// No description provided for @restoreData.
  ///
  /// In zh, this message translates to:
  /// **'恢复数据'**
  String get restoreData;

  /// No description provided for @categoryFood.
  ///
  /// In zh, this message translates to:
  /// **'餐饮'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In zh, this message translates to:
  /// **'交通'**
  String get categoryTransport;

  /// No description provided for @categoryShopping.
  ///
  /// In zh, this message translates to:
  /// **'购物'**
  String get categoryShopping;

  /// No description provided for @categoryHousing.
  ///
  /// In zh, this message translates to:
  /// **'居住'**
  String get categoryHousing;

  /// No description provided for @categoryEntertainment.
  ///
  /// In zh, this message translates to:
  /// **'娱乐'**
  String get categoryEntertainment;

  /// No description provided for @expenseCategoriesTitle.
  ///
  /// In zh, this message translates to:
  /// **'消费类别'**
  String get expenseCategoriesTitle;

  /// No description provided for @expenseCategoriesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自定义记账时使用的消费类别'**
  String get expenseCategoriesSubtitle;

  /// No description provided for @addExpenseCategory.
  ///
  /// In zh, this message translates to:
  /// **'新增消费类别'**
  String get addExpenseCategory;

  /// No description provided for @categoryNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'类别名称'**
  String get categoryNameLabel;

  /// No description provided for @categoryInUse.
  ///
  /// In zh, this message translates to:
  /// **'该类别已有记账记录，暂时无法删除'**
  String get categoryInUse;

  /// No description provided for @categorySalary.
  ///
  /// In zh, this message translates to:
  /// **'工资'**
  String get categorySalary;

  /// No description provided for @categoryBonus.
  ///
  /// In zh, this message translates to:
  /// **'奖金'**
  String get categoryBonus;

  /// No description provided for @goalCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get goalCompleted;

  /// No description provided for @goalExpired.
  ///
  /// In zh, this message translates to:
  /// **'已到期'**
  String get goalExpired;

  /// No description provided for @goalActive.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get goalActive;

  /// No description provided for @goalActions.
  ///
  /// In zh, this message translates to:
  /// **'目标操作'**
  String get goalActions;

  /// No description provided for @editSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'编辑专项储蓄'**
  String get editSavingsGoal;

  /// No description provided for @archiveSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'归档专项储蓄'**
  String get archiveSavingsGoal;

  /// No description provided for @restoreSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'恢复专项储蓄'**
  String get restoreSavingsGoal;

  /// No description provided for @purgeSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'永久删除'**
  String get purgeSavingsGoal;

  /// No description provided for @deleteSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'删除专项储蓄'**
  String get deleteSavingsGoal;

  /// No description provided for @goalDeadline.
  ///
  /// In zh, this message translates to:
  /// **'目标日期: {date} · 剩余 {days} 天'**
  String goalDeadline(Object date, Object days);

  /// No description provided for @savedAmount.
  ///
  /// In zh, this message translates to:
  /// **'已存: {amount}'**
  String savedAmount(Object amount);

  /// No description provided for @savedAmountLabel.
  ///
  /// In zh, this message translates to:
  /// **'已存入'**
  String get savedAmountLabel;

  /// No description provided for @targetAmount.
  ///
  /// In zh, this message translates to:
  /// **'目标: {amount}'**
  String targetAmount(Object amount);

  /// No description provided for @dailyDepositNeeded.
  ///
  /// In zh, this message translates to:
  /// **'按照当前目标，每日存入 {amount} 可按时完成'**
  String dailyDepositNeeded(Object amount);

  /// No description provided for @goalExpiredRemaining.
  ///
  /// In zh, this message translates to:
  /// **'目标日期已到，仍差 {amount}'**
  String goalExpiredRemaining(Object amount);

  /// No description provided for @archivedGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'已归档，只读；恢复后可继续记录流水。'**
  String get archivedGoalHint;

  /// No description provided for @savingsHistory.
  ///
  /// In zh, this message translates to:
  /// **'流水明细'**
  String get savingsHistory;

  /// No description provided for @withdraw.
  ///
  /// In zh, this message translates to:
  /// **'提取'**
  String get withdraw;

  /// No description provided for @deposit.
  ///
  /// In zh, this message translates to:
  /// **'存入一笔'**
  String get deposit;

  /// No description provided for @archiveSavingsGoalQuestion.
  ///
  /// In zh, this message translates to:
  /// **'归档专项储蓄？'**
  String get archiveSavingsGoalQuestion;

  /// No description provided for @archiveSavingsGoalMessage.
  ///
  /// In zh, this message translates to:
  /// **'“{title}”及其历史流水会被保留，并从进行中的目标中移出。'**
  String archiveSavingsGoalMessage(Object title);

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @archive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get archive;

  /// No description provided for @purgeSavingsGoalQuestion.
  ///
  /// In zh, this message translates to:
  /// **'永久删除专项储蓄？'**
  String get purgeSavingsGoalQuestion;

  /// No description provided for @purgeSavingsGoalMessage.
  ///
  /// In zh, this message translates to:
  /// **'“{title}”没有流水，删除后无法恢复。'**
  String purgeSavingsGoalMessage(Object title);

  /// No description provided for @purge.
  ///
  /// In zh, this message translates to:
  /// **'永久删除'**
  String get purge;

  /// No description provided for @newSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'新建专项储蓄'**
  String get newSavingsGoal;

  /// No description provided for @archived.
  ///
  /// In zh, this message translates to:
  /// **'已归档'**
  String get archived;

  /// No description provided for @noArchivedGoals.
  ///
  /// In zh, this message translates to:
  /// **'还没有已归档的专项储蓄'**
  String get noArchivedGoals;

  /// No description provided for @noActiveGoals.
  ///
  /// In zh, this message translates to:
  /// **'还没有进行中的专项储蓄'**
  String get noActiveGoals;

  /// No description provided for @showAmounts.
  ///
  /// In zh, this message translates to:
  /// **'显示敏感金额'**
  String get showAmounts;

  /// No description provided for @hideAmounts.
  ///
  /// In zh, this message translates to:
  /// **'隐藏敏感金额'**
  String get hideAmounts;

  /// No description provided for @analysisTab.
  ///
  /// In zh, this message translates to:
  /// **'分析'**
  String get analysisTab;

  /// No description provided for @settingsTab.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get settingsTab;

  /// No description provided for @savingsExpenseDeleteHint.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄支出请在计划页的流水明细中删除'**
  String get savingsExpenseDeleteHint;

  /// No description provided for @savingsExpenseEditHint.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄支出请在计划页的流水明细中编辑'**
  String get savingsExpenseEditHint;

  /// No description provided for @goalHistoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'「{title}」流水明细'**
  String goalHistoryTitle(Object title);

  /// No description provided for @noSavingsRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无记录'**
  String get noSavingsRecords;

  /// No description provided for @noNote.
  ///
  /// In zh, this message translates to:
  /// **'未填写备注'**
  String get noNote;

  /// No description provided for @logActions.
  ///
  /// In zh, this message translates to:
  /// **'流水操作'**
  String get logActions;

  /// No description provided for @deleteLogQuestion.
  ///
  /// In zh, this message translates to:
  /// **'删除这笔流水？'**
  String get deleteLogQuestion;

  /// No description provided for @deleteLogMessage.
  ///
  /// In zh, this message translates to:
  /// **'删除后会同步更新“{title}”的余额{budgetText}。'**
  String deleteLogMessage(Object budgetText, Object title);

  /// No description provided for @andBudgetExpense.
  ///
  /// In zh, this message translates to:
  /// **'和预算支出'**
  String get andBudgetExpense;

  /// No description provided for @editLog.
  ///
  /// In zh, this message translates to:
  /// **'编辑流水'**
  String get editLog;

  /// No description provided for @deleteLog.
  ///
  /// In zh, this message translates to:
  /// **'删除流水'**
  String get deleteLog;

  /// No description provided for @exportJsonBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出 JSON 备份'**
  String get exportJsonBackup;

  /// No description provided for @restoreJsonBackup.
  ///
  /// In zh, this message translates to:
  /// **'恢复 JSON 备份'**
  String get restoreJsonBackup;

  /// No description provided for @pasteBackupJson.
  ///
  /// In zh, this message translates to:
  /// **'粘贴备份 JSON'**
  String get pasteBackupJson;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @overwriteRestore.
  ///
  /// In zh, this message translates to:
  /// **'覆盖恢复'**
  String get overwriteRestore;

  /// No description provided for @editTransactionTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑记账'**
  String get editTransactionTitle;

  /// No description provided for @expenseType.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get expenseType;

  /// No description provided for @incomeType.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get incomeType;

  /// No description provided for @amountLabel.
  ///
  /// In zh, this message translates to:
  /// **'金额'**
  String get amountLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In zh, this message translates to:
  /// **'类别'**
  String get categoryLabel;

  /// No description provided for @noteLabel.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get noteLabel;

  /// No description provided for @saveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get saveChanges;

  /// No description provided for @goalNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'目标名称'**
  String get goalNameLabel;

  /// No description provided for @targetAmountLabel.
  ///
  /// In zh, this message translates to:
  /// **'目标金额'**
  String get targetAmountLabel;

  /// No description provided for @targetDateLabel.
  ///
  /// In zh, this message translates to:
  /// **'预计完成日期'**
  String get targetDateLabel;

  /// No description provided for @goalNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入目标名称'**
  String get goalNameRequired;

  /// No description provided for @positiveTargetAmountRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入大于 0 的目标金额'**
  String get positiveTargetAmountRequired;

  /// No description provided for @saveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试'**
  String get saveFailed;

  /// No description provided for @saving.
  ///
  /// In zh, this message translates to:
  /// **'保存中…'**
  String get saving;

  /// No description provided for @createSavingsGoal.
  ///
  /// In zh, this message translates to:
  /// **'创建专项储蓄'**
  String get createSavingsGoal;

  /// No description provided for @withdrawFromGoal.
  ///
  /// In zh, this message translates to:
  /// **'从「{title}」提取'**
  String withdrawFromGoal(Object title);

  /// No description provided for @depositToGoal.
  ///
  /// In zh, this message translates to:
  /// **'向「{title}」存入'**
  String depositToGoal(Object title);

  /// No description provided for @editGoalLog.
  ///
  /// In zh, this message translates to:
  /// **'编辑「{title}」流水'**
  String editGoalLog(Object title);

  /// No description provided for @withdrawAmount.
  ///
  /// In zh, this message translates to:
  /// **'提取金额'**
  String get withdrawAmount;

  /// No description provided for @depositAmount.
  ///
  /// In zh, this message translates to:
  /// **'存入金额'**
  String get depositAmount;

  /// No description provided for @countAgainstBudget.
  ///
  /// In zh, this message translates to:
  /// **'计入本月预算支出'**
  String get countAgainstBudget;

  /// No description provided for @countAgainstBudgetHint.
  ///
  /// In zh, this message translates to:
  /// **'开启后会生成一笔“强迫存钱”支出，减少本月可用预算'**
  String get countAgainstBudgetHint;

  /// No description provided for @positiveAmountRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入大于 0 的金额'**
  String get positiveAmountRequired;

  /// No description provided for @withdrawExceedsBalance.
  ///
  /// In zh, this message translates to:
  /// **'提取金额不能超过当前余额 {amount}'**
  String withdrawExceedsBalance(Object amount);

  /// No description provided for @saveFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试（{error}）'**
  String saveFailedWithError(Object error);

  /// No description provided for @confirmWithdraw.
  ///
  /// In zh, this message translates to:
  /// **'确认提取'**
  String get confirmWithdraw;

  /// No description provided for @confirmDeposit.
  ///
  /// In zh, this message translates to:
  /// **'确认存入'**
  String get confirmDeposit;

  /// No description provided for @editMonthlyBudget.
  ///
  /// In zh, this message translates to:
  /// **'编辑本月预算'**
  String get editMonthlyBudget;

  /// No description provided for @budgetLimitLabel.
  ///
  /// In zh, this message translates to:
  /// **'预算上限'**
  String get budgetLimitLabel;

  /// No description provided for @nonNegativeBudgetRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入不小于 0 的预算金额'**
  String get nonNegativeBudgetRequired;

  /// No description provided for @saveBudget.
  ///
  /// In zh, this message translates to:
  /// **'保存预算'**
  String get saveBudget;

  /// No description provided for @exportReadableBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出可读备份'**
  String get exportReadableBackup;

  /// No description provided for @readableBackupWarning.
  ///
  /// In zh, this message translates to:
  /// **'仅用于查看和审计；此文件未加密，不能用于恢复。'**
  String get readableBackupWarning;

  /// No description provided for @exportEncryptedBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出加密备份'**
  String get exportEncryptedBackup;

  /// No description provided for @restoreEncryptedBackup.
  ///
  /// In zh, this message translates to:
  /// **'恢复加密备份'**
  String get restoreEncryptedBackup;

  /// No description provided for @backupPassword.
  ///
  /// In zh, this message translates to:
  /// **'备份密码（至少 8 个字符）'**
  String get backupPassword;

  /// No description provided for @confirmBackupPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认备份密码'**
  String get confirmBackupPassword;

  /// No description provided for @continueLabel.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
