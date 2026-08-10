import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/currency/currency_definition.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String languagePreference;
  final ValueChanged<String> onLanguageChanged;
  final bool privacyDefaultHidden;
  final ValueChanged<bool> onPrivacyDefaultChanged;
  final String currencyCode;
  final double initialBalance;
  final VoidCallback? onEditInitialBalance;
  final Future<void> Function()? onResetData;
  final VoidCallback? onExportReadableBackup;
  final VoidCallback? onExportEncryptedBackup;
  final VoidCallback? onRestoreBackup;

  const SettingsScreen(
      {super.key,
      required this.themeMode,
      required this.onThemeModeChanged,
      required this.languagePreference,
      required this.onLanguageChanged,
      required this.privacyDefaultHidden,
      required this.onPrivacyDefaultChanged,
      this.currencyCode = 'CNY',
      this.initialBalance = 0,
      this.onEditInitialBalance,
      this.onResetData,
      this.onExportReadableBackup,
      this.onExportEncryptedBackup,
      this.onRestoreBackup});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settingsTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.settingsSubtitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text(l10n.appearanceTitle),
                subtitle: Text(l10n.appearanceSubtitle),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text(l10n.lightTheme)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text(l10n.darkTheme)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) =>
                      onThemeModeChanged(selection.first),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(l10n.currencyTitle),
            subtitle: Text(l10n.currencyLockedSubtitle),
            trailing: Text(
              '${CurrencyCatalog.byCode(currencyCode).nameFor(Localizations.localeOf(context).languageCode)} ($currencyCode)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (onEditInitialBalance != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.initialBalanceTitle),
              subtitle: Text(l10n.initialBalanceSubtitle),
              trailing: Text(
                privacyDefaultHidden
                    ? '${CurrencyCatalog.byCode(currencyCode).symbol} ****'
                    : CurrencyCatalog.byCode(currencyCode)
                        .format(initialBalance, 'en'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: onEditInitialBalance,
            ),
          ),
        ],
        if (onResetData != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(l10n.resetFinancialData),
              subtitle: Text(l10n.resetFinancialDataSubtitle),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: onResetData,
            ),
          ),
        ],
        if (onExportReadableBackup != null ||
            onExportEncryptedBackup != null ||
            onRestoreBackup != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.offlineBackup),
                  subtitle: Text(l10n.offlineBackupHint),
                ),
                if (onExportReadableBackup != null)
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.exportReadableBackup),
                    subtitle: Text(l10n.readableBackupWarning),
                    onTap: onExportReadableBackup,
                  ),
                if (onExportEncryptedBackup != null)
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Text(l10n.exportEncryptedBackup),
                    onTap: onExportEncryptedBackup,
                  ),
                if (onRestoreBackup != null)
                  ListTile(
                    leading: const Icon(Icons.restore_outlined),
                    title: Text(l10n.restoreEncryptedBackup),
                    onTap: onRestoreBackup,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: Text(l10n.privacyDefaultHidden),
            subtitle: Text(l10n.privacyDefaultHiddenSubtitle),
            value: privacyDefaultHidden,
            onChanged: onPrivacyDefaultChanged,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.localStorageTitle),
            subtitle: Text(l10n.localStorageSubtitle),
            trailing: Icon(Icons.verified_outlined,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.languageTitle),
            subtitle: Text(l10n.languageSubtitle),
            trailing: DropdownButton<String>(
              value: languagePreference,
              underline: const SizedBox.shrink(),
              onChanged: (value) {
                if (value != null) onLanguageChanged(value);
              },
              items: [
                DropdownMenuItem(
                    value: 'system', child: Text(l10n.languageSystem)),
                DropdownMenuItem(
                    value: 'zh', child: Text(l10n.languageChinese)),
                DropdownMenuItem(
                    value: 'en', child: Text(l10n.languageEnglish)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
