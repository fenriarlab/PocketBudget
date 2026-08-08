import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_colors.dart';
import 'features/dashboard/presentation/screens/home_dashboard_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _themeMode = preferences.getString('theme_mode') == 'light' ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
    if (mounted) setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketBudget 简预算',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F3),
        colorScheme: const ColorScheme.light(primary: AppColors.primary, surface: Colors.white, onSurface: AppColors.lightTextPrimary, onSurfaceVariant: AppColors.lightTextSecondary),
        fontFamily: 'Noto Sans CJK SC',
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
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFF9AA3B2))),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(color: states.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFF9AA3B2))),
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
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE4E6EB))),
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
          iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: states.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.textSecondary)),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(color: states.contains(WidgetState.selected) ? AppColors.primaryLight : AppColors.textSecondary)),
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
      ),
      home: HomeDashboardScreen(themeMode: _themeMode, onThemeModeChanged: _setThemeMode),
    );
  }
}
