import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only notification gateway. Permission is requested only when the user
/// turns on the Phase 2 setting, never while the app starts.
class InsightNotificationService {
  static const _enabledKey = 'insight_notifications_enabled';
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static void Function(String route)? onNotificationTap;

  static Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null) onNotificationTap?.call(route);
      },
    );
  }

  static Future<bool> isEnabled() async => (await SharedPreferences.getInstance()).getBool(_enabledKey) ?? false;

  static Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await requestPermission()) return false;
    await (await SharedPreferences.getInstance()).setBool(_enabledKey, enabled);
    return true;
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    required String route,
  }) async {
    if (!await isEnabled()) return;
    const details = NotificationDetails(android: AndroidNotificationDetails(
      'finsight_insights', 'FinSight insights',
      channelDescription: 'Budget, recurring payment, and unusual transaction alerts',
      importance: Importance.high, priority: Priority.high,
    ));
    await _plugin.show(id, title, body, details, payload: route);
  }
}
