import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../transactions/data/models/transaction_model.dart';

class AnalysisScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool privacyHidden;
  final String currencyCode;

  const AnalysisScreen(
      {super.key,
      required this.transactions,
      required this.privacyHidden,
      this.currencyCode = 'CNY'});

  String _amount(double value) => privacyHidden
      ? '${CurrencyCatalog.byCode(currencyCode).symbol} ****'
      : CurrencyCatalog.byCode(currencyCode).format(value, 'en');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final category = _displayCategory(
            transaction.categoryId, transaction.categoryName, l10n);
        categories[category] = (categories[category] ?? 0) + transaction.amount;
      }
    }
    final total =
        categories.values.fold<double>(0, (sum, value) => sum + value);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.monthlyCategorySpending,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (categories.isEmpty)
                      Text(l10n.noCategorySpending,
                          style:
                              const TextStyle(color: AppColors.textSecondary))
                    else
                      ...categories.entries.map((entry) {
                        final ratio = total == 0 ? 0.0 : entry.value / total;
                        return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key),
                                        Text(
                                            '${_amount(entry.value)} ${(ratio * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                                color: AppColors.textSecondary))
                                      ]),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 6,
                                      color: AppColors.primaryLight),
                                ]));
                      }),
                  ]))),
    ]);
  }

  String _displayCategory(
      String categoryId, String fallback, AppLocalizations l10n) {
    switch (categoryId) {
      case 'cat_food':
        return l10n.categoryFood;
      case 'cat_transport':
        return l10n.categoryTransport;
      case 'cat_shopping':
        return l10n.categoryShopping;
      case 'cat_housing':
        return l10n.categoryHousing;
      case 'cat_entertainment':
        return l10n.categoryEntertainment;
      case 'cat_salary':
        return l10n.categorySalary;
      case 'cat_bonus':
        return l10n.categoryBonus;
      default:
        return fallback;
    }
  }
}
