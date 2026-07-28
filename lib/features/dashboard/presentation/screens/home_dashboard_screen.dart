import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../savings/data/savings_repository.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../savings/data/models/savings_log_model.dart';
import '../../../budget/data/budget_repository.dart';
import '../../../budget/data/models/budget_model.dart';
import '../../../backup/data/backup_repository.dart';

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
  final BackupRepository _backupRepo = BackupRepository();

  List<TransactionModel> _transactions = [];
  List<SavingsGoalModel> _goals = [];
  double _monthlyBudget = 5000.0;
  double _monthlyExpense = 0.0;
  double _monthlyIncome = 0.0;
  bool _isLoading = true;

  // Calendar View State
  bool _isCalendarView = true;
  DateTime _calendarSelectedMonth = DateTime.now();
  DateTime _calendarSelectedDate = DateTime.now();

  // Privacy Shield State
  bool _isPrivacyHidden = false;

  final String _currentPeriod = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadPrivacyPreference();
    _loadAllData();
  }

  Future<void> _loadPrivacyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPrivacyHidden = prefs.getBool('is_privacy_hidden') ?? false;
    });
  }

  Future<void> _togglePrivacyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPrivacyHidden = !_isPrivacyHidden;
      prefs.setBool('is_privacy_hidden', _isPrivacyHidden);
    });
  }

  String _formatAmount(double amount, {bool isSigned = false, bool isExpense = false}) {
    if (_isPrivacyHidden) {
      return "¥ ****";
    }
    final prefix = isSigned ? (isExpense ? '-' : '+') : '';
    return "$prefix¥ ${amount.toStringAsFixed(2)}";
  }

  Future<void> _loadAllData() async {
    final txs = await _txRepo.getAllTransactions();
    final goals = await _savingsRepo.getAllGoals();
    final selectedMonthStr = DateFormat('yyyy-MM').format(_calendarSelectedMonth);
    final expense = await _txRepo.getTotalExpenseByMonth(selectedMonthStr);
    final income = await _txRepo.getTotalIncomeByMonth(selectedMonthStr);
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💰 PocketBudget'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.income.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: AppColors.income),
                    SizedBox(width: 3),
                    Text(
                      '100% 离线留存',
                      style: TextStyle(fontSize: 10, color: AppColors.income, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Privacy Shield Toggle
          IconButton(
            tooltip: _isPrivacyHidden ? '显示敏感金额' : '隐藏敏感金额',
            icon: Icon(_isPrivacyHidden ? Icons.visibility_off : Icons.visibility, color: AppColors.primaryLight),
            onPressed: _togglePrivacyPreference,
          ),
          if (_currentIndex == 1)
            IconButton(
              tooltip: _isCalendarView ? '切换为列表视图' : '切换为日历视图',
              icon: Icon(_isCalendarView ? Icons.receipt_long : Icons.calendar_month, color: AppColors.primaryLight),
              onPressed: () {
                setState(() => _isCalendarView = !_isCalendarView);
              },
            ),
        ],
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
        onPressed: () => _showAddTransactionDialog(context, defaultDate: _calendarSelectedDate),
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
            icon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primaryLight),
            label: '日历/明细',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.savings, color: AppColors.primaryLight),
            label: '存钱计划',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline, color: AppColors.textSecondary),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.primaryLight),
            label: '评估/工具',
          ),
        ],
      ),
    );
  }

  // --- TAB 1: 看板 ---
  Widget _buildDashboardView() {
    final remainingBudget = _monthlyBudget - _monthlyExpense;
    final pct = _monthlyBudget > 0 ? (_monthlyExpense / _monthlyBudget).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, daysInMonth);
    final dailyQuota = remainingBudget > 0 ? (remainingBudget / remainingDays) : 0.0;

    final totalSavings = _goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    final liquidBalance = _monthlyIncome - _monthlyExpense;
    final totalNetAssets = liquidBalance + totalSavings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Total Assets Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💎 个人总资产 (流动资金 + 存钱积蓄)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Icon(_isPrivacyHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatAmount(totalNetAssets),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('流动可用余额: ${_formatAmount(liquidBalance)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('存钱总积蓄: ${_formatAmount(totalSavings)}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main Monthly Budget Card
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
                _formatAmount(remainingBudget),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: remainingBudget >= 0 ? AppColors.textPrimary : AppColors.expense,
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
                  Text('总预算上限: ${_formatAmount(_monthlyBudget)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('已支出/转存: ${_formatAmount(_monthlyExpense)}', style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  Text('每日建议消费上限 (动态保护)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${_formatAmount(dailyQuota)} / 天",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income),
              ),
              const SizedBox(height: 4),
              Text('本月还剩 $remainingDays 天，控制每日开销在该数值内即可达成攒钱目标。', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: 明细与日历 View 融合 ---
  Widget _buildTransactionsView() {
    if (!_isCalendarView) {
      return _buildClassicListView();
    }

    final year = _calendarSelectedMonth.year;
    final month = _calendarSelectedMonth.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sunday = 0

    // Compute daily totals map for the selected month
    final Map<String, double> dailyExpenses = {};
    final Map<String, double> dailyIncomes = {};
    final Map<String, List<TransactionModel>> dailyTxMap = {};

    for (var tx in _transactions) {
      if (tx.date.year == year && tx.date.month == month) {
        final key = DateFormat('yyyy-MM-dd').format(tx.date);
        dailyTxMap.putIfAbsent(key, () => []).add(tx);
        if (tx.type == TransactionType.expense) {
          dailyExpenses[key] = (dailyExpenses[key] ?? 0.0) + tx.amount;
        } else {
          dailyIncomes[key] = (dailyIncomes[key] ?? 0.0) + tx.amount;
        }
      }
    }

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_calendarSelectedDate);
    final selectedDayTxs = dailyTxMap[selectedDateStr] ?? [];
    final selectedDayExpense = dailyExpenses[selectedDateStr] ?? 0.0;

    final monthExpenseTotal = dailyExpenses.values.fold(0.0, (a, b) => a + b);
    final monthIncomeTotal = dailyIncomes.values.fold(0.0, (a, b) => a + b);

    // 确保日预算基准区间合理 (最小 150元)，避免额度过小导致所有开销均直接爆表呈紫色
    final baselineQuota = (_monthlyBudget > 0 ? (_monthlyBudget / 30.0) : 200.0).clamp(150.0, 1000.0);
    final now = DateTime.now();
    final isNotCurrentMonth = _calendarSelectedMonth.year != now.year || _calendarSelectedMonth.month != now.month;

    Color getHeatmapColor(double exp, double inc) {
      if (exp == 0) {
        return const Color(0xFF2ECC71).withOpacity(0.18); // 🌿 0支出翡翠绿
      }
      final ratio = exp / baselineQuota;
      if (ratio <= 0.5) {
        return const Color(0xFFF1C40F).withOpacity(0.40); // 🟨 0~50% 额度：明黄色 (轻微)
      } else if (ratio <= 1.0) {
        return const Color(0xFFE67E22).withOpacity(0.55); // 🟧 50~100% 额度：暖橙色 (接近)
      } else if (ratio <= 2.0) {
        return const Color(0xFFFF4757).withOpacity(0.70); // 🟥 100~200% 额度：鲜红色 (超支)
      } else {
        return const Color(0xFF8E44AD).withOpacity(0.80); // 🍷 >200% 额度：深紫红 (大额)
      }
    }

    return Column(
      children: [
        // 1. Calendar Month Bar with Year/Month Quick Picker & Today Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppColors.darkSurface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _calendarSelectedMonth = DateTime(year, month - 1);
                    _loadAllData();
                  });
                },
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _calendarSelectedMonth,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    setState(() {
                      _calendarSelectedMonth = DateTime(picked.year, picked.month);
                      _loadAllData();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('yyyy 年 MM 月').format(_calendarSelectedMonth),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isNotCurrentMonth)
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                      onPressed: () {
                        setState(() {
                          _calendarSelectedMonth = DateTime(now.year, now.month);
                          _calendarSelectedDate = now;
                          _loadAllData();
                        });
                      },
                      icon: const Icon(Icons.today, size: 14, color: AppColors.income),
                      label: const Text('回到今天', style: TextStyle(color: AppColors.income, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _calendarSelectedMonth = DateTime(year, month + 1);
                        _loadAllData();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Month Overview Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.darkElevated,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('月支出: ${_formatAmount(monthExpenseTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.bold)),
              Text('月收入: ${_formatAmount(monthIncomeTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.bold)),
              Text('结余: ${_formatAmount(monthIncomeTotal - monthExpenseTotal)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),

        // 3. GitHub Style Heatmap Legend Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: AppColors.darkSurface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('压力图例: ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              _buildLegendDot(AppColors.income.withOpacity(0.4), '0元'),
              _buildLegendDot(const Color(0xFFF1C40F), '轻微'),
              _buildLegendDot(const Color(0xFFE67E22), '接近'),
              _buildLegendDot(const Color(0xFFE74C3C), '超支'),
              _buildLegendDot(const Color(0xFF8E44AD), '大额'),
            ],
          ),
        ),

        // 4. Weekday Headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: AppColors.darkSurface,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('日', style: TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('一', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('二', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('三', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('四', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('五', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('六', style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // 5. Calendar Heatmap Grid
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: firstWeekday + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (ctx, index) {
              if (index < firstWeekday) {
                return const SizedBox.shrink();
              }

              final dayNum = index - firstWeekday + 1;
              final thisDate = DateTime(year, month, dayNum);
              final dateKey = DateFormat('yyyy-MM-dd').format(thisDate);

              final isToday = now.year == year && now.month == month && now.day == dayNum;
              final isSelected = _calendarSelectedDate.year == year && _calendarSelectedDate.month == month && _calendarSelectedDate.day == dayNum;

              final exp = dailyExpenses[dateKey] ?? 0.0;
              final inc = dailyIncomes[dateKey] ?? 0.0;
              final heatmapBg = getHeatmapColor(exp, inc);

              return InkWell(
                onTap: () {
                  setState(() => _calendarSelectedDate = thisDate);
                },
                onDoubleTap: () {
                  setState(() => _calendarSelectedDate = thisDate);
                  _showAddTransactionDialog(context, defaultDate: thisDate);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: heatmapBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.income
                              : Colors.transparent,
                      width: isSelected || isToday ? 1.5 : 0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : (isToday ? AppColors.income : AppColors.textPrimary),
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(left: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      if (_isPrivacyHidden && (exp > 0 || inc > 0))
                        const Text('****', style: TextStyle(fontSize: 8, color: AppColors.textMuted))
                      else if (exp > 0)
                        Text(
                          "-${exp >= 1000 ? '${(exp / 1000).toStringAsFixed(1)}k' : exp.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 9, color: AppColors.expense, fontWeight: FontWeight.bold),
                        )
                      else if (inc > 0)
                        Text(
                          "+${inc >= 1000 ? '${(inc / 1000).toStringAsFixed(1)}k' : inc.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 9, color: AppColors.income, fontWeight: FontWeight.bold),
                        )
                      else if (thisDate.isBefore(now))
                        const Text('🌿', style: TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // 5. Selected Date Details Section
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "📅 ${DateFormat('MM月dd日').format(_calendarSelectedDate)} • 共 ${selectedDayTxs.length} 笔 (支出 ${_formatAmount(selectedDayExpense)})",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => _showAddTransactionDialog(context, defaultDate: _calendarSelectedDate),
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryLight),
                      label: const Text('为该日补记', style: TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: selectedDayTxs.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🌿 零支出日！该天没有消费记录~', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _showAddTransactionDialog(context, defaultDate: _calendarSelectedDate),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('补记一笔', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: selectedDayTxs.length,
                          itemBuilder: (ctx, idx) {
                            final tx = selectedDayTxs[idx];
                            final isExpense = tx.type == TransactionType.expense;
                            final timeStr = DateFormat('HH:mm').format(tx.date);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isExpense ? AppColors.expense.withOpacity(0.15) : AppColors.income.withOpacity(0.15),
                                  child: Text(
                                    tx.categoryIcon.isNotEmpty ? tx.categoryIcon : (isExpense ? '💸' : '💰'),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                title: Text(
                                  tx.categoryName.isNotEmpty ? tx.categoryName : (isExpense ? '支出' : '收入'),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  tx.note != null && tx.note!.isNotEmpty ? "${tx.note} • $timeStr" : timeStr,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatAmount(tx.amount, isSigned: true, isExpense: isExpense),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isExpense ? AppColors.expense : AppColors.income,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 18),
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
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassicListView() {
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
                  _formatAmount(tx.amount, isSigned: true, isExpense: isExpense),
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

  // --- TAB 3: 存钱计划 (多目标 + 存取流水明细) ---
  Widget _buildSavingsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🎯 存钱目标看板', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => _showAddGoalDialog(context),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('新建目标', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_goals.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('还没有制定存钱目标，点击“新建目标”开始积攒吧！', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._goals.map((goal) {
            final pct = goal.progressPercentage / 100.0;
            final isCompleted = goal.currentAmount >= goal.targetAmount;
            final targetDateStr = DateFormat('yyyy-MM-dd').format(goal.targetDate);
            final remainingDays = goal.remainingDays;
            final remainingAmount = goal.remainingAmount;
            final dailyNeeded = remainingDays > 0 ? (remainingAmount / remainingDays) : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted ? AppColors.income : AppColors.divider,
                  width: isCompleted ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(goal.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.income.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('🎉 已达成', style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 18),
                        onPressed: () async {
                          await _savingsRepo.deleteGoal(goal.id);
                          _loadAllData();
                        },
                      ),
                    ],
                  ),
                  Text('目标日期: $targetDateStr • 剩余 $remainingDays 天', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('已存: ${_formatAmount(goal.currentAmount)}', style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('目标: ${_formatAmount(goal.targetAmount)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.white24,
                      color: isCompleted ? AppColors.income : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Smart Saving Velocity Badge
                  if (!isCompleted && remainingDays > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.darkElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "💡 推荐速率: 每日存入 ${_formatAmount(dailyNeeded)} 即可按时达成",
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showGoalHistoryDialog(context, goal),
                        icon: const Icon(Icons.history, size: 16, color: AppColors.primaryLight),
                        label: const Text('流水明细', style: TextStyle(color: AppColors.primaryLight, fontSize: 13)),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                            onPressed: () => _showDepositModal(context, goal, isWithdraw: true),
                            child: const Text('提取', style: TextStyle(color: AppColors.expense, fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.income,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () => _showDepositModal(context, goal, isWithdraw: false),
                            icon: const Icon(Icons.add, size: 16, color: Colors.black),
                            label: const Text('存入一笔', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // --- TAB 4: 评估与工具（分类饼图 + 离线 JSON 备份恢复） ---
  Widget _buildBudgetAssessmentView() {
    final budgetController = TextEditingController(text: _monthlyBudget.toStringAsFixed(0));

    // Calculate Category Spending Distribution for Pie Chart
    final Map<String, double> catExpenses = {};
    for (var tx in _transactions) {
      if (tx.type == TransactionType.expense) {
        catExpenses[tx.categoryName] = (catExpenses[tx.categoryName] ?? 0.0) + tx.amount;
      }
    }

    final totalExpense = catExpenses.values.fold(0.0, (a, b) => a + b);
    final List<Color> palette = [
      const Color(0xFFFF7675),
      const Color(0xFF74B9FF),
      const Color(0xFFA29BFE),
      const Color(0xFFFFEAA7),
      const Color(0xFFFD79A8),
      const Color(0xFF00CEC9),
      const Color(0xFF6C5CE7),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Monthly Budget Configuration Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('月度消费预算上限设置 ($_currentPeriod)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('设置合理消费预算，配合存钱计划，系统会自动为你保护每日健康开销。', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 14),
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
        const SizedBox(height: 16),

        // 2. Category Spending Pie Chart Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 本月消费分类占比统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (catExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('本月尚无消费支出数据', style: TextStyle(color: AppColors.textSecondary))),
                  )
                else ...[
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: catExpenses.entries.toList().asMap().entries.map((entry) {
                          final idx = entry.key;
                          final catName = entry.value.key;
                          final amount = entry.value.value;
                          final pct = totalExpense > 0 ? (amount / totalExpense * 100) : 0.0;
                          final color = palette[idx % palette.length];

                          return PieChartSectionData(
                            color: color,
                            value: amount,
                            title: "${pct.toStringAsFixed(1)}%",
                            radius: 45,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Legend List
                  Column(
                    children: catExpenses.entries.toList().asMap().entries.map((entry) {
                      final idx = entry.key;
                      final catName = entry.value.key;
                      final amount = entry.value.value;
                      final pct = totalExpense > 0 ? (amount / totalExpense * 100) : 0.0;
                      final color = palette[idx % palette.length];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                Text(catName, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                              ],
                            ),
                            Text(
                              "${_formatAmount(amount)} (${pct.toStringAsFixed(1)}%)",
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Offline Data Backup & Restore Tools Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📦 数据本地离线备份与恢复', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('由于 PocketBudget 100% 离线留存，你可以随时将 SQLite 数据库全量导出为 JSON 备份文件保存。', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showExportBackupDialog(context),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('导出 JSON 备份'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => _showRestoreBackupDialog(context),
                        icon: const Icon(Icons.upload, size: 18, color: Colors.white),
                        label: const Text('恢复数据备份', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 弹窗与交互逻辑 ---
  void _showExportBackupDialog(BuildContext context) async {
    final jsonStr = await _backupRepo.exportBackupJson();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text('📦 导出 JSON 备份数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('已成功生成 100% 离线备份数据（包含所有账单、存钱计划与流水）。', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.darkElevated, borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  child: Text(jsonStr, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🎉 备份 JSON 数据已成功复制到剪贴板！')),
                );
              },
              icon: const Icon(Icons.copy, size: 16, color: Colors.white),
              label: const Text('复制 JSON 内容', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRestoreBackupDialog(BuildContext context) {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: const Text('📥 恢复 JSON 数据备份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请将之前导出的 JSON 备份内容粘贴到下方，恢复将覆盖当前数据。', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: jsonController,
                maxLines: 6,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '粘贴备份 JSON 代码...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () async {
                final input = jsonController.text.trim();
                if (input.isEmpty) return;

                final success = await _backupRepo.restoreBackupJson(input);
                Navigator.pop(ctx);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🎉 数据备份已成功覆盖恢复！')),
                  );
                  _loadAllData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ JSON 备份数据格式校验失败，请检查文本。')),
                  );
                }
              },
              child: const Text('确认覆盖恢复', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context, {DateTime? defaultDate}) {
    DateTime selectedDate = defaultDate ?? DateTime.now();
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
                  const Text('🎯 新建存钱目标', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '目标名称 (例如: 更换 MacBook M3)',
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

  void _showDepositModal(BuildContext context, SavingsGoalModel goal, {required bool isWithdraw}) {
    final amtController = TextEditingController();
    final noteController = TextEditingController();
    bool deductFromBudget = true;

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
                  Text(
                    isWithdraw ? "为【${goal.title}】提取备用金" : "为【${goal.title}】存入积蓄",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amtController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isWithdraw ? AppColors.expense : AppColors.income,
                    ),
                    decoration: InputDecoration(
                      labelText: isWithdraw ? '提取金额 (¥)' : '存入金额 (¥)',
                      prefixText: '¥ ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: '备注 (如: 项目奖金、发工资存入)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!isWithdraw) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('同步从当月消费预算中扣除 (强迫储蓄)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      value: deductFromBudget,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setModalState(() => deductFromBudget = val ?? true);
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWithdraw ? AppColors.expense : AppColors.income,
                      ),
                      onPressed: () async {
                        final val = double.tryParse(amtController.text.trim()) ?? 0.0;
                        if (val <= 0) return;

                        final finalAmount = isWithdraw ? -val : val;

                        final log = SavingsLogModel(
                          id: "slog_${DateTime.now().millisecondsSinceEpoch}",
                          goalId: goal.id,
                          amount: finalAmount,
                          note: noteController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        await _savingsRepo.addSavingsLog(log, deductFromBudget: !isWithdraw && deductFromBudget);
                        Navigator.pop(ctx);
                        _loadAllData();
                      },
                      child: Text(
                        isWithdraw ? '确认提取' : '确认存入',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
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

  void _showGoalHistoryDialog(BuildContext context, SavingsGoalModel goal) async {
    final logs = await _savingsRepo.getLogsForGoal(goal.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📜 【${goal.title}】存取明细历史', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('暂无存取记录', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isDeposit = log.isDeposit;
                          final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isDeposit ? AppColors.income : AppColors.expense,
                            ),
                            title: Text(
                              isDeposit ? "存入 ¥${log.amount.toStringAsFixed(2)}" : "提取 ¥${(-log.amount).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDeposit ? AppColors.income : AppColors.expense,
                              ),
                            ),
                            subtitle: Text(
                              log.note != null && log.note!.isNotEmpty ? "${log.note} • $dateStr" : dateStr,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
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
