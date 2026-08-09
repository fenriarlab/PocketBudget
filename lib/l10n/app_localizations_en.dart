// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PocketBudget';

  @override
  String get offlineBadge => '100% Offline';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabTransactions => 'Transactions';

  @override
  String get tabSavings => 'Sinking Funds';

  @override
  String get tabBudget => 'Budget';

  @override
  String get addTransaction => 'Add Expense';

  @override
  String get remainingBudget => 'Remaining Monthly Budget';

  @override
  String get totalBudget => 'Total Budget';

  @override
  String get usedBudget => 'Spent';

  @override
  String get dailyAssessmentTitle => 'Daily Spending Limit';

  @override
  String get dailyAssessmentTip =>
      '15 days remaining this month. Keep daily spending below this amount to stay on track with your sinking funds.';

  @override
  String get monthlyExpense => 'Total Expense';

  @override
  String get savingsAccumulated => 'Sinking Funds Total';

  @override
  String get transactionsTitle => 'Transaction History (100% Offline)';

  @override
  String get savingsGoalsTitle => 'Sinking Funds';

  @override
  String get budgetSettingTitle => 'Monthly Budget Limit';

  @override
  String get save => 'Save';

  @override
  String get saveToLocal => 'Save Locally';

  @override
  String get amount => 'Amount (¥)';

  @override
  String get note => 'Note (e.g. Lunch, Book)';

  @override
  String get newTransactionTitle => 'New Transaction';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Manage display preferences and local data';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Choose the app theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get privacyDefaultHidden => 'Hide amounts by default';

  @override
  String get privacyDefaultHiddenSubtitle =>
      'Hide all amounts when opening the app in public places';

  @override
  String get localStorageTitle => 'Local storage';

  @override
  String get localStorageSubtitle =>
      'Financial data is stored only on this device';

  @override
  String get languageTitle => 'App language';

  @override
  String get languageSubtitle => 'Choose the interface language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageChinese => 'Simplified Chinese';

  @override
  String get languageEnglish => 'English';

  @override
  String get currencyTitle => 'Bookkeeping currency';

  @override
  String get currencyLockedSubtitle =>
      'Used for all amounts and reports; locked after data is created';

  @override
  String get currencySetupTitle => 'Choose a bookkeeping currency';

  @override
  String get currencySetupMessage =>
      'This currency will be used for all budgets, transactions, sinking funds, and reports.';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get currencyPreview => 'Amount preview';

  @override
  String get currencySetupWarning =>
      'PocketBudget does not convert or migrate currencies after financial data is created. Back up and reset data to change it.';

  @override
  String confirmCurrency(Object currency) {
    return 'Use $currency';
  }

  @override
  String get resetFinancialData => 'Reset financial data';

  @override
  String get resetFinancialDataSubtitle =>
      'Delete transactions, budgets, and sinking funds, then choose a currency again';

  @override
  String get resetFinancialDataMessage =>
      'This permanently deletes transactions, budgets, sinking funds, and custom categories on this device. Export a backup first.';

  @override
  String get reset => 'Reset';

  @override
  String get currencyMismatch =>
      'The backup currency does not match the current bookkeeping currency. Restore was blocked.';

  @override
  String get dailySpendingLimit => 'Daily spending limit';

  @override
  String get selectMonth => 'Select month';

  @override
  String get today => 'Today';

  @override
  String get noBudgetLimit => 'No budget limit';

  @override
  String perDay(Object amount) {
    return '$amount / day';
  }

  @override
  String get dailySpendingLimitHint =>
      'Set a monthly budget to get a daily spending recommendation.';

  @override
  String remainingDaysHint(Object days) {
    return '$days days remain this month. Keep daily spending on track.';
  }

  @override
  String get monthlyExpenseShort => 'Monthly expense';

  @override
  String get monthlyIncomeShort => 'Monthly income';

  @override
  String get balanceShort => 'Balance';

  @override
  String budgetPercent(Object percent) {
    return '$percent% budget';
  }

  @override
  String get totalAssets => 'Total assets';

  @override
  String liquidBalance(Object amount) {
    return 'Liquid balance: $amount';
  }

  @override
  String totalSavings(Object amount) {
    return 'Savings: $amount';
  }

  @override
  String monthlyBudget(Object period) {
    return 'Monthly budget ($period)';
  }

  @override
  String remainingBudgetForPeriod(Object period) {
    return 'Remaining budget ($period)';
  }

  @override
  String get budgetNotSet => 'Budget: not set';

  @override
  String budgetAmount(Object amount) {
    return 'Budget: $amount';
  }

  @override
  String spentAmount(Object amount) {
    return 'Spent: $amount';
  }

  @override
  String get emptyTransactions =>
      'No transactions yet. Tap the add button to record one.';

  @override
  String get pressureLegend => 'Spending pressure:';

  @override
  String get noTransactionsForDay => 'No transactions for this day';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get expenseInitial => 'E';

  @override
  String get incomeInitial => 'I';

  @override
  String get pressureVeryLow => 'Very low';

  @override
  String get pressureLow => 'Low';

  @override
  String get pressureMedium => 'Moderate';

  @override
  String get pressureHigh => 'High';

  @override
  String get pressureVeryHigh => 'Very high';

  @override
  String get monthlyBudgetTitle => 'Monthly budget';

  @override
  String get budgetLabel => 'Budget';

  @override
  String get usedLabel => 'Used';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get notApplicable => 'N/A';

  @override
  String monthlyUsedPercent(Object percent) {
    return '$percent% used this month';
  }

  @override
  String get budgetNotSetHint =>
      'No monthly budget is set, so spending has no budget limit.';

  @override
  String get monthlyCategorySpending => 'Spending by category this month';

  @override
  String get noCategorySpending => 'No spending data this month';

  @override
  String get offlineBackup => 'Offline data backup';

  @override
  String get offlineBackupHint =>
      'All data is stored locally. Export a JSON backup or restore an existing one.';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get restoreData => 'Restore data';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryBonus => 'Bonus';

  @override
  String get goalCompleted => 'Completed';

  @override
  String get goalExpired => 'Expired';

  @override
  String get goalActive => 'Active';

  @override
  String get goalActions => 'Goal actions';

  @override
  String get editSavingsGoal => 'Edit sinking fund';

  @override
  String get archiveSavingsGoal => 'Archive sinking fund';

  @override
  String get restoreSavingsGoal => 'Restore sinking fund';

  @override
  String get purgeSavingsGoal => 'Delete permanently';

  @override
  String get deleteSavingsGoal => 'Delete sinking fund';

  @override
  String goalDeadline(Object date, Object days) {
    return 'Target date: $date · $days days left';
  }

  @override
  String savedAmount(Object amount) {
    return 'Saved: $amount';
  }

  @override
  String targetAmount(Object amount) {
    return 'Target: $amount';
  }

  @override
  String dailyDepositNeeded(Object amount) {
    return 'Deposit $amount per day to stay on track';
  }

  @override
  String goalExpiredRemaining(Object amount) {
    return 'Target date reached, $amount still needed';
  }

  @override
  String get archivedGoalHint =>
      'Archived and read-only. Restore it to record new activity.';

  @override
  String get savingsHistory => 'Activity';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get deposit => 'Deposit';

  @override
  String get archiveSavingsGoalQuestion => 'Archive sinking fund?';

  @override
  String archiveSavingsGoalMessage(Object title) {
    return '“$title” and its history will be kept and removed from active goals.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get archive => 'Archive';

  @override
  String get purgeSavingsGoalQuestion => 'Delete sinking fund permanently?';

  @override
  String purgeSavingsGoalMessage(Object title) {
    return '“$title” has no activity. It cannot be recovered after deletion.';
  }

  @override
  String get purge => 'Delete permanently';

  @override
  String get newSavingsGoal => 'New sinking fund';

  @override
  String get archived => 'Archived';

  @override
  String get noArchivedGoals => 'No archived sinking funds';

  @override
  String get noActiveGoals => 'No active sinking funds';

  @override
  String get showAmounts => 'Show sensitive amounts';

  @override
  String get hideAmounts => 'Hide sensitive amounts';

  @override
  String get analysisTab => 'Analysis';

  @override
  String get settingsTab => 'Settings';

  @override
  String get savingsExpenseDeleteHint =>
      'Delete sinking fund spending from the activity list on the Plan tab';

  @override
  String get savingsExpenseEditHint =>
      'Edit sinking fund spending from the activity list on the Plan tab';

  @override
  String goalHistoryTitle(Object title) {
    return 'Activity for “$title”';
  }

  @override
  String get noSavingsRecords => 'No activity';

  @override
  String get noNote => 'No note';

  @override
  String get logActions => 'Activity actions';

  @override
  String get deleteLogQuestion => 'Delete this activity?';

  @override
  String deleteLogMessage(Object budgetText, Object title) {
    return 'Deleting it will update the balance for “$title”$budgetText.';
  }

  @override
  String get andBudgetExpense => ' and budget spending';

  @override
  String get editLog => 'Edit activity';

  @override
  String get deleteLog => 'Delete activity';

  @override
  String get exportJsonBackup => 'Export JSON backup';

  @override
  String get restoreJsonBackup => 'Restore JSON backup';

  @override
  String get pasteBackupJson => 'Paste backup JSON';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get overwriteRestore => 'Overwrite and restore';

  @override
  String get editTransactionTitle => 'Edit transaction';

  @override
  String get expenseType => 'Expense';

  @override
  String get incomeType => 'Income';

  @override
  String get amountLabel => 'Amount';

  @override
  String get categoryLabel => 'Category';

  @override
  String get noteLabel => 'Note';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get goalNameLabel => 'Goal name';

  @override
  String get targetAmountLabel => 'Target amount';

  @override
  String get targetDateLabel => 'Target date';

  @override
  String get goalNameRequired => 'Enter a goal name';

  @override
  String get positiveTargetAmountRequired =>
      'Enter a target amount greater than 0';

  @override
  String get saveFailed => 'Save failed. Please try again.';

  @override
  String get saving => 'Saving…';

  @override
  String get createSavingsGoal => 'Create sinking fund';

  @override
  String withdrawFromGoal(Object title) {
    return 'Withdraw from “$title”';
  }

  @override
  String depositToGoal(Object title) {
    return 'Deposit into “$title”';
  }

  @override
  String editGoalLog(Object title) {
    return 'Edit activity for “$title”';
  }

  @override
  String get withdrawAmount => 'Withdrawal amount';

  @override
  String get depositAmount => 'Deposit amount';

  @override
  String get countAgainstBudget => 'Count toward monthly spending';

  @override
  String get countAgainstBudgetHint =>
      'This creates a forced-savings expense and reduces the available monthly budget';

  @override
  String get positiveAmountRequired => 'Enter an amount greater than 0';

  @override
  String withdrawExceedsBalance(Object amount) {
    return 'Withdrawal cannot exceed the current balance of $amount';
  }

  @override
  String saveFailedWithError(Object error) {
    return 'Save failed. Please try again ($error)';
  }

  @override
  String get confirmWithdraw => 'Confirm withdrawal';

  @override
  String get confirmDeposit => 'Confirm deposit';

  @override
  String get editMonthlyBudget => 'Edit monthly budget';

  @override
  String get budgetLimitLabel => 'Budget limit';

  @override
  String get nonNegativeBudgetRequired => 'Enter a budget amount of 0 or more';

  @override
  String get saveBudget => 'Save budget';

  @override
  String get exportReadableBackup => 'Export readable backup';

  @override
  String get readableBackupWarning =>
      'For viewing and audit only; this file is unencrypted and cannot be restored.';

  @override
  String get exportEncryptedBackup => 'Export encrypted backup';

  @override
  String get restoreEncryptedBackup => 'Restore encrypted backup';

  @override
  String get backupPassword => 'Backup password (8+ characters)';

  @override
  String get confirmBackupPassword => 'Confirm backup password';

  @override
  String get continueLabel => 'Continue';
}
