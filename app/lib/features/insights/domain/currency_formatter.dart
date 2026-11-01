import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrNoDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats paise (int) to formatted rupee string with no decimals (e.g. ₹12,450)
  static String formatPaise(int paise, {bool showDecimals = false}) {
    final rupees = paise / 100.0;
    if (showDecimals) {
      return _inrWithDecimals.format(rupees);
    }
    return _inrNoDecimals.format(rupees);
  }

  /// Formats rupees (num) to formatted rupee string (e.g. ₹42,380)
  static String formatRupees(num rupees, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrWithDecimals.format(rupees);
    }
    return _inrNoDecimals.format(rupees);
  }

  /// Compact Indian format (e.g. ₹1.5L, ₹4.2k)
  static String formatCompact(int paise) {
    final rupees = paise / 100.0;
    if (rupees >= 10000000) {
      return '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
    }
    if (rupees >= 100000) {
      return '₹${(rupees / 100000).toStringAsFixed(1)}L';
    }
    if (rupees >= 1000) {
      return '₹${(rupees / 1000).toStringAsFixed(1)}k';
    }
    return formatPaise(paise);
  }
}
