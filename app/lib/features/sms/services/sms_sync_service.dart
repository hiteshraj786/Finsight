import 'dart:async';
import 'dart:math' as math;

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/transaction_repository.dart';
import '../models/parsed_transaction.dart';
import '../models/raw_sms_message.dart';
import '../presentation/controllers/popup_queue_controller.dart';
import 'background_sms_handler.dart';
import 'incoming_sms_importer.dart';
import 'payment_popup.dart';
import 'sms_pipeline.dart';
import 'sms_reader.dart';

class FullImportResult {
  final ScanResult scan;
  final ScanInsertResult insert;
  const FullImportResult(this.scan, this.insert);
}

class SmsSyncService with WidgetsBindingObserver {
  SmsSyncService._();
  static final instance = SmsSyncService._();

  static const _maxCatchUpPopups = 3;
  final repository = TransactionRepository();
  final reader = const SmsReader();
  final popups = PopupQueueController();
  Future<void> _queue = Future<void>.value();
  int _attachedShells = 0;
  bool _listening = false;

  Future<void> attach() async {
    _attachedShells++;
    if (_attachedShells == 1) WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  void detach() {
    if (_attachedShells == 0) return;
    _attachedShells--;
    if (_attachedShells == 0) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  Future<void> refresh() async {
    await _ensureListening();
    await syncNewMessages();
  }

  bool get _started => _attachedShells > 0;

  Future<bool> get _hasPermission async {
    try {
      return await Permission.sms.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureListening() async {
    if (_listening || !await _hasPermission) return;
    try {
      Telephony.instance.listenIncomingSms(
        onNewMessage: _onIncomingSms,
        onBackgroundMessage: onBackgroundSms,
      );
      _listening = true;
    } catch (error) {
      debugPrint('Could not listen for incoming SMS: $error');
    }
  }

  void _onIncomingSms(SmsMessage message) {
    if (!_started) return;
    unawaited(_handleLiveSms(SmsReader.fromTelephony(message)));
  }

  Future<void> _handleLiveSms(RawSmsMessage raw) async {
    ParsedTransaction? stored;
    await _serialized(() async {
      stored = await IncomingSmsImporter(repository).import(raw);
      await _advanceLastChecked([raw]);
    });
    final tx = stored;
    if (tx?.id == null) return;
    await PaymentPopup.waitUntilDue(raw.date);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      popups.enqueue(tx!);
    } else {
      await PaymentPopup.show(tx!.id!, repository);
    }
  }

  Future<void> syncNewMessages() => _serialized(() async {
    if (!_started || !await _hasPermission) return;
    final since = await repository.getLastCheckedSmsTimestamp();
    final messages = await reader.fetchInboxMessages(sinceMillis: since);
    if (messages.isEmpty) return;
    final scan = await compute(_processInBackground, messages);
    final newlyInserted = <ParsedTransaction>[];
    for (final tx in scan.transactions) {
      final key = TransactionRepository.computeDedupeKey(tx);
      if (await repository.findByDedupeKey(key) != null) continue;
      await repository.insertNewFromScan([tx]);
      final stored = await repository.findByDedupeKey(key);
      if (stored != null) newlyInserted.add(stored);
    }
    await _advanceLastChecked(messages);
    if (since != null && newlyInserted.length <= _maxCatchUpPopups) {
      for (final tx in newlyInserted) {
        popups.enqueue(tx);
      }
    }
  });

  Future<FullImportResult> importFullInbox() {
    final completer = Completer<FullImportResult>();
    unawaited(
      _serialized(() async {
        try {
          final messages = await reader.fetchInboxMessages();
          final scan = await compute(_processInBackground, messages);
          final insert = await repository.insertNewFromScan(scan.transactions);
          await _advanceLastChecked(messages);
          completer.complete(FullImportResult(scan, insert));
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      }),
    );
    return completer.future;
  }

  Future<void> _advanceLastChecked(List<RawSmsMessage> messages) async {
    if (messages.isEmpty) return;
    final newest = messages
        .map((message) => message.date.millisecondsSinceEpoch)
        .reduce(math.max);
    final previous = await repository.getLastCheckedSmsTimestamp() ?? 0;
    if (newest > previous) {
      await repository.setLastCheckedSmsTimestamp(newest);
    }
  }

  Future<void> _serialized(Future<void> Function() task) {
    final next = _queue.then((_) => task()).catchError((error) {
      debugPrint('SMS sync failed: $error');
    });
    _queue = next;
    return next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started) {
      repository.notifyExternalChanges();
      unawaited(refresh());
    }
  }
}

ScanResult _processInBackground(List<RawSmsMessage> messages) =>
    SmsPipeline().processMessages(messages);
