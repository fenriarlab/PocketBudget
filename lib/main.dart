import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_colors.dart';
import 'core/currency/currency_definition.dart';
import 'core/database/database_helper.dart';
import 'features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'features/onboarding/presentation/screens/currency_setup_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PocketBudgetApp());
}

class PocketBudgetApp extends StatefulWidget {
  const PocketBudgetApp({super.key});

  @override
  State<PocketBudgetApp> createState() => _PocketBudgetAppState();
}

class _PocketBudgetAppState extends State<PocketBudgetApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _languagePreference = 'system';
  String? _currencyCode;
  bool _currencyLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLanguagePreference();
    _loadCurrency();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _themeMode = preferences.getString('theme_mode') == 'light'
        ? ThemeMode.light
        : ThemeMode.dark);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        'theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
    if (mounted) setState(() => _themeMode = mode);
  }

  Future<void> _loadLanguagePreference() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('user_language');
    if (!mounted) return;
    setState(() {
      _languagePreference = value == 'zh' || value == 'en' ? value! : 'system';
    });
  }

  Future<void> _setLanguagePreference(String language) async {
    final value = language == 'zh' || language == 'en' ? language : 'system';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user_language', value);
    if (mounted) setState(() => _languagePreference = value);
  }

  Future<void> _loadCurrency() async {
    final preferences = await SharedPreferences.getInstance();
    var value = preferences.getString('currency_code');
    if (value == null && await DatabaseHelper.instance.hasFinancialData()) {
      value = 'CNY';
      await preferences.setString('currency_code', value);
    }
    if (!mounted) return;
    setState(() {
      _currencyCode = value == null ? null : CurrencyCatalog.byCode(value).code;
      _currencyLoading = false;
    });
  }

  Future<void> _setCurrency(String code) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('currency_code', code);
    if (mounted) {
      setState(() => _currencyCode = CurrencyCatalog.byCode(code).code);
    }
  }

  Future<void> _resetCurrency() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('currency_code');
    if (mounted) setState(() => _currencyCode = null);
  }

  Locale? get _locale {
    switch (_languagePreference) {
      case 'zh':
        return const Locale('zh', 'CN');
      case 'en':
        return const Locale('en', 'US');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currencyLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            surface: Colors.white,
            surfaceContainerHighest: Color(0xFFEEF3FA),
            onSurface: AppColors.lightTextPrimary,
            onSurfaceVariant: AppColors.lightTextSecondary),
        fontFamily: 'Noto Sans CJK SC',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
          bodyMedium: TextStyle(color: AppColors.lightTextPrimary),
          bodySmall: TextStyle(color: AppColors.lightTextSecondary),
          titleLarge: TextStyle(color: AppColors.lightTextPrimary),
          titleMedium: TextStyle(color: AppColors.lightTextPrimary),
          titleSmall: TextStyle(color: AppColors.lightTextSecondary),
          labelLarge: TextStyle(color: AppColors.lightTextPrimary),
          labelMedium: TextStyle(color: AppColors.lightTextSecondary),
          labelSmall: TextStyle(color: AppColors.lightTextSecondary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFEAF0FF),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : const Color(0xFF9AA3B2))),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : const Color(0xFF9AA3B2))),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
          sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: const Color(0x24000000),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.darkSurface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
        ),
        fontFamily: 'Noto Sans CJK SC',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          bodySmall: TextStyle(color: AppColors.textSecondary),
          titleLarge: TextStyle(color: AppColors.textPrimary),
          titleMedium: TextStyle(color: AppColors.textPrimary),
          titleSmall: TextStyle(color: AppColors.textSecondary),
          labelLarge: TextStyle(color: AppColors.textPrimary),
          labelMedium: TextStyle(color: AppColors.textSecondary),
          labelSmall: TextStyle(color: AppColors.textSecondary),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          indicatorColor: const Color(0xFF293A62),
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryLight
                  : AppColors.textSecondary)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryLight
                  : AppColors.textSecondary)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: CircleBorder(),
          sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 1,
          shadowColor: Colors.black54,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: _currencyCode == null
          ? CurrencySetupScreen(onConfirmed: _setCurrency)
          : HomeDashboardScreen(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
              languagePreference: _languagePreference,
              onLanguageChanged: _setLanguagePreference,
              currencyCode: _currencyCode!,
              onCurrencyReset: _resetCurrency,
            ),
    );
  }
}
