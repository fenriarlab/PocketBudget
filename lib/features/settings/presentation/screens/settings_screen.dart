import 'package:flutter/material.dart';

import '../../../../core/currency/currency_definition.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/data/models/category_model.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String languagePreference;
  final ValueChanged<String> onLanguageChanged;
  final bool privacyDefaultHidden;
  final ValueChanged<bool> onPrivacyDefaultChanged;
  final bool biometricLockEnabled;
  final Future<bool> Function(bool enabled)? onBiometricLockChanged;
  final String currencyCode;
  final double initialBalance;
  final VoidCallback? onEditInitialBalance;
  final Future<void> Function()? onResetData;
  final VoidCallback? onExportReadableBackup;
  final VoidCallback? onExportEncryptedBackup;
  final VoidCallback? onRestoreBackup;
  final List<CategoryModel> expenseCategories;
  final Future<void> Function(String name)? onAddExpenseCategory;
  final Future<void> Function(CategoryModel category)? onDeleteExpenseCategory;

  const SettingsScreen({
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
    this.initialBalance = 0,
    this.onEditInitialBalance,
    this.onResetData,
    this.onExportReadableBackup,
    this.onExportEncryptedBackup,
    this.onRestoreBackup,
    this.expenseCategories = const [],
    this.onAddExpenseCategory,
    this.onDeleteExpenseCategory,
  });

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
        if (onAddExpenseCategory != null) ...[
          const SizedBox(height: 12),
          _ExpenseCategorySettings(
            categories: expenseCategories,
            onAdd: onAddExpenseCategory!,
            onDelete: onDeleteExpenseCategory,
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
        if (onBiometricLockChanged != null) ...[
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: Text(l10n.appLockTitle),
              subtitle: Text(l10n.appLockSubtitle),
              value: biometricLockEnabled,
              onChanged: (enabled) async {
                final changed = await onBiometricLockChanged!(enabled);
                if (!changed && context.mounted && enabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.appLockEnableFailed)),
                  );
                }
              },
            ),
          ),
        ],
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

class _ExpenseCategorySettings extends StatefulWidget {
  final List<CategoryModel> categories;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(CategoryModel category)? onDelete;

  const _ExpenseCategorySettings({
    required this.categories,
    required this.onAdd,
    this.onDelete,
  });

  @override
  State<_ExpenseCategorySettings> createState() =>
      _ExpenseCategorySettingsState();
}

class _ExpenseCategorySettingsState extends State<_ExpenseCategorySettings> {
  Future<void> _showCategoryPanel(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Categories',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: _CategorySidePanel(
            categories: widget.categories,
            onAdd: widget.onAdd,
            onDelete: widget.onDelete,
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.category_outlined),
        title: Text(l10n.expenseCategoriesTitle),
        subtitle: Text(l10n.expenseCategoriesSubtitle),
        trailing:
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
        onTap: () => _showCategoryPanel(context),
      ),
    );
  }
}

class _CategorySidePanel extends StatelessWidget {
  final List<CategoryModel> categories;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(CategoryModel category)? onDelete;

  const _CategorySidePanel({
    required this.categories,
    required this.onAdd,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.86,
          child: Column(
            children: [
              ListTile(
                leading: IconButton(
                  tooltip: l10n.cancel,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(l10n.expenseCategoriesTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l10n.expenseCategoriesSubtitle),
                trailing: IconButton(
                  tooltip: l10n.addExpenseCategory,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showAddDialog(context),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Text(l10n.expenseCategoriesSubtitle,
                            style: TextStyle(color: colors.onSurfaceVariant)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 64,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final color =
                              _settingsCategoryColor(category.colorHex);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: _SettingsCategoryGlyph(
                                      category: category),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(category.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                                if (category.isCustom && onDelete != null)
                                  IconButton(
                                    tooltip: l10n.delete,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(Icons.close_rounded,
                                        size: 18,
                                        color: colors.onSurfaceVariant),
                                    onPressed: () async {
                                      await onDelete!(category);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10n.addExpenseCategory),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(labelText: l10n.categoryNameLabel),
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
        );
      },
    );
    await WidgetsBinding.instance.endOfFrame;
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      await onAdd(name);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _SettingsCategoryGlyph extends StatelessWidget {
  final CategoryModel category;

  const _SettingsCategoryGlyph({required this.category});

  @override
  Widget build(BuildContext context) {
    final icon = _settingsCategoryIcons[category.id];
    if (icon != null) {
      return Icon(icon,
          size: 19, color: _settingsCategoryColor(category.colorHex));
    }
    return Text(category.icon, style: const TextStyle(fontSize: 17));
  }
}

const _settingsCategoryIcons = <String, IconData>{
  'cat_food': Icons.restaurant_outlined,
  'cat_transport': Icons.directions_car_outlined,
  'cat_shopping': Icons.shopping_bag_outlined,
  'cat_daily': Icons.inventory_2_outlined,
  'cat_entertainment': Icons.sports_esports_outlined,
  'cat_housing': Icons.home_outlined,
  'cat_communication': Icons.phone_iphone_outlined,
  'cat_education': Icons.menu_book_outlined,
  'cat_medical': Icons.medical_services_outlined,
  'cat_other': Icons.category_outlined,
};

Color _settingsCategoryColor(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? const Color(0xFF8791A5) : Color(0xFF000000 | value);
}
