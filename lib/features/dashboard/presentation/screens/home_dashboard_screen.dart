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
import '../../../plan/presentation/screens/plan_screen.dart';
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
  bool _privacyHidden = true;
  bool _privacyDefaultHidden = true;
  bool _isBottomSheetOpen = false;
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
        return PlanScreen(
          goals: _goals,
          privacyHidden: _privacyHidden,
          currentPeriod: _currentPeriod,
          monthlyBudget: _monthlyBudget,
          monthlyExpense: _monthlyExpense,
          onEditBudget: () => _showBudgetSheet(),
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
          privacyHidden: _privacyHidden,
          onExportBackup: _showExportBackup,
          onRestoreBackup: _showRestoreBackup,
        );
      case 3:
        return SettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          privacyDefaultHidden: _privacyDefaultHidden,
          onPrivacyDefaultChanged: _setPrivacyDefaultHidden,
        );
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
          dailyQuota: _monthlyBudget / DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month),
          onMonthChanged: (month) => setState(() {
            _selectedMonth = DateTime(month.year, month.month);
            _selectedDate = DateTime(month.year, month.month, 1);
          }),
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onDelete: (transaction) async {
            await _transactionRepository.deleteTransaction(transaction.id);
            _loadData();
          },
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

  Future<void> _showEditTransactionSheet(TransactionModel transaction) async {
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

  Future<void> _showBudgetSheet() async {
    await _showBottomSheet<void>(
      isScrollControlled: true,
      builder: (sheetContext) => _BudgetSheet(
        initialBudget: _monthlyBudget,
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
          await _savingsRepository.addSavingsLog(log, deductFromBudget: deductFromBudget);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
    if (mounted) _loadData();
  }

  Future<void> _showGoalHistory(SavingsGoalModel goal) async {
    final logs = await _savingsRepository.getLogsForGoal(goal.id);
    if (!mounted) return;
    await _showBottomSheet<void>(builder: (context) => ListView(padding: const EdgeInsets.all(20), children: [Text('「${goal.title}」流水明细', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12), if (logs.isEmpty) const Text('暂无记录', style: TextStyle(color: AppColors.textSecondary)) else ...logs.map((log) => ListTile(leading: Icon(log.isDeposit ? Icons.arrow_downward : Icons.arrow_upward, color: log.isDeposit ? AppColors.income : AppColors.expense), title: Text('${log.isDeposit ? '存入' : '提取'} ¥${log.amount.abs().toStringAsFixed(2)}'), subtitle: Text(log.note ?? '')))]));
  }

  Future<T?> _showBottomSheet<T>({required WidgetBuilder builder, bool isScrollControlled = false}) async {
    if (_isBottomSheetOpen || !mounted) return null;
    _isBottomSheetOpen = true;
    try {
      return await showModalBottomSheet<T>(context: context, isScrollControlled: isScrollControlled, builder: builder);
    } finally {
      _isBottomSheetOpen = false;
    }
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
  final TransactionModel? initialTransaction;
  final Future<void> Function(TransactionModel transaction) onSave;

  const _TransactionSheet({required this.date, this.initialTransaction, required this.onSave});

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
              Text(widget.initialTransaction == null ? '新增记账明细' : '编辑记账明细', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  id: widget.initialTransaction?.id ?? 'tx_${DateTime.now().microsecondsSinceEpoch}',
                  amount: amount,
                  type: _selectedType,
                  categoryId: _category,
                  categoryName: _category,
                  categoryIcon: _icon,
                  date: widget.date,
                  note: _noteController.text.trim(),
                ));
              },
              child: Text(widget.initialTransaction == null ? '保存到本地' : '保存修改'),
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
  String? _titleError;
  String? _amountError;
  bool _isSaving = false;

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
          TextField(controller: _titleController, decoration: InputDecoration(labelText: '目标名称', errorText: _titleError, border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '目标金额', prefixText: '¥ ', errorText: _amountError, border: const OutlineInputBorder())),
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
              onPressed: _isSaving
                  ? null
                  : () async {
                final amount = double.tryParse(_amountController.text);
                final title = _titleController.text.trim();
                setState(() {
                  _titleError = title.isEmpty ? '请输入目标名称' : null;
                  _amountError = amount == null || amount <= 0 ? '请输入大于 0 的目标金额' : null;
                });
                if (_titleError != null || _amountError != null) return;
                final validAmount = amount!;
                setState(() => _isSaving = true);
                await widget.onSave(SavingsGoalModel(
                  id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
                  title: title,
                  targetAmount: validAmount,
                  targetDate: _targetDate,
                  createdAt: DateTime.now(),
                ));
              },
              child: Text(_isSaving ? '保存中…' : '创建目标'),
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
  final Future<void> Function(SavingsLogModel log, bool deductFromBudget) onSave;

  const SavingsDepositSheet({super.key, required this.goal, required this.isWithdraw, required this.onSave});

  @override
  State<SavingsDepositSheet> createState() => _SavingsDepositSheetState();
}

class _SavingsDepositSheetState extends State<SavingsDepositSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _deductFromBudget = true;
  String? _amountError;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.isWithdraw ? '从「${widget.goal.title}」提取' : '向「${widget.goal.title}」存入', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: widget.isWithdraw ? '提取金额' : '存入金额', prefixText: '¥ ', errorText: _amountError, border: const OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder())),
          if (!widget.isWithdraw)
            CheckboxListTile(
              value: _deductFromBudget,
              contentPadding: EdgeInsets.zero,
              title: const Text('计入本月预算支出'),
              subtitle: const Text('开启后会生成一笔“强迫存钱”支出，减少本月可用预算', style: TextStyle(fontSize: 12)),
              onChanged: (value) => setState(() => _deductFromBudget = value ?? true),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                final value = double.tryParse(_amountController.text);
                final exceedsBalance = widget.isWithdraw && value != null && value > widget.goal.currentAmount;
                setState(() {
                  _amountError = value == null || value <= 0
                      ? '请输入大于 0 的金额'
                      : exceedsBalance
                          ? '提取金额不能超过当前余额 ¥${widget.goal.currentAmount.toStringAsFixed(2)}'
                          : null;
                });
                if (_amountError != null) return;
                final validValue = value!;
                setState(() => _isSaving = true);
                await widget.onSave(
                  SavingsLogModel(id: 'slog_${DateTime.now().microsecondsSinceEpoch}', goalId: widget.goal.id, amount: widget.isWithdraw ? -validValue : validValue, note: _noteController.text.trim(), createdAt: DateTime.now()),
                  !widget.isWithdraw && _deductFromBudget,
                );
              },
              child: Text(_isSaving ? '保存中…' : widget.isWithdraw ? '确认提取' : '确认存入'),
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
  late final TextEditingController _controller = TextEditingController(text: widget.initialBudget.toStringAsFixed(2));
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('编辑本月预算', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '预算上限', prefixText: '¥ ', errorText: _error, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final budget = double.tryParse(_controller.text.trim());
              if (budget == null || budget < 0) {
                setState(() => _error = '请输入不小于 0 的预算金额');
                return;
              }
              await widget.onSave(budget);
            },
            child: const Text('保存预算'),
          ),
        ),
      ]),
    );
  }
}
