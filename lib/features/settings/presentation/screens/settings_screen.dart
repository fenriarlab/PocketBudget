import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool privacyDefaultHidden;
  final ValueChanged<bool> onPrivacyDefaultChanged;

  const SettingsScreen({super.key, required this.themeMode, required this.onThemeModeChanged, required this.privacyDefaultHidden, required this.onPrivacyDefaultChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('我的', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('管理显示偏好和本地数据', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('外观模式'),
                subtitle: Text('选择应用的显示主题'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) => onThemeModeChanged(selection.first),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('默认隐藏金额'),
            subtitle: const Text('打开应用时先隐藏所有金额，适合在公共场合使用'),
            value: privacyDefaultHidden,
            onChanged: onPrivacyDefaultChanged,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('本地存储'),
              subtitle: const Text('财务数据仅保存在本机'),
            trailing: Icon(Icons.verified_outlined, color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}