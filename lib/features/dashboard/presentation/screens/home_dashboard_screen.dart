import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../analysis/presentation/screens/analysis_screen.dart';
import '../../../backup/data/backup_repository.dart';
import '../../../budget/data/budget_repository.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../savings/data/models/savings_log_model.dart';
import '../../../savings/data/savings_repository.dart';
import '../../../savings/presentation/screens/savings_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/transaction_repository.dart';
import 'dashboard_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeDashboardScreen({super.key, required this.themeMode, required this.onThemeModeChanged});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _transactionRepository = TransactionRepository();
  final _savingsRepository = SavingsRepository();
  final _budgetRepository = BudgetRepository();
  final _backupRepository = BackupRepository();
  final _currentPeriod = DateFormat('yyyy-MM').format(DateTime.now());

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _privacyHidden = false;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<TransactionModel> _transactions = [];
  List<SavingsGoalModel> _goals = [];
  double _monthlyBudget = 5000;
  double _monthlyExpense = 0;
  double _monthlyIncome = 0;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPreference();
    _loadData();
  }

  Future<void> _loadPrivacyPreference() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) setState(() => _privacyHidden = preferences.getBool('is_privacy_hidden') ?? false);
  }

  Future<void> _togglePrivacy() async {
    final nextValue = !_privacyHidden;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('is_privacy_hidden', nextValue);
    if (mounted) setState(() => _privacyHidden = nextValue);
  }

  Future<void> _loadData() async {
    final transactions = await _transactionRepository.getAllTransactions();
    final goals = await _savingsRepository.getAllGoals();
    final expense = await _transactionRepository.getTotalExpenseByMonth(_currentPeriod);
    final income = await _transactionRepository.getTotalIncomeByMonth(_currentPeriod);
    final budget = await _budgetRepository.getBudget(_currentPeriod);
    if (!mounted) return;
    setState(() {
      _transactions = transactions;
      _goals = goals;
      _monthlyExpense = expense;
      _monthlyIncome = income;
      if (budget != null) _monthlyBudget = budget.totalBudget;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketBudget'),
        actions: [
          IconButton(
            tooltip: _privacyHidden ? '显示敏感金额' : '隐藏敏感金额',
            icon: Icon(_privacyHidden ? Icons.visibility_off : Icons.visibility),
            onPressed: _togglePrivacy,
          ),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildPage(),
        floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(onPressed: () => _showTransactionSheet(_selectedDate), tooltip: '记一笔', child: const Icon(Icons.add, size: 28))
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: '计划'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '分析'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 1:
        return SavingsScreen(
          goals: _goals,
          privacyHidden: _privacyHidden,
          onAddGoal: _showGoalSheet,
          onDelete: (goal) async {
            await _savingsRepository.deleteGoal(goal.id);
            _loadData();
          },
          onHistory: _showGoalHistory,
          onDeposit: _showDepositSheet,
        );
      case 2:
        return AnalysisScreen(
          transactions: _transactions,
          monthlyBudget: _monthlyBudget,
          currentPeriod: _currentPeriod,
          privacyHidden: _privacyHidden,
          onSaveBudget: (budget) async {
            await _budgetRepository.setBudget(_currentPeriod, budget);
            _loadData();
          },
          onExportBackup: _showExportBackup,
          onRestoreBackup: _showRestoreBackup,
        );
      case 3:
        return SettingsScreen(themeMode: widget.themeMode, onThemeModeChanged: widget.onThemeModeChanged);
      default:
        return DashboardScreen(
          monthlyBudget: _monthlyBudget,
          monthlyExpense: _monthlyExpense,
          monthlyIncome: _monthlyIncome,
          goals: _goals,
          currentPeriod: _currentPeriod,
          privacyHidden: _privacyHidden,
          transactions: _transactions,
          selectedMonth: _selectedMonth,
          selectedDate: _selectedDate,
          dailyQuota: _monthlyBudget / 30,
          onMonthChanged: (month) => setState(() {
            _selectedMonth = DateTime(month.year, month.month);
            _selectedDate = DateTime(month.year, month.month, 1);
          }),
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onDelete: (transaction) async {
            await _transactionRepository.deleteTransaction(transaction.id);
            _loadData();
          },
          onAdd: _showTransactionSheet,
        );
    }
  }

  Future<void> _showTransactionSheet(DateTime date) async {
    await showModalBottomSheet<void>(
      context: context,
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

  Future<void> _showGoalSheet() async {
    await showModalBottomSheet<void>(
      context: context,
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

  Future<void> _showDepositSheet(SavingsGoalModel goal, bool isWithdraw) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool deductFromBudget = true;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isWithdraw ? '从「${goal.title}」提取' : '向「${goal.title}」存入', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: isWithdraw ? '提取金额' : '存入金额', prefixText: '¥ ', border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: noteController, decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder())),
        if (!isWithdraw) CheckboxListTile(value: deductFromBudget, contentPadding: EdgeInsets.zero, title: const Text('同步从月度预算扣除'), onChanged: (value) => setSheetState(() => deductFromBudget = value ?? true)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async { final value = double.tryParse(amountController.text); if (value == null || value <= 0) return; final log = SavingsLogModel(id: 'slog_${DateTime.now().microsecondsSinceEpoch}', goalId: goal.id, amount: isWithdraw ? -value : value, note: noteController.text.trim(), createdAt: DateTime.now()); await _savingsRepository.addSavingsLog(log, deductFromBudget: !isWithdraw && deductFromBudget); if (sheetContext.mounted) Navigator.pop(sheetContext); }, child: Text(isWithdraw ? '确认提取' : '确认存入'))),
      ]),
    )));
    amountController.dispose();
    noteController.dispose();
    if (mounted) _loadData();
  }

  Future<void> _showGoalHistory(SavingsGoalModel goal) async {
    final logs = await _savingsRepository.getLogsForGoal(goal.id);
    if (!mounted) return;
    showModalBottomSheet<void>(context: context, builder: (context) => ListView(padding: const EdgeInsets.all(20), children: [Text('「${goal.title}」流水明细', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), if (logs.isEmpty) const Text('暂无记录', style: TextStyle(color: AppColors.textSecondary)) else ...logs.map((log) => ListTile(leading: Icon(log.isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: log.isDeposit ? AppColors.income : AppColors.expense), title: Text('${log.isDeposit ? '存入' : '提取'} ¥${log.amount.abs().toStringAsFixed(2)}'), subtitle: Text(log.note ?? '')))]));
  }

  Future<void> _showExportBackup() async {
    final json = await _backupRepository.exportBackupJson();
    if (!mounted) return;
    showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('导出 JSON 备份'), content: SizedBox(width: 500, height: 220, child: SingleChildScrollView(child: SelectableText(json))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')), ElevatedButton.icon(onPressed: () { Clipboard.setData(ClipboardData(text: json)); Navigator.pop(context); }, icon: const Icon(Icons.copy), label: const Text('复制'))]));
  }

  Future<void> _showRestoreBackup() async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('恢复 JSON 备份'), content: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: '粘贴备份 JSON', border: OutlineInputBorder())), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), ElevatedButton(onPressed: () async { final success = await _backupRepository.restoreBackupJson(controller.text.trim()); if (context.mounted) Navigator.pop(context); if (success) _loadData(); }, child: const Text('覆盖恢复'))]));
    controller.dispose();
  }
}

class _TransactionSheet extends StatefulWidget {
  final DateTime date;
  final Future<void> Function(TransactionModel transaction) onSave;

  const _TransactionSheet({required this.date, required this.onSave});

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
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedType == TransactionType.expense
        ? const {'餐饮': '🍔', '交通': '🚌', '购物': '🛍️', '居住': '🏠', '娱乐': '🎮'}
        : const {'工资收入': '💰', '理财/奖金': '📈'};

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('新增记账明细', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('支出')),
                  ButtonSegment(value: TransactionType.income, label: Text('收入')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (value) => setState(() {
                  _selectedType = value.first;
                  _category = _selectedType == TransactionType.expense ? '餐饮' : '工资收入';
                  _icon = _selectedType == TransactionType.expense ? '🍔' : '💰';
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: '金额', prefixText: '¥ ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: '类别', border: OutlineInputBorder()),
            items: categories.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text('${entry.value} ${entry.key}'))).toList(),
            onChanged: (value) => setState(() {
              _category = value!;
              _icon = categories[_category]!;
            }),
          ),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text.trim());
                if (amount == null || amount <= 0) return;
                await widget.onSave(TransactionModel(
                  id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
                  amount: amount,
                  type: _selectedType,
                  categoryId: _category,
                  categoryName: _category,
                  categoryIcon: _icon,
                  date: widget.date,
                  note: _noteController.text.trim(),
                ));
              },
              child: const Text('保存到本地'),
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsGoalSheet extends StatefulWidget {
  final Future<void> Function(SavingsGoalModel goal) onSave;

  const SavingsGoalSheet({super.key, required this.onSave});

  @override
  State<SavingsGoalSheet> createState() => _SavingsGoalSheetState();
}

class _SavingsGoalSheetState extends State<SavingsGoalSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('新建存钱目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: '目标名称', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '目标金额', prefixText: '¥ ', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('预计完成日期'),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_targetDate)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _targetDate, firstDate: DateTime.now(), lastDate: DateTime(2035));
              if (picked != null && mounted) setState(() => _targetDate = picked);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text);
                final title = _titleController.text.trim();
                if (amount == null || amount <= 0 || title.isEmpty) return;
                await widget.onSave(SavingsGoalModel(
                  id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
                  title: title,
                  targetAmount: amount,
                  targetDate: _targetDate,
                  createdAt: DateTime.now(),
                ));
              },
              child: const Text('创建目标'),
            ),
          ),
        ],
      ),
    );
  }
}
