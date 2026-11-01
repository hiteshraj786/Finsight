import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/transaction_repository.dart';

/// The small "new transaction" popup drawn over whatever app the user is in
/// (e.g. GPay), a few seconds after the bank SMS arrives.
///
/// The popup runs in its own Flutter engine (see `overlayMain` in
/// main.dart), so the transaction to show is handed over through the
/// database: [pendingTransactionKey] holds its id.
class PaymentPopup {
  PaymentPopup._();

  /// How long after the SMS the popup appears, giving the payment app time
  /// to show its own success screen first.
  static const Duration delay = Duration(seconds: 5);

  static const String pendingTransactionKey = 'overlayTransactionId';
  static const String _enabledKey = 'payment_popup_enabled';
  static const String _promptShownKey = 'payment_popup_prompt_shown';

  /// Height of the popup in logical pixels; the overlay resizes itself to
  /// this once it starts.
  static const int heightDp = 236;

  static Future<bool> hasPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "Display over other apps" page. Must be called from
  /// the app's UI (it needs an activity).
  static Future<bool> requestPermission() async {
    try {
      return await FlutterOverlayWindow.requestPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// The user's on/off switch in Settings. On by default.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Whether the one-time "allow popups?" question has been asked.
  static Future<bool> takePromptTurn() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptShownKey) ?? false) return false;
    await prefs.setBool(_promptShownKey, true);
    return true;
  }

  /// Waits until [delay] after [receivedAt] (at most [delay] from now, in
  /// case the phone's clock and the SMS timestamp disagree).
  static Future<void> waitUntilDue(DateTime receivedAt) async {
    var wait = receivedAt.add(delay).difference(DateTime.now());
    if (wait > delay) wait = delay;
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  /// Shows the popup for transaction [transactionId] over other apps, if the
  /// user allowed it.
  static Future<void> show(
    int transactionId,
    TransactionRepository repository,
  ) async {
    if (!await isEnabled() || !await hasPermission()) return;
    await repository.setAppState(pendingTransactionKey, '$transactionId');
    try {
      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          height: 900, // pixels; the popup shrinks itself to [heightDp]
          width: WindowSize.matchParent,
          alignment: OverlayAlignment.topCenter,
          flag: OverlayFlag.defaultFlag,
          // Dragging would take over horizontal swipes, so the category
          // chips could not scroll.
          enableDrag: false,
          overlayTitle: 'FinSight',
          overlayContent: 'New transaction detected',
        );
      }
      // The popup engine may be reused from an earlier popup, so tell it to
      // load the new transaction. Only message it once it is running.
      for (var i = 0; i < 30; i++) {
        if (await FlutterOverlayWindow.isActive()) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (await FlutterOverlayWindow.isActive()) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await FlutterOverlayWindow.shareData({'reload': transactionId});
      }
    } catch (error) {
      debugPrint('Could not show the payment popup: $error');
    }
  }
}
