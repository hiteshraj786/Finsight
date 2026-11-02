import 'package:intl/intl.dart';

import '../../../core/services/currency_service.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static const _locales = <String, String>{
    'INR': 'en_IN',
    'USD': 'en_US',
    'EUR': 'de_DE',
    'IDR': 'id_ID',
    'JPY': 'ja_JP',
    'RUB': 'ru_RU',
    'KRW': 'ko_KR',
    'GBP': 'en_GB',
  };

  static NumberFormat _format({required bool showDecimals, String? currency}) {
    final code = currency ?? CurrencyService.current;
    return NumberFormat.currency(
      locale: _locales[code] ?? 'en_US',
      name: code,
      symbol: CurrencyService.symbolFor(code),
      decimalDigits: showDecimals ? 2 : 0,
    );
  }

  static String formatPaise(
    int paise, {
    bool showDecimals = false,
    String? currency,
  }) => _format(showDecimals: showDecimals, currency: currency).format(paise / 100);

  static String formatRupees(
    num rupees, {
    bool showDecimals = false,
    String? currency,
  }) => _format(showDecimals: showDecimals, currency: currency).format(rupees);

  static String formatCompact(int paise, {String? currency}) {
    final rupees = paise / 100.0;
    final code = currency ?? CurrencyService.current;
    final symbol = CurrencyService.symbolFor(code);
    if (code == 'INR') {
      if (rupees >= 10000000) {
        return '$symbol${(rupees / 10000000).toStringAsFixed(1)}Cr';
      }
      if (rupees >= 100000) {
        return '$symbol${(rupees / 100000).toStringAsFixed(1)}L';
      }
      if (rupees >= 1000) {
        return '$symbol${(rupees / 1000).toStringAsFixed(1)}k';
      }
    } else {
      if (rupees >= 1000000000) {
        return '$symbol${(rupees / 1000000000).toStringAsFixed(1)}B';
      }
      if (rupees >= 1000000) {
        return '$symbol${(rupees / 1000000).toStringAsFixed(1)}M';
      }
      if (rupees >= 1000) {
        return '$symbol${(rupees / 1000).toStringAsFixed(1)}K';
      }
    }
    return formatPaise(paise, currency: currency);
  }
}
