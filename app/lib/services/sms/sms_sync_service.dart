import 'dart:async';
import 'dart:math' as math;

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/models/parsed_transaction.dart';
import '../../data/models/raw_sms_message.dart';
import '../../data/repositories/transaction_repository.dart';
import 'background_sms_handler.dart';
import 'incoming_sms_importer.dart';
import 'payment_popup.dart';
import 'popup_queue_controller.dart';
import 'sms_pipeline.dart';
import 'sms_reader.dart';

/// Result of a full inbox import, for the "import complete" screen.
class FullImportResult {
  final ScanResult scan;
  final ScanInsertResult insert;

  const FullImportResult(this.scan, this.insert);
}

/// Keeps the local transaction list in step with the SMS inbox without the
/// user pressing "Import":
///
/// * while the app is open, new bank SMS are imported the moment they
///   arrive and shown in a confirmation popup;
/// * whenever the app is opened or brought back to the foreground, any SMS
///   received in the meantime is imported.
///
/// Both only run once the user has granted SMS permission. Parsing runs on a
/// background isolate so large inboxes never freeze the UI.
class SmsSyncService with WidgetsBindingObserver {
  SmsSyncService._();

  static final SmsSyncService instance = SmsSyncService._();

  /// At most this many SMS caught by a catch-up sync get a popup each; larger
  /// batches wait in the review list instead of flooding the screen.
  static const int _maxCatchUpPopups = 3;

  final TransactionRepository repository = TransactionRepository();
  final SmsReader _reader = const SmsReader();

  /// Queue of newly imported transactions waiting for the user to confirm.
  final PopupQueueController popups = PopupQueueController();

  /// Number of signed-in shells using the service. Navigating to a fresh
  /// shell builds the new one before disposing the old, so a plain on/off
  /// flag would be switched off by the old shell.
  int _attachedShells = 0;
  bool _listening = false;
  Future<void> _queue = Future<void>.value();

  bool get _started => _attachedShells > 0;

  /// Called by each signed-in shell when it is created. Pair with [detach].
  Future<void> attach() async {
    _attachedShells++;
    if (_attachedShells == 1) WidgetsBinding.instance.addObserver(this);
    await refresh();
  }

  /// Called by each shell when it is disposed (e.g. on sign-out).
  void detach() {
    if (_attachedShells == 0) return;
    _attachedShells--;
    if (_attachedShells == 0) WidgetsBinding.instance.removeObserver(this);
  }

  /// Starts listening if permission was just granted, then imports any SMS
  /// received since the last sync.
  Future<void> refresh() async {
    await _ensureListening();
    await syncNewMessages();
    await _backfillPaymentMethodsOnce();
  }

  static const _paymentMethodBackfillKey = 'paymentMethodBackfillV1';

  /// Transactions imported before payment-method detection existed have no
  /// method, and the SMS text is not stored. Re-read the inbox once in the
  /// background and fill the method in for those rows.
  Future<void> _backfillPaymentMethodsOnce() {
    return _serialized(() async {
      if (!await _hasPermission) return;
      if (await repository.getAppState(_paymentMethodBackfillKey) != null) {
        return;
      }
      final messages = await _reader.fetchInboxMessages();
      final scan = await compute(_processInBackground, messages);
      final updated = await repository.fillMissingPaymentMethods(
        scan.transactions,
      );
      await repository.setAppState(_paymentMethodBackfillKey, '$updated');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _started) {
      // The background handler or the payment popup may have changed the
      // data through their own connections while the app was away.
      repository.notifyExternalChanges();
      // The user may have granted permission in system settings meanwhile.
      unawaited(_ensureListening());
      unawaited(syncNewMessages());
    }
  }

  Future<bool> get _hasPermission async {
    try {
      return await Permission.sms.isGranted;
    } catch (_) {
      return false; // Not Android, or the plugin is unavailable (tests).
    }
  }

  Future<void> _ensureListening() async {
    if (_listening || !await _hasPermission) return;
    try {
      // While FinSight is on screen, SMS arrive in [_onIncomingSms]. When it
      // is not (e.g. the user is in GPay), Android starts [onBackgroundSms],
      // which shows the payment popup over the other app.
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

  /// Stores a live SMS right away, then shows its popup [PaymentPopup.delay]
  /// after the SMS: inside the app if FinSight is still on screen, otherwise
  /// over whichever app the user switched to.
  Future<void> _handleLiveSms(RawSmsMessage raw) async {
    ParsedTransaction? stored;
    await _serialized(() async {
      stored = await IncomingSmsImporter(repository).import(raw);
      await _advanceLastChecked([raw]);
    });
    final tx = stored;
    if (tx == null || tx.id == null) return;
    await PaymentPopup.waitUntilDue(raw.date);
    final onScreen =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (onScreen) {
      popups.enqueue(tx);
    } else {
      await PaymentPopup.show(tx.id!, repository);
    }
  }

  /// Imports every SMS received since the last sync. The first sync after
  /// permission is granted imports the whole inbox without popups.
  Future<void> syncNewMessages() {
    return _serialized(() async {
      if (!_started || !await _hasPermission) return;
      final since = await repository.getLastCheckedSmsTimestamp();
      final messages = await _reader.fetchInboxMessages(sinceMillis: since);
      if (messages.isEmpty) return;
      await _import(
        messages,
        popupLimit: since == null ? 0 : _maxCatchUpPopups,
      );
    });
  }

  /// Reads and imports the whole inbox. Used by the "Import / Scan again"
  /// buttons, which show a summary afterwards.
  Future<FullImportResult> importFullInbox() {
    final completer = Completer<FullImportResult>();
    unawaited(
      _serialized(() async {
        try {
          final messages = await _reader.fetchInboxMessages();
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

  Future<void> _import(
    List<RawSmsMessage> messages, {
    required int popupLimit,
  }) async {
    final scan = await compute(_processInBackground, messages);
    if (popupLimit == 0) {
      // Silent first import: one bulk insert, no per-row lookups.
      await repository.insertNewFromScan(scan.transactions);
      await _advanceLastChecked(messages);
      return;
    }
    final newlyInserted = <ParsedTransaction>[];
    for (final tx in scan.transactions) {
      final key = TransactionRepository.computeDedupeKey(tx);
      final existed = await repository.findByDedupeKey(key) != null;
      if (existed) continue;
      await repository.insertNewFromScan([tx]);
      final stored = await repository.findByDedupeKey(key);
      if (stored != null) newlyInserted.add(stored);
    }
    await _advanceLastChecked(messages);
    if (newlyInserted.length <= popupLimit) {
      newlyInserted.forEach(popups.enqueue);
    }
  }

  Future<void> _advanceLastChecked(List<RawSmsMessage> messages) async {
    if (messages.isEmpty) return;
    final newest = messages
        .map((m) => m.date.millisecondsSinceEpoch)
        .reduce(math.max);
    final previous = await repository.getLastCheckedSmsTimestamp() ?? 0;
    if (newest > previous) {
      await repository.setLastCheckedSmsTimestamp(newest);
    }
  }

  /// Runs [task] after any sync already in progress, so two syncs never
  /// import the same messages at once.
  Future<void> _serialized(Future<void> Function() task) {
    final next = _queue.then((_) => task()).catchError((Object error) {
      debugPrint('SMS sync failed: $error');
    });
    _queue = next;
    return next;
  }
}

/// Filters and parses SMS off the UI thread. Must stay a top-level function
/// so it can run in a background isolate.
ScanResult _processInBackground(List<RawSmsMessage> messages) =>
    SmsPipeline().processMessages(messages);
