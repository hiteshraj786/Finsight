import 'package:flutter/material.dart';

import 'app/finsight_app.dart';
import 'core/theme/app_theme.dart';
import 'features/overlay/payment_overlay.dart';
import 'services/auth/auth_service.dart';
import 'services/categories/category_registry.dart';
import 'services/preferences/currency_service.dart';
import 'services/preferences/language_service.dart';

export 'app/finsight_app.dart' show FinSightApp;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  await CurrencyService.initialize();
  await LanguageService.initialize();
  await AppTheme.loadSaved();
  await CategoryRegistry.instance.load();
  runApp(const FinSightApp());
}

/// Entry point of the payment popup drawn over other apps. Android starts it
/// in its own engine, so it loads only what the popup needs.
@pragma('vm:entry-point')
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.loadSaved();
  runApp(const PaymentOverlayApp());
}
