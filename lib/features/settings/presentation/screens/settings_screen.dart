import 'package:flutter/material.dart';

import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';

/// 通用设置页面 — 仅包含低频的环境配置、安全隐私及高危操作
/// 由"我的"页面右上角齿轮按钮导航进入
class GeneralSettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String languagePreference;
  final ValueChanged<String> onLanguageChanged;
  final bool privacyDefaultHidden;
  final ValueChanged<bool> onPrivacyDefaultChanged;
  final bool biometricLockEnabled;
  final Future<bool> Function(bool enabled)? onBiometricLockChanged;
  final String currencyCode;
  final Future<void> Function()? onResetData;

  const GeneralSettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.languagePreference,
    required this.onLanguageChanged,
    required this.privacyDefaultHidden,
    required this.onPrivacyDefaultChanged,
    this.biometricLockEnabled = false,
    this.onBiometricLockChanged,
    this.currencyCode = 'CNY',
    this.onResetData,
  });

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late bool _biometricLockEnabled;

  @override
  void initState() {
    super.initState();
    _biometricLockEnabled = widget.biometricLockEnabled;
  }

  @override
  void didUpdateWidget(covariant GeneralSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.biometricLockEnabled != widget.biometricLockEnabled) {
      _biometricLockEnabled = widget.biometricLockEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.generalSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 外观与语言 ───────────────────────────────────────────
          _SectionHeader(l10n.appearanceTitle),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(l10n.appearanceTitle),
                  subtitle: Text(l10n.appearanceSubtitle),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(l10n.lightTheme)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(l10n.darkTheme)),
                    ],
                    selected: {widget.themeMode},
                    onSelectionChanged: (selection) =>
                        widget.onThemeModeChanged(selection.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.languageTitle),
              subtitle: Text(l10n.languageSubtitle),
              trailing: DropdownButton<String>(
                value: widget.languagePreference,
                underline: const SizedBox.shrink(),
                onChanged: (value) {
                  if (value != null) widget.onLanguageChanged(value);
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

          // ─── 安全与隐私 ───────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionHeader(l10n.appLockTitle),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: Text(l10n.privacyDefaultHidden),
              subtitle: Text(l10n.privacyDefaultHiddenSubtitle),
              value: widget.privacyDefaultHidden,
              onChanged: widget.onPrivacyDefaultChanged,
            ),
          ),
          if (widget.onBiometricLockChanged != null) ...[
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: Text(l10n.appLockTitle),
                subtitle: Text(l10n.appLockSubtitle),
                value: _biometricLockEnabled,
                onChanged: (enabled) async {
                  final changed =
                      await widget.onBiometricLockChanged!(enabled);
                  if (mounted) {
                    if (changed) {
                      setState(() {
                        _biometricLockEnabled = enabled;
                      });
                    } else if (enabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.appLockEnableFailed)),
                      );
                    }
                  }
                },
              ),
            ),
          ],

          // ─── 系统与本位币 ─────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionHeader(l10n.currencyTitle),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(l10n.currencyTitle),
              subtitle: Text(l10n.currencyLockedSubtitle),
              trailing: Text(
                '${CurrencyCatalog.byCode(widget.currencyCode).nameFor(Localizations.localeOf(context).languageCode)} (${widget.currencyCode})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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

          // ─── 高危操作区 ───────────────────────────────────────────
          if (widget.onResetData != null) ...[
            const SizedBox(height: 20),
            _SectionHeader(l10n.resetFinancialData,
                color: Theme.of(context).colorScheme.error),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: Text(l10n.resetFinancialData),
                subtitle: Text(l10n.resetFinancialDataSubtitle),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: widget.onResetData,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;

  const _SectionHeader(this.title, {this.color});

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: baseColor,
        ),
      ),
    );
  }
}
