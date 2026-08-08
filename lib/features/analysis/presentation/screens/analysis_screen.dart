import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/models/transaction_model.dart';

class AnalysisScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool privacyHidden;
  final VoidCallback onExportBackup;
  final VoidCallback onRestoreBackup;

  const AnalysisScreen({super.key, required this.transactions, required this.privacyHidden, required this.onExportBackup, required this.onRestoreBackup});

  String _amount(double value) => privacyHidden ? '¥ ****' : '¥ ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final categories = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) categories[transaction.categoryName] = (categories[transaction.categoryName] ?? 0) + transaction.amount;
    }
    final total = categories.values.fold<double>(0, (sum, value) => sum + value);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('本月消费分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (categories.isEmpty) const Text('本月尚无消费支出数据', style: TextStyle(color: AppColors.textSecondary))
        else ...categories.entries.map((entry) {
          final ratio = total == 0 ? 0.0 : entry.value / total;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(entry.key), Text('${_amount(entry.value)} ${(ratio * 100).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textSecondary))]),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: ratio, minHeight: 6, color: AppColors.primaryLight),
          ]));
        }),
      ]))),
      const SizedBox(height: 16),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('离线数据备份', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('所有数据保存在本地，可导出 JSON 备份或恢复已有备份。', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: onExportBackup, icon: const Icon(Icons.download), label: const Text('导出 JSON'))), const SizedBox(width: 12), Expanded(child: ElevatedButton.icon(onPressed: onRestoreBackup, icon: const Icon(Icons.upload), label: const Text('恢复数据')))]),
      ]))),
    ]);
  }
}
