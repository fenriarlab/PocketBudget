import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

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
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardView(),
          _TransactionsView(),
          _SavingsView(),
          _BudgetAssessmentView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open Add Transaction modal
          _showAddTransactionDialog(context);
        },
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

  void _showAddTransactionDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();

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
            final dateStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

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
                  const Text('新增记账明细', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income),
                    decoration: InputDecoration(
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
                        setModalState(() {
                          selectedDate = picked;
                        });
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
                  const TextField(
                    decoration: InputDecoration(
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
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('保存到本地', style: TextStyle(color: Colors.white, fontSize: 16)),
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
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
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
              const Text('本月剩余可用预算', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              const Text('¥ 3,750.50', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.25,
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('总预算: ¥ 5,000.00', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('已支出: ¥ 1,249.50', style: TextStyle(color: AppColors.expense, fontSize: 13, fontWeight: FontWeight.bold)),
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Text('日均健康度控制', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              SizedBox(height: 8),
              Text('¥ 250.00 / 天', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income)),
              SizedBox(height: 4),
              Text('本月还剩 15 天，控制每日支出低于该数值即可达成存钱目标。', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Stats Row
        const Row(
          children: [
            Expanded(
              child: _StatCard(title: '本月总支出', amount: '¥ 1,249.50', color: AppColors.expense),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(title: '存钱总积攒', amount: '¥ 24,700.00', color: AppColors.income),
            ),
          ],
        ),
      ],
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

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('账单交易明细 (本地纯净无追踪)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        _buildTxTile('🍔 餐饮 - 午餐牛肉面', '-35.50', '2026-07-26', AppColors.expense),
        _buildTxTile('🚌 交通 - 地铁充值', '-50.00', '2026-07-25', AppColors.expense),
        _buildTxTile('💰 工资 - 7月薪资发牌', '+12,000.00', '2026-07-24', AppColors.income),
      ],
    );
  }

  Widget _buildTxTile(String title, String amount, String date, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

class _SavingsView extends StatelessWidget {
  const _SavingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('存钱计划 (目标看板)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildGoalCard('🎯 更换 MacBook M3 Pro', 15000, 6200, '2026-10-01'),
        const SizedBox(height: 12),
        _buildGoalCard('🛡️ 应急备用金 (3个月)', 30000, 18500, '2026-12-31'),
      ],
    );
  }

  Widget _buildGoalCard(String title, double target, double current, String targetDate) {
    final pct = (current / target).clamp(0.0, 1.0);
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text('预计达成日期: $targetDate', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('已存: ¥ ${current.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('目标: ¥ ${target.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAssessmentView extends StatelessWidget {
  const _BudgetAssessmentView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('月度预算设定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '本月预算上限 (¥)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('保存配置'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
