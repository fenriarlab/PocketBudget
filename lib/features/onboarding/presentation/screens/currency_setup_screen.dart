import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';

class CurrencySetupScreen extends StatefulWidget {
  final String languagePreference;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function(String currencyCode, double initialBalance)
      onConfirmed;

  const CurrencySetupScreen({
    super.key,
    required this.languagePreference,
    required this.onLanguageChanged,
    required this.onConfirmed,
  });

  @override
  State<CurrencySetupScreen> createState() => _CurrencySetupScreenState();
}

class _CurrencySetupScreenState extends State<CurrencySetupScreen> {
  String _selectedCode = 'CNY';
  final TextEditingController _balanceController = TextEditingController();
  String? _balanceError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _balanceController.text.trim();
    double initialBalance = 0.0;
    if (text.isNotEmpty) {
      final parsed = double.tryParse(text);
      if (parsed == null || parsed < 0) {
        setState(() {
          _balanceError = AppLocalizations.of(context)!.initialBalanceInvalid;
        });
        return;
      }
      initialBalance = parsed;
    }

    setState(() {
      _balanceError = null;
      _isSubmitting = true;
    });

    try {
      await widget.onConfirmed(_selectedCode, initialBalance);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final language = Localizations.localeOf(context).languageCode;
    final selectedCurrency = CurrencyCatalog.byCode(_selectedCode);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // ─── Header ─────────────────────────────────────────
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingWelcome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.onboardingSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 1. 语言选择卡片 ─────────────────────────────────
                _SetupCard(
                  title: l10n.languageTitle,
                  icon: Icons.language_rounded,
                  isDark: isDark,
                  child: Row(
                    children: [
                      Expanded(
                        child: _LanguagePill(
                          label: l10n.languageSystem,
                          selected: widget.languagePreference == 'system',
                          onTap: () => widget.onLanguageChanged('system'),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LanguagePill(
                          label: l10n.languageChinese,
                          selected: widget.languagePreference == 'zh',
                          onTap: () => widget.onLanguageChanged('zh'),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LanguagePill(
                          label: l10n.languageEnglish,
                          selected: widget.languagePreference == 'en',
                          onTap: () => widget.onLanguageChanged('en'),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── 2. 货币选择卡片 ─────────────────────────────────
                _SetupCard(
                  title: l10n.currencySetupTitle,
                  icon: Icons.currency_exchange_rounded,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCode,
                        decoration: InputDecoration(
                          labelText: l10n.currencyLabel,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          for (final currency in CurrencyCatalog.defaults)
                            DropdownMenuItem(
                              value: currency.code,
                              child: Text(
                                '${currency.nameFor(language)} (${currency.code} ${currency.symbol})',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E222A)
                              : const Color(0xFFF4F7FC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.currencyPreview,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              selectedCurrency.format(1234.56, language),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.currencySetupWarning,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── 3. 初始资产设定卡片 ─────────────────────────────
                _SetupCard(
                  title: l10n.initialBalanceTitle,
                  icon: Icons.account_balance_rounded,
                  badge: l10n.optionalBadge,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.initialBalanceLabel,
                          hintText: '0.00',
                          prefixText: '${selectedCurrency.symbol} ',
                          errorText: _balanceError,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.initialBalanceSubtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ─── 确认按钮 ───────────────────────────────────────
                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.getStarted,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final bool isDark;
  final Widget child;

  const _SetupCard({
    required this.title,
    required this.icon,
    this.badge,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _LanguagePill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.14)
                : (isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F7FC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected
                  ? (isDark ? Colors.white : AppColors.primaryDark)
                  : (isDark
                      ? AppColors.textSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
