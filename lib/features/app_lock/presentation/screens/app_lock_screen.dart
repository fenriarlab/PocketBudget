import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AppLockScreen extends StatefulWidget {
  final Future<bool> Function() onAuthenticate;

  const AppLockScreen({super.key, required this.onAuthenticate});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAuthenticating = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _hasFailed = false;
    });
    final authenticated = await widget.onAuthenticate();
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _hasFailed = !authenticated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fingerprint_rounded,
                    size: 72, color: colors.primary),
                const SizedBox(height: 24),
                Text(
                  l10n.appLockTitle,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appLockSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                if (_isAuthenticating)
                  const CircularProgressIndicator()
                else ...[
                  FilledButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(l10n.appLockUnlock),
                  ),
                  if (_hasFailed) ...[
                    const SizedBox(height: 12),
                    Text(l10n.appLockFailed,
                        style: TextStyle(color: colors.error)),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
