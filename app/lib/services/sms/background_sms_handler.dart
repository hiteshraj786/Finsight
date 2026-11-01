import 'dart:ui' show DartPluginRegistrant;

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import 'incoming_sms_importer.dart';
import 'payment_popup.dart';
import 'sms_reader.dart';

/// Runs in a background isolate when a bank SMS arrives while FinSight is
/// not on screen: stores the transaction, then shows the payment popup over
/// the current app five seconds after the SMS.
///
/// Must stay a top-level function so Android can start it without the app.
@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  final raw = SmsReader.fromTelephony(message);
  // This isolate has no shared connection; open one and always close it.
  final db = AppDatabase();
  try {
    final repository = TransactionRepository(db: db);
    final stored = await IncomingSmsImporter(repository).import(raw);
    final id = stored?.id;
    if (id == null) return;
    await PaymentPopup.waitUntilDue(raw.date);
    await PaymentPopup.show(id, repository);
  } catch (error) {
    debugPrint('Background SMS handling failed: $error');
  } finally {
    await db.close();
  }
}
