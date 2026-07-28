import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../savings/data/savings_repository.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../budget/data/budget_repository.dart';
import '../../../budget/data/models/budget_model.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  final TransactionRepository _txRepo = TransactionRepository();
  final SavingsRepository _savingsRepo = SavingsRepository();
  final BudgetRepository _budgetRepo = BudgetRepository();

  List<TransactionModel> _transactions = [];
  List<SavingsGoalModel> _goals = [];
  double _monthlyBudget = 5000.0;
  double _monthlyExpense = 0.0;
  double _monthlyIncome = 0.0;
  bool _isLoading = true;

  final String _currentPeriod = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final txs = await _txRepo.getAllTransactions();
    final goals = await _savingsRepo.getAllGoals();
    final expense = await _txRepo.getTotalExpenseByMonth(_currentPeriod);
    final income = await _txRepo.getTotalIncomeByMonth(_currentPeriod);
    final bModel = await _budgetRepo.getBudget(_currentPeriod);

    setState(() {
      _transactions = txs;
      _goals = goals;
      _monthlyExpense = expense;
      _monthlyIncome = income;
      if (bModel != null) {
        _monthlyBudget = bModel.totalBudget;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('💰 PocketBudget'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.income.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 12, color: AppColors.income),
                  SizedBox(width: 4),
                  Text(
                    '100% 离线留存',
                    style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardView(),
                _buildTransactionsView(),
                _buildSavingsView(),
                _buildBudgetAssessmentView(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('记一笔', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primaryLight),
            label: '看板',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primaryLight),
            label: '明细',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.savings, color: AppColors.primaryLight),
            label: '存钱计划',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.primaryLight),
            label: '预算评估',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: 看板 ---
  Widget _buildDashboardView() {
    final remaining = _monthlyBudget - _monthlyExpense;
    final pct = _monthlyBudget > 0 ? (_monthlyExpense / _monthlyBudget).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, daysInMonth);
    final dailyBudget = remaining > 0 ? (remaining / remainingDays) : 0.0;

    final totalSaved = _goals.fold(0.0, (sum, g) => sum + g.currentAmount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main Budget Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('本月剩余可用预算 ($_currentPeriod)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Text(
                '¥ ${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: remaining >= 0 ? AppColors.textPrimary : AppColors.expense,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: pct > 0.9 ? AppColors.expense : AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('总预算: ¥ ${_monthlyBudget.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('已支出: ¥ ${_monthlyExpense.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.expense, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daily Assessment Alert Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.income.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text('每日健康额度推荐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '¥ ${dailyBudget.toStringAsFixed(2)} / 天',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income),
              ),
              const SizedBox(height: 4),
              Text('本月还剩 $remainingDays 天，控制每日支出不超过该数值即可健康预算。', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _StatCard(title: '本月总收入', amount: '¥ ${_monthlyIncome.toStringAsFixed(2)}', color: AppColors.income),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(title: '存钱总积攒', amount: '¥ ${totalSaved.toStringAsFixed(2)}', color: AppColors.primaryLight),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 2: 明细 ---
  Widget _buildTransactionsView() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Text('暂无记账明细，点击右下角“记一笔”开始记录！', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (ctx, idx) {
        final tx = _transactions[idx];
        final isExpense = tx.type == TransactionType.expense;
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(tx.date);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isExpense ? AppColors.expense.withOpacity(0.15) : AppColors.income.withOpacity(0.15),
              child: Text(
                tx.categoryIcon.isNotEmpty ? tx.categoryIcon : (isExpense ? '💸' : '💰'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            title: Text(
              tx.categoryName.isNotEmpty ? tx.categoryName : (isExpense ? '支出' : '收入'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Text(
              tx.note != null && tx.note!.isNotEmpty ? "${tx.note} • $dateStr" : dateStr,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${isExpense ? '-' : '+'}¥${tx.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                  onPressed: () async {
                    await _txRepo.deleteTransaction(tx.id);
                    _loadAllData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TAB 3: 存钱计划 ---
  Widget _buildSavingsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('存钱计划 (目标看板)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add_task, size: 18),
              label: const Text('新建目标'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_goals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('还没有制定存钱目标，点击“新建目标”开始存钱吧！', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._goals.map((goal) {
            final pct = goal.progressPercentage / 100.0;
            final targetDateStr = DateFormat('yyyy-MM-dd').format(goal.targetDate);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 18),
                        onPressed: () async {
                          await _savingsRepo.deleteGoal(goal.id);
                          _loadAllData();
                        },
                      ),
                    ],
                  ),
                  Text('目标日期: $targetDateStr • 剩余 ${goal.remainingDays} 天', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('已存: ¥ ${goal.currentAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold)),
                      Text('目标: ¥ ${goal.targetAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showInjectDepositDialog(context, goal),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('存入一笔'),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 4: 预算评估 ---
  Widget _buildBudgetAssessmentView() {
    final budgetController = TextEditingController(text: _monthlyBudget.toStringAsFixed(0));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('月度预算上限设置 ($_currentPeriod)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '本月预算上限 (¥)',
                    prefixText: '¥ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () async {
                      final newB = double.tryParse(budgetController.text.trim()) ?? 5000.0;
                      await _budgetRepo.setBudget(_currentPeriod, newB);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('月度预算配置已保存！')),
                      );
                      _loadAllData();
                    },
                    child: const Text('保存配置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 弹窗逻辑 ---
  void _showAddTransactionDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TransactionType selectedType = TransactionType.expense;
    String selectedCategory = '餐饮';
    String categoryIcon = '🍔';
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final now = DateTime.now();
            final isToday = selectedDate.year == now.year &&
                selectedDate.month == now.month &&
                selectedDate.day == now.day;
            final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
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
                        selected: {selectedType},
                        onSelectionChanged: (val) {
                          setModalState(() {
                            selectedType = val.first;
                            if (selectedType == TransactionType.income) {
                              selectedCategory = '工资收入';
                              categoryIcon = '💰';
                            } else {
                              selectedCategory = '餐饮';
                              categoryIcon = '🍔';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: selectedType == TransactionType.expense ? AppColors.expense : AppColors.income,
                    ),
                    decoration: const InputDecoration(
                      labelText: '金额 (¥)',
                      prefixText: '¥ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '日期',
                        prefixIcon: Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        isToday ? "今天 ($dateStr)" : dateStr,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: '备注 (例如: 午餐、买书)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt <= 0) return;

                        final newTx = TransactionModel(
                          id: "tx_${DateTime.now().millisecondsSinceEpoch}",
                          amount: amt,
                          type: selectedType,
                          categoryId: selectedType == TransactionType.expense ? 'cat_food' : 'cat_salary',
                          categoryName: selectedCategory,
                          categoryIcon: categoryIcon,
                          date: selectedDate,
                          note: noteController.text.trim(),
                        );

                        await _txRepo.insertTransaction(newTx);
                        Navigator.pop(ctx);
                        _loadAllData();
                      },
                      child: const Text('保存到本地', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 90));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('新建存钱目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '目标名称 (例如: 更换笔记本电脑)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '目标金额 (¥)',
                      prefixText: '¥ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setModalState(() => targetDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '预计目标达成日期',
                        prefixIcon: Icon(Icons.event, size: 18, color: AppColors.primary),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(targetDate),
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        if (amt <= 0 || titleController.text.trim().isEmpty) return;

                        final newGoal = SavingsGoalModel(
                          id: "goal_${DateTime.now().millisecondsSinceEpoch}",
                          title: titleController.text.trim(),
                          targetAmount: amt,
                          targetDate: targetDate,
                          createdAt: DateTime.now(),
                        );

                        await _savingsRepo.insertGoal(newGoal);
                        Navigator.pop(ctx);
                        _loadAllData();
                      },
                      child: const Text('创建目标', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInjectDepositDialog(BuildContext context, SavingsGoalModel goal) {
    final depositController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text("为【${goal.title}】存入积蓄"),
          content: TextField(
            controller: depositController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '存入金额 (¥)',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(depositController.text.trim()) ?? 0.0;
                if (amt > 0) {
                  await _savingsRepo.updateGoalProgress(goal.id, amt);
                  Navigator.pop(ctx);
                  _loadAllData();
                }
              },
              child: const Text('确认存入'),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _StatCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
