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

  @override
  String get settingsTitle => '我的';

  @override
  String get settingsSubtitle => '管理显示偏好和本地数据';

  @override
  String get appearanceTitle => '外观模式';

  @override
  String get appearanceSubtitle => '选择应用的显示主题';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get privacyDefaultHidden => '默认隐藏金额';

  @override
  String get privacyDefaultHiddenSubtitle => '打开应用时先隐藏所有金额，适合在公共场合使用';

  @override
  String get localStorageTitle => '本地存储';

  @override
  String get localStorageSubtitle => '财务数据仅保存在本机';

  @override
  String get languageTitle => '应用语言';

  @override
  String get languageSubtitle => '选择界面显示语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get dailySpendingLimit => '每日建议消费上限';

  @override
  String get selectMonth => '选择月份';

  @override
  String get today => '今天';

  @override
  String get noBudgetLimit => '无预算限制';

  @override
  String perDay(Object amount) {
    return '$amount / 天';
  }

  @override
  String get dailySpendingLimitHint => '设置月度预算后可获得每日消费建议。';

  @override
  String remainingDaysHint(Object days) {
    return '本月还剩 $days 天，控制每日开销即可保持当前计划。';
  }

  @override
  String get monthlyExpenseShort => '月支出';

  @override
  String get monthlyIncomeShort => '月收入';

  @override
  String get balanceShort => '结余';

  @override
  String budgetPercent(Object percent) {
    return '$percent% 预算';
  }

  @override
  String get totalAssets => '个人总资产';

  @override
  String liquidBalance(Object amount) {
    return '流动余额: $amount';
  }

  @override
  String totalSavings(Object amount) {
    return '存钱积蓄: $amount';
  }

  @override
  String monthlyBudget(Object period) {
    return '本月预算 ($period)';
  }

  @override
  String remainingBudgetForPeriod(Object period) {
    return '本月剩余可用预算 ($period)';
  }

  @override
  String get budgetNotSet => '预算：未设置';

  @override
  String budgetAmount(Object amount) {
    return '预算: $amount';
  }

  @override
  String spentAmount(Object amount) {
    return '已支出: $amount';
  }

  @override
  String get emptyTransactions => '暂无记账明细，点击右下角“记一笔”开始记录！';

  @override
  String get pressureLegend => '压力图例：';

  @override
  String get noTransactionsForDay => '当天暂无记录';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get expenseInitial => '支';

  @override
  String get incomeInitial => '收';

  @override
  String get pressureVeryLow => '很低';

  @override
  String get pressureLow => '偏低';

  @override
  String get pressureMedium => '适中';

  @override
  String get pressureHigh => '偏高';

  @override
  String get pressureVeryHigh => '过高';

  @override
  String get monthlyBudgetTitle => '本月预算';

  @override
  String get budgetLabel => '预算';

  @override
  String get usedLabel => '已使用';

  @override
  String get remainingLabel => '剩余';

  @override
  String get notApplicable => '不适用';

  @override
  String monthlyUsedPercent(Object percent) {
    return '本月已使用 $percent%';
  }

  @override
  String get budgetNotSetHint => '当前未设置月度预算，消费不会受到预算上限限制。';

  @override
  String get monthlyCategorySpending => '本月消费分类';

  @override
  String get noCategorySpending => '本月尚无消费支出数据';

  @override
  String get offlineBackup => '离线数据备份';

  @override
  String get offlineBackupHint => '所有数据保存在本地，可导出 JSON 备份或恢复已有备份。';

  @override
  String get exportJson => '导出 JSON';

  @override
  String get restoreData => '恢复数据';

  @override
  String get categoryFood => '餐饮';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryShopping => '购物';

  @override
  String get categoryHousing => '居住';

  @override
  String get categoryEntertainment => '娱乐';

  @override
  String get categorySalary => '工资';

  @override
  String get categoryBonus => '奖金';

  @override
  String get goalCompleted => '已完成';

  @override
  String get goalExpired => '已到期';

  @override
  String get goalActive => '进行中';

  @override
  String get goalActions => '目标操作';

  @override
  String get editSavingsGoal => '编辑专项储蓄';

  @override
  String get archiveSavingsGoal => '归档专项储蓄';

  @override
  String get restoreSavingsGoal => '恢复专项储蓄';

  @override
  String get purgeSavingsGoal => '永久删除';

  @override
  String get deleteSavingsGoal => '删除专项储蓄';

  @override
  String goalDeadline(Object date, Object days) {
    return '目标日期: $date · 剩余 $days 天';
  }

  @override
  String savedAmount(Object amount) {
    return '已存: $amount';
  }

  @override
  String targetAmount(Object amount) {
    return '目标: $amount';
  }

  @override
  String dailyDepositNeeded(Object amount) {
    return '按照当前目标，每日存入 $amount 可按时完成';
  }

  @override
  String goalExpiredRemaining(Object amount) {
    return '目标日期已到，仍差 $amount';
  }

  @override
  String get archivedGoalHint => '已归档，只读；恢复后可继续记录流水。';

  @override
  String get savingsHistory => '流水明细';

  @override
  String get withdraw => '提取';

  @override
  String get deposit => '存入一笔';

  @override
  String get archiveSavingsGoalQuestion => '归档专项储蓄？';

  @override
  String archiveSavingsGoalMessage(Object title) {
    return '“$title”及其历史流水会被保留，并从进行中的目标中移出。';
  }

  @override
  String get cancel => '取消';

  @override
  String get archive => '归档';

  @override
  String get purgeSavingsGoalQuestion => '永久删除专项储蓄？';

  @override
  String purgeSavingsGoalMessage(Object title) {
    return '“$title”没有流水，删除后无法恢复。';
  }

  @override
  String get purge => '永久删除';

  @override
  String get newSavingsGoal => '新建专项储蓄';

  @override
  String get archived => '已归档';

  @override
  String get noArchivedGoals => '还没有已归档的专项储蓄';

  @override
  String get noActiveGoals => '还没有进行中的专项储蓄';

  @override
  String get showAmounts => '显示敏感金额';

  @override
  String get hideAmounts => '隐藏敏感金额';

  @override
  String get analysisTab => '分析';

  @override
  String get settingsTab => '我的';

  @override
  String get savingsExpenseDeleteHint => '专项储蓄支出请在计划页的流水明细中删除';

  @override
  String get savingsExpenseEditHint => '专项储蓄支出请在计划页的流水明细中编辑';

  @override
  String goalHistoryTitle(Object title) {
    return '「$title」流水明细';
  }

  @override
  String get noSavingsRecords => '暂无记录';

  @override
  String get noNote => '未填写备注';

  @override
  String get logActions => '流水操作';

  @override
  String get deleteLogQuestion => '删除这笔流水？';

  @override
  String deleteLogMessage(Object budgetText, Object title) {
    return '删除后会同步更新“$title”的余额$budgetText。';
  }

  @override
  String get andBudgetExpense => '和预算支出';

  @override
  String get editLog => '编辑流水';

  @override
  String get deleteLog => '删除流水';

  @override
  String get exportJsonBackup => '导出 JSON 备份';

  @override
  String get restoreJsonBackup => '恢复 JSON 备份';

  @override
  String get pasteBackupJson => '粘贴备份 JSON';

  @override
  String get close => '关闭';

  @override
  String get copy => '复制';

  @override
  String get overwriteRestore => '覆盖恢复';

  @override
  String get editTransactionTitle => '编辑记账明细';

  @override
  String get expenseType => '支出';

  @override
  String get incomeType => '收入';

  @override
  String get amountLabel => '金额';

  @override
  String get categoryLabel => '类别';

  @override
  String get noteLabel => '备注';

  @override
  String get saveChanges => '保存修改';

  @override
  String get goalNameLabel => '目标名称';

  @override
  String get targetAmountLabel => '目标金额';

  @override
  String get targetDateLabel => '预计完成日期';

  @override
  String get goalNameRequired => '请输入目标名称';

  @override
  String get positiveTargetAmountRequired => '请输入大于 0 的目标金额';

  @override
  String get saveFailed => '保存失败，请重试';

  @override
  String get saving => '保存中…';

  @override
  String get createSavingsGoal => '创建专项储蓄';

  @override
  String withdrawFromGoal(Object title) {
    return '从「$title」提取';
  }

  @override
  String depositToGoal(Object title) {
    return '向「$title」存入';
  }

  @override
  String editGoalLog(Object title) {
    return '编辑「$title」流水';
  }

  @override
  String get withdrawAmount => '提取金额';

  @override
  String get depositAmount => '存入金额';

  @override
  String get countAgainstBudget => '计入本月预算支出';

  @override
  String get countAgainstBudgetHint => '开启后会生成一笔“强迫存钱”支出，减少本月可用预算';

  @override
  String get positiveAmountRequired => '请输入大于 0 的金额';

  @override
  String withdrawExceedsBalance(Object amount) {
    return '提取金额不能超过当前余额 $amount';
  }

  @override
  String saveFailedWithError(Object error) {
    return '保存失败，请重试（$error）';
  }

  @override
  String get confirmWithdraw => '确认提取';

  @override
  String get confirmDeposit => '确认存入';

  @override
  String get editMonthlyBudget => '编辑本月预算';

  @override
  String get budgetLimitLabel => '预算上限';

  @override
  String get nonNegativeBudgetRequired => '请输入不小于 0 的预算金额';

  @override
  String get saveBudget => '保存预算';
}
