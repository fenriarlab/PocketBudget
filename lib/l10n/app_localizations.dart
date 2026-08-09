import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'PocketBudget 简预算'**
  String get appTitle;

  /// No description provided for @offlineBadge.
  ///
  /// In zh, this message translates to:
  /// **'100% 本地留存'**
  String get offlineBadge;

  /// No description provided for @tabDashboard.
  ///
  /// In zh, this message translates to:
  /// **'看板'**
  String get tabDashboard;

  /// No description provided for @tabTransactions.
  ///
  /// In zh, this message translates to:
  /// **'明细'**
  String get tabTransactions;

  /// No description provided for @tabSavings.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄'**
  String get tabSavings;

  /// No description provided for @tabBudget.
  ///
  /// In zh, this message translates to:
  /// **'预算评估'**
  String get tabBudget;

  /// No description provided for @addTransaction.
  ///
  /// In zh, this message translates to:
  /// **'记一笔'**
  String get addTransaction;

  /// No description provided for @remainingBudget.
  ///
  /// In zh, this message translates to:
  /// **'本月剩余可用预算'**
  String get remainingBudget;

  /// No description provided for @totalBudget.
  ///
  /// In zh, this message translates to:
  /// **'总预算'**
  String get totalBudget;

  /// No description provided for @usedBudget.
  ///
  /// In zh, this message translates to:
  /// **'已支出'**
  String get usedBudget;

  /// No description provided for @dailyAssessmentTitle.
  ///
  /// In zh, this message translates to:
  /// **'日均健康度控制'**
  String get dailyAssessmentTitle;

  /// No description provided for @dailyAssessmentTip.
  ///
  /// In zh, this message translates to:
  /// **'本月还剩 15 天，控制每日支出低于该数值即可完成专项储蓄计划。'**
  String get dailyAssessmentTip;

  /// No description provided for @monthlyExpense.
  ///
  /// In zh, this message translates to:
  /// **'本月总支出'**
  String get monthlyExpense;

  /// No description provided for @savingsAccumulated.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄累计'**
  String get savingsAccumulated;

  /// No description provided for @transactionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'账单交易明细 (本地纯净无追踪)'**
  String get transactionsTitle;

  /// No description provided for @savingsGoalsTitle.
  ///
  /// In zh, this message translates to:
  /// **'专项储蓄 (目标看板)'**
  String get savingsGoalsTitle;

  /// No description provided for @budgetSettingTitle.
  ///
  /// In zh, this message translates to:
  /// **'月度预算设定'**
  String get budgetSettingTitle;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @saveToLocal.
  ///
  /// In zh, this message translates to:
  /// **'保存到本地'**
  String get saveToLocal;

  /// No description provided for @amount.
  ///
  /// In zh, this message translates to:
  /// **'金额 (¥)'**
  String get amount;

  /// No description provided for @note.
  ///
  /// In zh, this message translates to:
  /// **'备注 (例如: 午餐、买书)'**
  String get note;

  /// No description provided for @newTransactionTitle.
  ///
  /// In zh, this message translates to:
  /// **'新增记账明细'**
  String get newTransactionTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
