import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The selected display currency for the active app session.
///
/// The source amount is preserved as entered; changing this preference changes
/// how monetary values are presented across FinSight without mutating account
/// records or silently applying an unverified exchange rate.
class CurrencyService {
  CurrencyService._();

  static const String _prefKey = 'finsight_selected_currency';

  static final ValueNotifier<String> selected = ValueNotifier<String>('INR');

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && _supportedCurrencies.contains(saved)) {
      selected.value = saved;
    }
  }

  static void setCurrency(String currency) {
    final valid = _supportedCurrencies.contains(currency) ? currency : 'INR';
    selected.value = valid;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKey, valid);
    });
  }

  static String get current => selected.value;

  static String symbolFor(String currency) => switch (currency) {
    'USD' => r'$',
    'EUR' => '€',
    'IDR' => 'Rp',
    'JPY' => '¥',
    'RUB' => '₽',
    'KRW' => '₩',
    'GBP' => '£',
    _ => '₹',
  };

  static String format(double value, {int fractionDigits = 2, String? currency}) {
    final activeCurrency = currency ?? current;
    return '${symbolFor(activeCurrency)} ${value.toStringAsFixed(fractionDigits)}';
  }

  static const _supportedCurrencies = <String>{
    'INR',
    'USD',
    'EUR',
    'IDR',
    'JPY',
    'RUB',
    'KRW',
    'GBP',
  };
}
