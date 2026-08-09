import 'package:intl/intl.dart';

class CurrencyDefinition {
  final String code;
  final String nameZh;
  final String nameEn;
  final String symbol;
  final int decimalDigits;

  const CurrencyDefinition({
    required this.code,
    required this.nameZh,
    required this.nameEn,
    required this.symbol,
    required this.decimalDigits,
  });

  String nameFor(String language) => language == 'zh' ? nameZh : nameEn;

  String format(double amount, String language) {
    final locale = language == 'zh' ? 'zh_CN' : 'en_US';
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }
}

class CurrencyCatalog {
  static const defaults = <CurrencyDefinition>[
    CurrencyDefinition(
      code: 'CNY',
      nameZh: '人民币',
      nameEn: 'Chinese Yuan',
      symbol: '¥',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'USD',
      nameZh: '美元',
      nameEn: 'US Dollar',
      symbol: r'$',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'EUR',
      nameZh: '欧元',
      nameEn: 'Euro',
      symbol: '€',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'GBP',
      nameZh: '英镑',
      nameEn: 'British Pound',
      symbol: '£',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'JPY',
      nameZh: '日元',
      nameEn: 'Japanese Yen',
      symbol: '¥',
      decimalDigits: 0,
    ),
    CurrencyDefinition(
      code: 'KRW',
      nameZh: '韩元',
      nameEn: 'South Korean Won',
      symbol: '₩',
      decimalDigits: 0,
    ),
    CurrencyDefinition(
      code: 'HKD',
      nameZh: '港元',
      nameEn: 'Hong Kong Dollar',
      symbol: r'HK$',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'TWD',
      nameZh: '新台币',
      nameEn: 'New Taiwan Dollar',
      symbol: r'NT$',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'SGD',
      nameZh: '新加坡元',
      nameEn: 'Singapore Dollar',
      symbol: r'S$',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'CAD',
      nameZh: '加拿大元',
      nameEn: 'Canadian Dollar',
      symbol: r'CA$',
      decimalDigits: 2,
    ),
    CurrencyDefinition(
      code: 'AUD',
      nameZh: '澳大利亚元',
      nameEn: 'Australian Dollar',
      symbol: r'A$',
      decimalDigits: 2,
    ),
  ];

  static CurrencyDefinition byCode(String code) => defaults.firstWhere(
        (currency) => currency.code == code,
        orElse: () => defaults.first,
      );
}
