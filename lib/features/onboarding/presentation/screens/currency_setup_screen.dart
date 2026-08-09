import 'package:flutter/material.dart';

import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';

class CurrencySetupScreen extends StatefulWidget {
  final ValueChanged<String> onConfirmed;

  const CurrencySetupScreen({super.key, required this.onConfirmed});

  @override
  State<CurrencySetupScreen> createState() => _CurrencySetupScreenState();
}

class _CurrencySetupScreenState extends State<CurrencySetupScreen> {
  String _selectedCode = 'CNY';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final selected = CurrencyCatalog.byCode(_selectedCode);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 56, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text(l10n.currencySetupTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(l10n.currencySetupMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCode,
                  decoration: InputDecoration(
                    labelText: l10n.currencyLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final currency in CurrencyCatalog.defaults)
                      DropdownMenuItem(
                        value: currency.code,
                        child: Text(
                            '${currency.nameFor(language)} (${currency.code})'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedCode = value);
                  },
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    title: Text(l10n.currencyPreview),
                    subtitle: Text(selected.format(1234.56, language),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.currencySetupWarning,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => widget.onConfirmed(_selectedCode),
                  child: Text(l10n.confirmCurrency(selected.nameFor(language))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
