import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/transaction_repository.dart';

class PaymentPopup {
  PaymentPopup._();

  static const delay = Duration(seconds: 5);
  static const pendingTransactionKey = 'overlayTransactionId';
  static const heightDp = 236;
  static const _enabledKey = 'payment_popup_enabled';

  static Future<bool> hasPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestPermission() async {
    try {
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<void> waitUntilDue(DateTime receivedAt) async {
    var wait = receivedAt.add(delay).difference(DateTime.now());
    if (wait > delay) wait = delay;
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  static Future<void> show(
    int transactionId,
    TransactionRepository repository,
  ) async {
    if (!await isEnabled() || !await hasPermission()) return;
    await repository.setAppState(pendingTransactionKey, '$transactionId');
    try {
      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          height: 900,
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.topCenter,
          flag: OverlayFlag.defaultFlag,
          enableDrag: false,
          overlayTitle: 'FinSight',
          overlayContent: 'New transaction detected',
        );
      }
      for (var attempt = 0; attempt < 30; attempt++) {
        if (await FlutterOverlayWindow.isActive()) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (await FlutterOverlayWindow.isActive()) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await FlutterOverlayWindow.shareData({'reload': transactionId});
      }
    } catch (error) {
      debugPrint('Could not show payment popup: $error');
    }
  }
}
