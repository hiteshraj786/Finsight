import 'dart:ui' show DartPluginRegistrant;

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/transaction_repository.dart';
import 'incoming_sms_importer.dart';
import 'payment_popup.dart';
import 'sms_reader.dart';

@pragma('vm:entry-point')
Future<void> onBackgroundSms(SmsMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  final raw = SmsReader.fromTelephony(message);
  final db = AppDatabase();
  try {
    final repository = TransactionRepository(db: db);
    final stored = await IncomingSmsImporter(repository).import(raw);
    if (stored?.id == null) {
      debugPrint('Background SMS was not recognized as a completed transaction');
      return;
    }
    await PaymentPopup.waitUntilDue(raw.date);
    debugPrint('Showing background payment popup for transaction ${stored!.id}');
    await PaymentPopup.show(stored!.id!, repository);
  } catch (error, stackTrace) {
    debugPrint('Background SMS handling failed: $error\n$stackTrace');
  } finally {
    await db.close();
  }
}
