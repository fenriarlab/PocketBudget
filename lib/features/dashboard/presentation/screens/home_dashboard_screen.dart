import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/month_period.dart';
import '../../../analysis/presentation/screens/analysis_screen.dart';
import '../../../backup/data/backup_repository.dart';
import '../../../budget/data/budget_allocation_repository.dart';
import '../../../budget/data/budget_repository.dart';
import '../../domain/services/monthly_financial_calculator.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../savings/data/models/savings_log_model.dart';
import '../../../savings/data/savings_repository.dart';
import '../../../plan/presentation/screens/plan_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
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
          onExportBackup: _showExportBackup,
          onRestoreBackup: _showRestoreBackup,
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
          privacyDefaultHidden: _privacyDefaultHidden,
          onPrivacyDefaultChanged: _setPrivacyDefaultHidden,
        );
      default:
        return DashboardScreen(
          monthlyBudget: _monthlyBudget,
          monthlyExpense: _monthlyExpense,
          monthlyIncome: _monthlyIncome,
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

  Future<void> _showExportBackup() async {
    final json = await _backupRepository
        .exportBackupJson(currencyCode: widget.currencyCode);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(l10n.exportJsonBackup),
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
                      label: Text(l10n.copy))
                ]));
  }

  Future<void> _showRestoreBackup() async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(l10n.restoreJsonBackup),
                content: TextField(
                    controller: controller,
                    maxLines: 8,
                    decoration: InputDecoration(
                        hintText: l10n.pasteBackupJson,
                        border: OutlineInputBorder())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel)),
                  ElevatedButton(
                      onPressed: () async {
                        final success = await _backupRepository
                            .restoreBackupJson(controller.text.trim(),
                                expectedCurrencyCode: widget.currencyCode);
                        if (context.mounted) Navigator.pop(context);
                        if (success) {
                          _loadData();
                        } else if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(l10n.currencyMismatch)));
                        }
                      },
                      child: Text(l10n.overwriteRestore))
                ]));
    controller.dispose();
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
                _showExportBackup();
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

class _TransactionSheet extends StatefulWidget {
  final DateTime date;
  final TransactionModel? initialTransaction;
  final Future<void> Function(TransactionModel transaction) onSave;

  const _TransactionSheet(
      {required this.date, this.initialTransaction, required this.onSave});

  @override
  State<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<_TransactionSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _selectedType = TransactionType.expense;
  String _category = '餐饮';
  String _icon = '🍔';

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    if (transaction != null) {
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _noteController.text = transaction.note ?? '';
      _selectedType = transaction.type;
      _category = transaction.categoryName;
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
    final categories = _selectedType == TransactionType.expense
        ? const {'餐饮': '🍔', '交通': '🚌', '购物': '🛍️', '居住': '🏠', '娱乐': '🎮'}
        : const {'工资收入': '💰', '理财/奖金': '📈'};

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  widget.initialTransaction == null
                      ? l10n.newTransactionTitle
                      : l10n.editTransactionTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expenseType)),
                  ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.incomeType)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (value) => setState(() {
                  _selectedType = value.first;
                  _category =
                      _selectedType == TransactionType.expense ? '餐饮' : '工资收入';
                  _icon =
                      _selectedType == TransactionType.expense ? '🍔' : '💰';
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: l10n.amountLabel,
                prefixText: '¥ ',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(
                labelText: l10n.categoryLabel,
                border: const OutlineInputBorder()),
            items: categories.entries
                .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                        '${entry.value} ${_localizedCategory(entry.key, l10n)}')))
                .toList(),
            onChanged: (value) => setState(() {
              _category = value!;
              _icon = categories[_category]!;
            }),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: _noteController,
              decoration: InputDecoration(
                  labelText: l10n.noteLabel,
                  border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text.trim());
                if (amount == null || amount <= 0) return;
                await widget.onSave(TransactionModel(
                  id: widget.initialTransaction?.id ??
                      'tx_${DateTime.now().microsecondsSinceEpoch}',
                  amount: amount,
                  type: _selectedType,
                  categoryId: _category,
                  categoryName: _category,
                  categoryIcon: _icon,
                  date: widget.date,
                  note: _noteController.text.trim(),
                ));
              },
              child: Text(widget.initialTransaction == null
                  ? l10n.saveToLocal
                  : l10n.saveChanges),
            ),
          ),
        ],
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
