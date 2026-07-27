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
  String get tabSavings => 'Savings';

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
      '15 days remaining this month. Keep daily spending below this amount to stay on budget.';

  @override
  String get monthlyExpense => 'Total Expense';

  @override
  String get savingsAccumulated => 'Total Savings';

  @override
  String get transactionsTitle => 'Transaction History (100% Offline)';

  @override
  String get savingsGoalsTitle => 'Savings Goals';

  @override
  String get budgetSettingTitle => 'Monthly Budget Limit';

  @override
  String get save => 'Save';

  @override
  String get saveToLocal => 'Save Locally';

  @override
  String get amount => 'Amount (\$)';

  @override
  String get note => 'Note (e.g. Lunch, Book)';

  @override
  String get newTransactionTitle => 'New Transaction';
}
