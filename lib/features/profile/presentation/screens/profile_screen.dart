import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// "我的" Tab 页面 — 聚焦于本地账本的身份、资产概览与高频业务配置
class ProfileScreen extends StatefulWidget {
  // 资产数据
  final double totalIncome;
  final double totalExpense;
  final double initialBalance;
  final int transactionCount;
  final bool privacyHidden;
  final String currencyCode;

  // 初始余额操作
  final VoidCallback? onEditInitialBalance;

  // 分类数据与操作
  final List<CategoryModel> expenseCategories;
  final List<CategoryModel> incomeCategories;
  final Future<void> Function(String name, CategoryType type)? onAddCategory;
  final Future<void> Function(CategoryModel category)? onDeleteCategory;

  // 备份与恢复操作
  final VoidCallback? onExportReadableBackup;
  final VoidCallback? onExportEncryptedBackup;
  final VoidCallback? onRestoreBackup;

  // 设置参数（传递给 GeneralSettingsScreen）
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String languagePreference;
  final ValueChanged<String> onLanguageChanged;
  final bool privacyDefaultHidden;
  final ValueChanged<bool> onPrivacyDefaultChanged;
  final bool biometricLockEnabled;
  final Future<bool> Function(bool enabled)? onBiometricLockChanged;
  final Future<void> Function()? onResetData;

  const ProfileScreen({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.initialBalance,
    required this.transactionCount,
    required this.privacyHidden,
    required this.currencyCode,
    this.onEditInitialBalance,
    required this.expenseCategories,
    this.incomeCategories = const [],
    this.onAddCategory,
    this.onDeleteCategory,
    this.onExportReadableBackup,
    this.onExportEncryptedBackup,
    this.onRestoreBackup,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.languagePreference,
    required this.onLanguageChanged,
    required this.privacyDefaultHidden,
    required this.onPrivacyDefaultChanged,
    this.biometricLockEnabled = false,
    this.onBiometricLockChanged,
    this.onResetData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nickname = '';
  bool _nicknameLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nickname = prefs.getString('account_nickname') ?? '';
      _nicknameLoaded = true;
    });
  }

  Future<void> _editNickname(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _nickname);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editNickname),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: l10n.profileAccountbookLabel,
            hintText: l10n.profileAccountbookHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
    controller.dispose();
    if (result != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account_nickname', result);
      if (mounted) setState(() => _nickname = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_nicknameLoaded) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final currency = CurrencyCatalog.byCode(widget.currencyCode);
    final netAssets =
        widget.initialBalance + widget.totalIncome - widget.totalExpense;
    final displayName =
        _nickname.isEmpty ? l10n.profileAccountbookDefault : _nickname;

    // 计算记账天数（近似值：如果有交易则按总流水数估算天数）
    final trackingDays = widget.transactionCount > 0
        ? (widget.transactionCount / 1).clamp(1, 9999).toInt()
        : 0;

    return CustomScrollView(
      slivers: [
        // ─── Header 概览区 ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ProfileHeader(
            displayName: displayName,
            netAssets: netAssets,
            transactionCount: widget.transactionCount,
            trackingDays: trackingDays,
            privacyHidden: widget.privacyHidden,
            currency: currency,
            onEditNickname: () => _editNickname(context),
            onOpenSettings: () => _openSettings(context),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ─── 账本管理 ────────────────────────────────────────
              _SectionLabel(l10n.profileSection_account),
              const SizedBox(height: 8),

              // 初始余额
              if (widget.onEditInitialBalance != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(l10n.initialBalanceTitle),
                    subtitle: Text(l10n.initialBalanceSubtitle),
                    trailing: Text(
                      widget.privacyHidden
                          ? '${currency.symbol} ****'
                          : currency.format(widget.initialBalance, 'en'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: widget.onEditInitialBalance,
                  ),
                ),
              const SizedBox(height: 10),

              // 分类管理
              if (widget.onAddCategory != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(l10n.profileCategoryManagement),
                    subtitle: Text(l10n.profileCategoryManagementSubtitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.expenseCategories.length + widget.incomeCategories.length}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: colors.onSurfaceVariant),
                      ],
                    ),
                    onTap: () => _openCategoryManagement(context),
                  ),
                ),

              const SizedBox(height: 20),

              // ─── 数据安全 ────────────────────────────────────────
              _SectionLabel(l10n.profileSection_data),
              const SizedBox(height: 8),

              // 备份区块
              if (widget.onExportReadableBackup != null ||
                  widget.onExportEncryptedBackup != null ||
                  widget.onRestoreBackup != null)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup_outlined),
                        title: Text(l10n.offlineBackup),
                        subtitle: Text(l10n.offlineBackupHint),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      if (widget.onExportReadableBackup != null)
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(l10n.exportReadableBackup),
                          subtitle: Text(l10n.readableBackupWarning),
                          onTap: widget.onExportReadableBackup,
                        ),
                      if (widget.onExportEncryptedBackup != null)
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: Text(l10n.exportEncryptedBackup),
                          onTap: widget.onExportEncryptedBackup,
                        ),
                      if (widget.onRestoreBackup != null)
                        ListTile(
                          leading: const Icon(Icons.restore_outlined),
                          title: Text(l10n.restoreEncryptedBackup),
                          onTap: widget.onRestoreBackup,
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              // 通用设置入口
              Card(
                child: ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.profileGeneralSettings),
                  subtitle: Text(l10n.profileGeneralSettingsSubtitle),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant),
                  onTap: () => _openSettings(context),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GeneralSettingsScreen(
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          languagePreference: widget.languagePreference,
          onLanguageChanged: widget.onLanguageChanged,
          privacyDefaultHidden: widget.privacyDefaultHidden,
          onPrivacyDefaultChanged: widget.onPrivacyDefaultChanged,
          biometricLockEnabled: widget.biometricLockEnabled,
          onBiometricLockChanged: widget.onBiometricLockChanged,
          currencyCode: widget.currencyCode,
          onResetData: widget.onResetData,
        ),
      ),
    );
  }

  void _openCategoryManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryManagementScreen(
          expenseCategories: widget.expenseCategories,
          incomeCategories: widget.incomeCategories,
          onAdd: widget.onAddCategory!,
          onDelete: widget.onDeleteCategory,
        ),
      ),
    );
  }
}

// ─── Header 组件 ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final double netAssets;
  final int transactionCount;
  final int trackingDays;
  final bool privacyHidden;
  final CurrencyDefinition currency;
  final VoidCallback onEditNickname;
  final VoidCallback onOpenSettings;

  const _ProfileHeader({
    required this.displayName,
    required this.netAssets,
    required this.transactionCount,
    required this.trackingDays,
    required this.privacyHidden,
    required this.currency,
    required this.onEditNickname,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2544), AppColors.darkSurface]
              : [AppColors.primary.withValues(alpha: 0.08), const Color(0xFFF4F7FC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行 + 齿轮按钮
              Row(
                children: [
                  Text(
                    l10n.profileTitle,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.generalSettingsTitle,
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: onOpenSettings,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 账本头像 + 名称
              Row(
                children: [
                  // 默认头像
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.account_balance_wallet,
                        size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onEditNickname,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined,
                                size: 14,
                                color: colors.onSurfaceVariant),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.profileStatsTransactions(transactionCount),
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 净资产卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileNetAssets,
                      style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      privacyHidden
                          ? '${currency.symbol} ****'
                          : currency.format(netAssets, 'en'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: netAssets >= 0
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 分组标题 ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
