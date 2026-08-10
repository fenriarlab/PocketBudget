import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/month_period.dart';
import '../../../analysis/presentation/screens/analysis_screen.dart';
import '../../../backup/data/backup_repository.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../budget/data/budget_allocation_repository.dart';
import '../../../budget/data/budget_repository.dart';
import '../../domain/services/monthly_financial_calculator.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../savings/data/models/savings_log_model.dart';
import '../../../savings/data/savings_repository.dart';
import '../../../plan/presentation/screens/plan_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../initial_balance/data/initial_balance_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/transaction_repository.dart';
import 'dashboard_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String languagePreference;
  final ValueChanged<String> onLanguageChanged;
  final String currencyCode;
  final Future<void> Function() onCurrencyReset;

  const HomeDashboardScreen(
      {super.key,
      required this.themeMode,
      required this.onThemeModeChanged,
      required this.languagePreference,
      required this.onLanguageChanged,
      required this.currencyCode,
      required this.onCurrencyReset});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _transactionRepository = TransactionRepository();
  final _savingsRepository = SavingsRepository();
  final _budgetRepository = BudgetRepository();
  final _budgetAllocationRepository = BudgetAllocationRepository();
  final _backupRepository = BackupRepository();
  final _initialBalanceRepository = InitialBalanceRepository();
  final _categoryRepository = CategoryRepository();
  final _financialCalculator = const MonthlyFinancialCalculator();

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _privacyHidden = true;
  bool _privacyDefaultHidden = true;
  bool _isBottomSheetOpen = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<TransactionModel> _transactions = [];
  List<SavingsGoalModel> _goals = [];
  List<SavingsGoalModel> _archivedGoals = [];
  double? _monthlyBudget;
  double _monthlyExpense = 0;
  double _monthlyIncome = 0;
  double _monthlyBudgetedSavings = 0;
  double _initialBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<CategoryModel> _expenseCategories = [];

  String get _currentPeriod => MonthPeriod.fromDate(_selectedMonth).key;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPreference();
    _loadData();
  }

  Future<void> _loadPrivacyPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final defaultHidden = preferences.getBool('privacy_default_hidden') ?? true;
    if (mounted) {
      setState(() {
        _privacyDefaultHidden = defaultHidden;
        _privacyHidden = defaultHidden;
      });
    }
  }

  Future<void> _togglePrivacy() async {
    final nextValue = !_privacyHidden;
    if (mounted) {
      setState(() => _privacyHidden = nextValue);
    }
  }

  Future<void> _setPrivacyDefaultHidden(bool hidden) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('privacy_default_hidden', hidden);
    if (mounted) {
      setState(() {
        _privacyDefaultHidden = hidden;
        _privacyHidden = hidden;
      });
    }
  }

  Future<void> _loadData() async {
    final transactions = await _transactionRepository.getAllTransactions();
    final goals = await _savingsRepository.getAllGoals();
    final archivedGoals = await _savingsRepository.getArchivedGoals();
    final savingsLogs = await _savingsRepository.getAllLogs();
    final budget = await _budgetRepository.getBudget(_currentPeriod);
    final budgetAllocations =
        await _budgetAllocationRepository.getByPeriod(_currentPeriod);
    final initialBalance = await _initialBalanceRepository.getInitialBalance();
    final expenseCategories = await _categoryRepository.getCategories(type: CategoryType.expense);
    _expenseCategories = expenseCategories;
    var totalIncome = 0.0;
    var totalExpense = 0.0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else if (transaction.categoryId != 'cat_savings') {
        totalExpense += transaction.amount;
      }
    }
    final snapshot = _financialCalculator.calculate(
      period: MonthPeriod.parse(_currentPeriod),
      transactions: transactions,
      savingsLogs: savingsLogs,
      budgetAllocations: budgetAllocations,
      budget: budget,
    );
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _goals = goals;
      _archivedGoals = archivedGoals;
      _monthlyExpense = snapshot.consumption;
      _monthlyIncome = snapshot.income;
      _monthlyBudgetedSavings = snapshot.budgetedSavings;
      _monthlyBudget = budget?.totalBudget;
      _initialBalance = initialBalance;
      _totalIncome = totalIncome;
      _totalExpense = totalExpense;
      _expenseCategories = expenseCategories;
      _isLoading = false;
    });
  }

  void _changeMonth(DateTime month) {
    setState(() {
      _selectedMonth = DateTime(month.year, month.month);
      _selectedDate = DateTime(month.year, month.month, 1);
      _isLoading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: _privacyHidden ? l10n.showAmounts : l10n.hideAmounts,
            icon:
                Icon(_privacyHidden ? Icons.visibility_off : Icons.visibility),
            onPressed: _togglePrivacy,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPage(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showTransactionSheet(_selectedDate),
              tooltip: l10n.addTransaction,
              child: const Icon(Icons.add, size: 28))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: l10n.tabDashboard),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: l10n.tabBudget),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: l10n.analysisTab),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: l10n.settingsTab),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return PlanScreen(
          goals: _goals,
          archivedGoals: _archivedGoals,
          privacyHidden: _privacyHidden,
          currentPeriod: _currentPeriod,
          monthlyBudget: _monthlyBudget,
          monthlyExpense: _monthlyExpense,
          monthlyBudgetedSavings: _monthlyBudgetedSavings,
          currencyCode: widget.currencyCode,
          onEditBudget: () => _showBudgetSheet(),
          onAddGoal: _showGoalSheet,
          onArchive: (goal) async {
            await _savingsRepository.archiveGoal(goal.id);
            await _loadData();
          },
          onEdit: _showEditGoalSheet,
          onRestore: (goal) async {
            await _savingsRepository.restoreGoal(goal.id);
            await _loadData();
          },
          onPurge: (goal) async {
            await _savingsRepository.purgeEmptyGoal(goal.id);
            await _loadData();
          },
          onHistory: _showGoalHistory,
          onDeposit: _showDepositSheet,
        );
      case 2:
        return AnalysisScreen(
          transactions: _transactions,
          privacyHidden: _privacyHidden,
          currencyCode: widget.currencyCode,
        );
      case 3:
        return SettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          languagePreference: widget.languagePreference,
          onLanguageChanged: widget.onLanguageChanged,
          currencyCode: widget.currencyCode,
          onResetData: _confirmAndResetData,
          onExportReadableBackup: _showExportReadableBackup,
          onExportEncryptedBackup: _showExportEncryptedBackup,
          onRestoreBackup: _showRestoreBackup,
          initialBalance: _initialBalance,
          onEditInitialBalance: _showInitialBalanceDialog,
          expenseCategories: _expenseCategories,
          onAddExpenseCategory: (name) async {
            await _categoryRepository.addExpenseCategory(name);
            await _loadData();
          },
          onDeleteExpenseCategory: (category) async {
            final deleted = await _categoryRepository.deleteCategory(category);
            if (!deleted && mounted) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.categoryInUse)),
              );
            }
            await _loadData();
          },
          privacyDefaultHidden: _privacyDefaultHidden,
          onPrivacyDefaultChanged: _setPrivacyDefaultHidden,
        );
      default:
        return DashboardScreen(
          monthlyBudget: _monthlyBudget,
          monthlyExpense: _monthlyExpense,
          monthlyIncome: _monthlyIncome,
          totalIncome: _totalIncome,
          totalExpense: _totalExpense,
          initialBalance: _initialBalance,
          budgetedSavings: _monthlyBudgetedSavings,
          goals: _goals,
          currentPeriod: _currentPeriod,
          privacyHidden: _privacyHidden,
          currencyCode: widget.currencyCode,
          transactions: _transactions,
          selectedMonth: _selectedMonth,
          selectedDate: _selectedDate,
          dailyQuota: _monthlyBudget == null
              ? null
              : _monthlyBudget! /
                  DateUtils.getDaysInMonth(
                      _selectedMonth.year, _selectedMonth.month),
          onMonthChanged: _changeMonth,
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onDelete: _deleteTransaction,
          onEdit: _showEditTransactionSheet,
          onAdd: _showTransactionSheet,
        );
    }
  }

  Future<void> _showTransactionSheet(DateTime date) async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => _TransactionSheet(
        date: date,
        expenseCategories: _expenseCategories,
        onSave: (transaction) async {
          await _transactionRepository.insertTransaction(transaction);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final l10n = AppLocalizations.of(context)!;
    if (transaction.id.startsWith('tx_savings_')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.savingsExpenseDeleteHint)));
      }
      return;
    }
    await _transactionRepository.deleteTransaction(transaction.id);
    if (mounted) _loadData();
  }

  Future<void> _showEditTransactionSheet(TransactionModel transaction) async {
    final l10n = AppLocalizations.of(context)!;
    if (transaction.id.startsWith('tx_savings_')) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.savingsExpenseEditHint)));
      }
      return;
    }
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => _TransactionSheet(
        date: transaction.date,
        initialTransaction: transaction,
        expenseCategories: _expenseCategories,
        onSave: (updatedTransaction) async {
          await _transactionRepository.updateTransaction(updatedTransaction);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showGoalSheet() async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => SavingsGoalSheet(
        onSave: (goal) async {
          await _savingsRepository.insertGoal(goal);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showEditGoalSheet(SavingsGoalModel goal) async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => SavingsGoalSheet(
        initialGoal: goal,
        onSave: (updatedGoal) async {
          await _savingsRepository.updateGoal(updatedGoal);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showBudgetSheet() async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => _BudgetSheet(
        initialBudget: _monthlyBudget ?? 0,
        onSave: (budget) async {
          await _budgetRepository.setBudget(_currentPeriod, budget);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showDepositSheet(SavingsGoalModel goal, bool isWithdraw) async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => SavingsDepositSheet(
        goal: goal,
        isWithdraw: isWithdraw,
        onSave: (log, deductFromBudget) async {
          await _savingsRepository.addSavingsLog(log,
              deductFromBudget: deductFromBudget);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showEditSavingsLogSheet(
      SavingsGoalModel goal, SavingsLogModel log) async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => SavingsDepositSheet(
        goal: goal,
        isWithdraw: !log.isDeposit,
        initialLog: log,
        onSave: (updatedLog, deductFromBudget) async {
          await _savingsRepository.updateSavingsLog(updatedLog,
              deductFromBudget: deductFromBudget);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showGoalHistory(SavingsGoalModel goal) async {
    final logs = await _savingsRepository.getLogsForGoal(goal.id);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final action = await _showBottomSheet<String>(
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.goalHistoryTitle(goal.title),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Text(l10n.noSavingsRecords,
                  style: TextStyle(color: AppColors.textSecondary))
            else
              ...logs.map(
                (log) => ListTile(
                  leading: Icon(
                      log.isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                      color:
                          log.isDeposit ? AppColors.income : AppColors.expense),
                  title: Text(
                      '${log.isDeposit ? l10n.deposit : l10n.withdraw} ¥${log.amount.abs().toStringAsFixed(2)}'),
                  subtitle: Text(
                      log.note?.isNotEmpty == true ? log.note! : l10n.noNote),
                  trailing: PopupMenuButton<String>(
                    tooltip: l10n.logActions,
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.pop(context, 'edit:${log.id}');
                        return;
                      }
                      if (value != 'delete') return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.deleteLogQuestion),
                          content: Text(l10n.deleteLogMessage(
                              goal.title,
                              log.linkedTransactionId == null
                                  ? ''
                                  : l10n.andBudgetExpense)),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: Text(l10n.cancel)),
                            FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: Text(l10n.delete)),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await _savingsRepository.deleteSavingsLog(log.id);
                      logs.removeWhere((item) => item.id == log.id);
                      setSheetState(() {});
                      if (mounted) _loadData();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(l10n.editLog)),
                      PopupMenuItem(
                          value: 'delete', child: Text(l10n.deleteLog)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (action != null && action.startsWith('edit:') && mounted) {
      final logId = action.substring('edit:'.length);
      final log = logs.where((item) => item.id == logId).firstOrNull;
      if (log != null) await _showEditSavingsLogSheet(goal, log);
    }
  }

  Future<T?> _showBottomSheet<T>(
      {required WidgetBuilder builder, bool isScrollControlled = false}) async {
    if (_isBottomSheetOpen || !mounted) return null;
    _isBottomSheetOpen = true;
    try {
      return await showModalBottomSheet<T>(
          context: context,
          isScrollControlled: isScrollControlled,
          builder: builder);
    } finally {
      _isBottomSheetOpen = false;
    }
  }

  Future<void> _showExportReadableBackup() async {
    final json = await _backupRepository.exportReadableJson(
        currencyCode: widget.currencyCode);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(l10n.exportReadableBackup),
                content: SizedBox(
                    width: 500,
                    height: 260,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.readableBackupWarning,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                          const SizedBox(height: 12),
                          Expanded(
                              child: SingleChildScrollView(
                                  child: SelectableText(json))),
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.close)),
                  ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: json));
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(l10n.copy))
                ]));
  }

  Future<void> _showExportEncryptedBackup() async {
    final password = await _promptPassword(confirm: true);
    if (password == null) return;
    final l10n = AppLocalizations.of(context)!;
    final json = await _backupRepository.exportEncryptedJson(
        currencyCode: widget.currencyCode, password: password);
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(l10n.exportEncryptedBackup),
              content: SizedBox(
                  width: 500,
                  height: 220,
                  child: SingleChildScrollView(child: SelectableText(json))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close)),
                ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: json));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.copy)),
              ],
            ));
  }

  Future<void> _showRestoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final password = await _promptPassword();
    if (password == null) return;
    await showDialog<void>(
        context: context,
        builder: (context) => _RestoreBackupDialog(
              title: l10n.restoreEncryptedBackup,
              hintText: l10n.pasteBackupJson,
              cancelLabel: l10n.cancel,
              restoreLabel: l10n.overwriteRestore,
              onRestore: (json) async {
                try {
                  await _backupRepository.restoreEncryptedJson(json,
                      expectedCurrencyCode: widget.currencyCode,
                      password: password);
                  if (context.mounted) Navigator.pop(context);
                  if (mounted) _loadData();
                } on BackupRepositoryException catch (error) {
                  if (mounted)
                    ScaffoldMessenger.of(this.context)
                        .showSnackBar(SnackBar(content: Text(error.message)));
                }
              },
            ));
  }

  Future<String?> _promptPassword({bool confirm = false}) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _BackupPasswordDialog(
        title:
            confirm ? l10n.exportEncryptedBackup : l10n.restoreEncryptedBackup,
        passwordLabel: l10n.backupPassword,
        confirmationLabel: l10n.confirmBackupPassword,
        cancelLabel: l10n.cancel,
        continueLabel: l10n.continueLabel,
        confirm: confirm,
      ),
    );
  }

  Future<void> _showInitialBalanceDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => _InitialBalanceDialog(
        initialBalance: _initialBalance,
        currencySymbol: CurrencyCatalog.byCode(widget.currencyCode).symbol,
      ),
    );
    if (amount == null) return;
    try {
      await _initialBalanceRepository.setInitialBalance(amount);
      await _loadData();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.initialBalanceSaveFailed)),
        );
      }
    }
  }

  Future<void> _confirmAndResetData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resetFinancialData),
        content: Text(l10n.resetFinancialDataMessage),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showExportReadableBackup();
              },
              child: Text(l10n.exportJsonBackup)),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.reset)),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper.instance.resetFinancialData();
    await widget.onCurrencyReset();
  }
}

class _InitialBalanceDialog extends StatefulWidget {
  final double initialBalance;
  final String currencySymbol;

  const _InitialBalanceDialog({
    required this.initialBalance,
    required this.currencySymbol,
  });

  @override
  State<_InitialBalanceDialog> createState() => _InitialBalanceDialogState();
}

class _InitialBalanceDialogState extends State<_InitialBalanceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || !amount.isFinite || amount < 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.initialBalanceInvalid)),
      );
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.initialBalanceTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText: l10n.initialBalanceLabel,
          prefixText: '${widget.currencySymbol} ',
          helperText: l10n.initialBalanceHint,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  final String title;
  final String passwordLabel;
  final String confirmationLabel;
  final String cancelLabel;
  final String continueLabel;
  final bool confirm;

  const _BackupPasswordDialog({
    required this.title,
    required this.passwordLabel,
    required this.confirmationLabel,
    required this.cancelLabel,
    required this.continueLabel,
    required this.confirm,
  });

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final confirmation = _confirmationController.text;
    final canContinue =
        password.length >= 8 && (!widget.confirm || password == confirmation);
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: widget.passwordLabel),
            ),
            if (widget.confirm)
              TextField(
                controller: _confirmationController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                decoration:
                    InputDecoration(labelText: widget.confirmationLabel),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelLabel)),
        FilledButton(
          onPressed: canContinue
              ? () => Navigator.pop(context, _passwordController.text)
              : null,
          child: Text(widget.continueLabel),
        ),
      ],
    );
  }
}

class _RestoreBackupDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String cancelLabel;
  final String restoreLabel;
  final Future<void> Function(String json) onRestore;

  const _RestoreBackupDialog({
    required this.title,
    required this.hintText,
    required this.cancelLabel,
    required this.restoreLabel,
    required this.onRestore,
  });

  @override
  State<_RestoreBackupDialog> createState() => _RestoreBackupDialogState();
}

class _RestoreBackupDialogState extends State<_RestoreBackupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        child: TextField(
          controller: _controller,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
              hintText: widget.hintText, border: const OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.cancelLabel)),
        ElevatedButton(
            onPressed: () => widget.onRestore(_controller.text.trim()),
            child: Text(widget.restoreLabel)),
      ],
    );
  }
}

class _TransactionSheet extends StatefulWidget {
  final DateTime date;
  final List<CategoryModel> expenseCategories;
  final TransactionModel? initialTransaction;
  final Future<void> Function(TransactionModel transaction) onSave;

  const _TransactionSheet({
    required this.date,
    required this.expenseCategories,
    this.initialTransaction,
    required this.onSave,
  });

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String _category = 'cat_food';
  String _icon = '🍔';

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    if (transaction != null) {
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _noteController.text = transaction.note ?? '';
      _selectedType = transaction.type;
      _category = transaction.categoryId;
      _icon = transaction.categoryIcon;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final categories = _selectedType == TransactionType.expense
        ? {for (final category in widget.expenseCategories) category.id: category}
        : const {
            'cat_salary': CategoryModel(
              id: 'cat_salary',
              name: '工资收入',
              icon: '💰',
              type: CategoryType.income,
              isCustom: false,
            ),
            'cat_bonus': CategoryModel(
              id: 'cat_bonus',
              name: '理财/奖金',
              icon: '📈',
              type: CategoryType.income,
              isCustom: false,
            ),
          };
    final selectedCategory = categories[_category] ??
        categories.values.cast<CategoryModel?>().firstWhere(
              (category) => category?.name == widget.initialTransaction?.categoryName,
              orElse: () => null,
            );

    final accent = _selectedType == TransactionType.expense
        ? colors.error
        : colors.tertiary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 10, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.initialTransaction == null
                            ? l10n.newTransactionTitle
                            : l10n.editTransactionTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${widget.date.year}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.receipt_long_outlined, color: accent),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.expense,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: Text(l10n.expenseType),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: Text(l10n.incomeType),
                  ),
                ],
                selected: {_selectedType},
                style: ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return colors.onPrimary;
                    return colors.onSurfaceVariant;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return accent;
                    return colors.surfaceContainerHighest.withValues(alpha: 0.45);
                  }),
                ),
                onSelectionChanged: (value) => setState(() {
                  _selectedType = value.first;
                  _category = _selectedType == TransactionType.expense
                      ? widget.expenseCategories.first.id
                      : 'cat_salary';
                  _icon = _selectedType == TransactionType.expense
                      ? widget.expenseCategories.first.icon
                      : '💰';
                }),
              ),
            ),
            const SizedBox(height: 22),
            Text(l10n.amountLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent,
              ),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '¥ ',
                prefixStyle: theme.textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: accent.withValues(alpha: 0.08),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _TransactionFieldTile(
              icon: selectedCategory?.icon ?? '🏷️',
              label: l10n.categoryLabel,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory?.id,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: categories.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(_localizedCategory(entry.value.name, l10n)),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _category = value!;
                    _icon = categories[_category]!.icon;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _TransactionFieldTile(
              icon: Icons.notes_outlined,
              label: l10n.noteLabel,
              child: TextField(
                controller: _noteController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.noNote,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.initialTransaction == null
                    ? l10n.saveToLocal
                    : l10n.saveChanges),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final amount =
                      double.tryParse(_amountController.text.trim());
                  if (amount == null || amount <= 0) return;
                  await widget.onSave(TransactionModel(
                    id: widget.initialTransaction?.id ??
                        'tx_${DateTime.now().microsecondsSinceEpoch}',
                    amount: amount,
                    type: _selectedType,
                    categoryId: selectedCategory?.id ?? _category,
                    categoryName: selectedCategory?.name ?? _category,
                    categoryIcon: _icon,
                    date: widget.date,
                    note: _noteController.text.trim(),
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizedCategory(String category, AppLocalizations l10n) {
    switch (category) {
      case '餐饮':
        return l10n.categoryFood;
      case '交通':
        return l10n.categoryTransport;
      case '购物':
        return l10n.categoryShopping;
      case '居住':
        return l10n.categoryHousing;
      case '娱乐':
        return l10n.categoryEntertainment;
      case '工资收入':
        return l10n.categorySalary;
      case '理财/奖金':
        return l10n.categoryBonus;
      default:
        return category;
    }
  }
}

class _TransactionFieldTile extends StatelessWidget {
  final Object icon;
  final String label;
  final Widget child;

  const _TransactionFieldTile({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: icon is IconData
                ? Icon(icon as IconData, color: colors.onSurfaceVariant)
                : Text(icon as String, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class SavingsGoalSheet extends StatefulWidget {
  final Future<void> Function(SavingsGoalModel goal) onSave;
  final SavingsGoalModel? initialGoal;

  const SavingsGoalSheet({super.key, this.initialGoal, required this.onSave});

  @override
  State<SavingsGoalSheet> createState() => _SavingsGoalSheetState();
}

class _SavingsGoalSheetState extends State<SavingsGoalSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  String? _titleError;
  String? _amountError;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final goal = widget.initialGoal;
    if (goal != null) {
      _titleController.text = goal.title;
      _amountController.text = goal.targetAmount.toStringAsFixed(2);
      _targetDate = goal.targetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              widget.initialGoal == null
                  ? l10n.newSavingsGoal
                  : l10n.editSavingsGoal,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_saveError != null)
            Text(_saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          TextField(
              controller: _titleController,
              decoration: InputDecoration(
                  labelText: l10n.goalNameLabel,
                  errorText: _titleError,
                  border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: l10n.targetAmountLabel,
                  prefixText: '¥ ',
                  errorText: _amountError,
                  border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          ListTile(
            title: Text(l10n.targetDateLabel),
            subtitle: Text(
                DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
                    .format(_targetDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: _targetDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035));
              if (picked != null && mounted) {
                setState(() => _targetDate = picked);
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final amount = double.tryParse(_amountController.text);
                      final title = _titleController.text.trim();
                      setState(() {
                        _titleError =
                            title.isEmpty ? l10n.goalNameRequired : null;
                        _amountError = amount == null || amount <= 0
                            ? l10n.positiveTargetAmountRequired
                            : null;
                      });
                      if (_titleError != null || _amountError != null) return;
                      final validAmount = amount!;
                      setState(() {
                        _isSaving = true;
                        _saveError = null;
                      });
                      try {
                        final initialGoal = widget.initialGoal;
                        await widget.onSave(SavingsGoalModel(
                          id: initialGoal?.id ??
                              'goal_${DateTime.now().microsecondsSinceEpoch}',
                          title: title,
                          targetAmount: validAmount,
                          targetDate: _targetDate,
                          currentAmount: initialGoal?.currentAmount ?? 0,
                          createdAt: initialGoal?.createdAt ?? DateTime.now(),
                          status:
                              initialGoal?.status ?? SavingsGoalStatus.active,
                        ));
                      } catch (error) {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                            _saveError = l10n.saveFailed;
                          });
                        }
                      }
                    },
              child: Text(_isSaving
                  ? l10n.saving
                  : widget.initialGoal == null
                      ? l10n.createSavingsGoal
                      : l10n.saveChanges),
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsDepositSheet extends StatefulWidget {
  final SavingsGoalModel goal;
  final bool isWithdraw;
  final SavingsLogModel? initialLog;
  final Future<void> Function(SavingsLogModel log, bool deductFromBudget)
      onSave;

  const SavingsDepositSheet(
      {super.key,
      required this.goal,
      required this.isWithdraw,
      this.initialLog,
      required this.onSave});

  @override
  State<SavingsDepositSheet> createState() => _SavingsDepositSheetState();
}

class _SavingsDepositSheetState extends State<SavingsDepositSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _deductFromBudget = true;
  String? _amountError;
  String? _saveError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final log = widget.initialLog;
    if (log != null) {
      _amountController.text = log.amount.abs().toStringAsFixed(2);
      _noteController.text = log.note ?? '';
      _deductFromBudget = log.deductFromBudget;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              widget.initialLog == null
                  ? (widget.isWithdraw
                      ? l10n.withdrawFromGoal(widget.goal.title)
                      : l10n.depositToGoal(widget.goal.title))
                  : l10n.editGoalLog(widget.goal.title),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: widget.isWithdraw
                      ? l10n.withdrawAmount
                      : l10n.depositAmount,
                  prefixText: '¥ ',
                  errorText: _amountError,
                  border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _noteController,
              decoration: InputDecoration(
                  labelText: l10n.noteLabel,
                  border: const OutlineInputBorder())),
          if (!widget.isWithdraw)
            CheckboxListTile(
              value: _deductFromBudget,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.countAgainstBudget),
              subtitle: Text(l10n.countAgainstBudgetHint,
                  style: TextStyle(fontSize: 12)),
              onChanged: (value) =>
                  setState(() => _deductFromBudget = value ?? true),
            ),
          if (_saveError != null) ...[
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerLeft,
                child: Text(_saveError!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12))),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      final value = double.tryParse(_amountController.text);
                      final exceedsBalance = widget.isWithdraw &&
                          value != null &&
                          value > widget.goal.currentAmount;
                      setState(() {
                        _amountError = value == null || value <= 0
                            ? l10n.positiveAmountRequired
                            : exceedsBalance
                                ? l10n.withdrawExceedsBalance(
                                    '¥${widget.goal.currentAmount.toStringAsFixed(2)}')
                                : null;
                      });
                      if (_amountError != null) return;
                      final validValue = value!;
                      setState(() => _isSaving = true);
                      try {
                        await widget.onSave(
                          SavingsLogModel(
                              id: widget.initialLog?.id ??
                                  'slog_${DateTime.now().microsecondsSinceEpoch}',
                              goalId: widget.goal.id,
                              amount:
                                  widget.isWithdraw ? -validValue : validValue,
                              note: _noteController.text.trim(),
                              createdAt: widget.initialLog?.createdAt ??
                                  DateTime.now()),
                          !widget.isWithdraw && _deductFromBudget,
                        );
                      } catch (error) {
                        if (!mounted) return;
                        setState(() {
                          _isSaving = false;
                          _saveError =
                              l10n.saveFailedWithError(error.toString());
                        });
                      }
                    },
              child: Text(_isSaving
                  ? l10n.saving
                  : widget.initialLog == null
                      ? (widget.isWithdraw
                          ? l10n.confirmWithdraw
                          : l10n.confirmDeposit)
                      : l10n.saveChanges),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  final double initialBudget;
  final Future<void> Function(double budget) onSave;

  const _BudgetSheet({required this.initialBudget, required this.onSave});

  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialBudget.toStringAsFixed(2));
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.editMonthlyBudget,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: l10n.budgetLimitLabel,
                  prefixText: '¥ ',
                  errorText: _error,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final budget = double.tryParse(_controller.text.trim());
                  if (budget == null || budget < 0) {
                    setState(() => _error = l10n.nonNegativeBudgetRequired);
                    return;
                  }
                  await widget.onSave(budget);
                },
                child: Text(l10n.saveBudget),
              ),
            ),
          ]),
    );
  }
}
