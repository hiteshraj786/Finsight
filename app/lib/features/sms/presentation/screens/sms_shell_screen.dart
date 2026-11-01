import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/transaction_repository.dart';
import '../../models/parsed_transaction.dart';
import '../../models/raw_sms_message.dart';
import '../../models/transaction_status.dart';
import '../../services/sms_pipeline.dart';
import '../controllers/popup_queue_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import 'empty_states.dart';
import 'import_complete_screen.dart';
import 'import_scanning_screen.dart';
import 'manual_add_sheet.dart';
import 'new_transaction_popup_sheet.dart';
import 'review_list_screen.dart';
import 'sms_access_off_screen.dart';
import 'sms_permission_screen.dart';
import 'transaction_detail_sheet.dart';
import 'transactions_screen.dart';

enum ShellFlowState {
  permissionRequired,
  permissionDenied,
  scanning,
  importComplete,
  mainApp,
  unreadableMessages,
}

class SmsShellScreen extends StatefulWidget {
  final SmsPipeline pipeline;
  final TransactionRepository repository;

  SmsShellScreen({
    super.key,
    SmsPipeline? pipeline,
    TransactionRepository? repository,
  })  : pipeline = pipeline ?? SmsPipeline(),
        repository = repository ?? TransactionRepository();

  @override
  State<SmsShellScreen> createState() => _SmsShellScreenState();
}

class _SmsShellScreenState extends State<SmsShellScreen>
    with WidgetsBindingObserver {
  ShellFlowState _flowState = ShellFlowState.mainApp;
  int _currentTabIndex = 0; // 0 = Review, 1 = Transactions
  final PopupQueueController _popupController = PopupQueueController();

  // Scan progress & results
  int _scanChecked = 0;
  int _scanFound = 0;
  int _scanSkipped = 0;
  ScanResult _lastScanResult = ScanResult.empty;
  ScanInsertResult _lastInsertResult = const ScanInsertResult(
    inserted: 0,
    alreadyExisting: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _popupController.addListener(_onPopupQueueChanged);
    _checkInitialPermission();
    _initIncomingSmsListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _popupController.removeListener(_onPopupQueueChanged);
    _popupController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMissedSmsOnResume();
    }
  }

  Future<void> _checkInitialPermission() async {
    final status = await Permission.sms.status;
    if (status.isPermanentlyDenied) {
      setState(() => _flowState = ShellFlowState.permissionDenied);
    } else if (!status.isGranted) {
      // Check if any transactions already exist in database
      final existing = await widget.repository.getAll();
      if (existing.isEmpty) {
        setState(() => _flowState = ShellFlowState.permissionRequired);
      }
    }
  }

  void _initIncomingSmsListener() {
    try {
      Telephony.instance.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          final date = message.date != null
              ? DateTime.fromMillisecondsSinceEpoch(message.date!)
              : DateTime.now();
          _handleIncomingRawSms(
            RawSmsMessage(
              sender: message.address,
              body: message.body ?? '',
              date: date,
            ),
          );
        },
        listenInBackground: false,
      );
    } catch (_) {
      // Graceful fallback for non-Android/test
    }
  }

  Future<void> _handleIncomingRawSms(RawSmsMessage raw) async {
    final filterRes = widget.pipeline.filter.evaluate(
      raw.body,
      sender: raw.sender,
    );
    if (!filterRes.isAccepted) return;

    final tx = widget.pipeline.parser.parse(
      raw,
      matchedPhrase: filterRes.matchedPhrase,
      isLowConfidence: filterRes.isLowConfidence,
    );
    if (tx == null) return;

    final insertRes = await widget.repository.insertNewFromScan([tx]);
    if (insertRes.inserted > 0) {
      await widget.repository.setLastCheckedSmsTimestamp(
        raw.date.millisecondsSinceEpoch,
      );

      final all = await widget.repository.getAll();
      final key = TransactionRepository.computeDedupeKey(tx);
      final storedTx = all.firstWhere(
        (t) => TransactionRepository.computeDedupeKey(t) == key,
        orElse: () => tx,
      );

      _popupController.enqueue(storedTx);
    }
  }

  void _onPopupQueueChanged() {
    if (!mounted) return;
    if (_popupController.isShowing && _popupController.currentPopup != null) {
      final tx = _popupController.currentPopup!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNewTransactionModal(tx);
      });
    }
  }

  void _showNewTransactionModal(ParsedTransaction tx) {
    NewTransactionPopupSheet.show(
      context,
      transaction: tx,
      onConfirm: (category) async {
        if (tx.id != null) {
          await widget.repository.updatePartyAndCategory(
            tx.id!,
            category: category,
          );
          await widget.repository.updateStatus(tx.id!, TransactionStatus.confirmed);
        }
        _popupController.markDismissed();
      },
      onIgnore: () async {
        if (tx.id != null) {
          await widget.repository.updateStatus(tx.id!, TransactionStatus.ignored);
        }
        _popupController.markDismissed();
      },
      onEdit: () {
        _popupController.markDismissed();
        TransactionDetailSheet.show(
          context,
          transaction: tx,
          repository: widget.repository,
          onSaved: () {},
        );
      },
    );
  }

  Future<void> _startScan() async {
    final status = await Permission.sms.request();
    if (status.isPermanentlyDenied) {
      setState(() => _flowState = ShellFlowState.permissionDenied);
      return;
    }
    if (!status.isGranted) {
      setState(() => _flowState = ShellFlowState.permissionDenied);
      return;
    }

    setState(() {
      _flowState = ShellFlowState.scanning;
      _scanChecked = 0;
      _scanFound = 0;
      _scanSkipped = 0;
    });

    try {
      final messages = await widget.pipeline.reader.fetchInboxMessages();
      final res = widget.pipeline.processMessages(messages);
      final insertRes = await widget.repository.insertNewFromScan(res.transactions);

      if (mounted) {
        setState(() {
          _lastScanResult = res;
          _lastInsertResult = insertRes;
          _scanChecked = res.messagesChecked;
          _scanFound = res.transactionsFound;
          _scanSkipped = res.skipped;
          _flowState = ShellFlowState.importComplete;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _flowState = ShellFlowState.mainApp);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read inbox. Please try again.')),
        );
      }
    }
  }

  Future<void> _checkMissedSmsOnResume() async {
    try {
      final lastTimestamp = await widget.repository.getLastCheckedSmsTimestamp();
      if (lastTimestamp == null) return;

      final allMessages = await widget.pipeline.reader.fetchInboxMessages();
      final newer = allMessages
          .where((m) => m.date.millisecondsSinceEpoch > lastTimestamp)
          .toList();
      if (newer.isEmpty) return;

      final List<ParsedTransaction> newTxs = [];
      int maxTimestamp = lastTimestamp;

      for (final raw in newer) {
        if (raw.date.millisecondsSinceEpoch > maxTimestamp) {
          maxTimestamp = raw.date.millisecondsSinceEpoch;
        }
        final fRes = widget.pipeline.filter.evaluate(raw.body, sender: raw.sender);
        if (fRes.isAccepted) {
          final tx = widget.pipeline.parser.parse(
            raw,
            matchedPhrase: fRes.matchedPhrase,
            isLowConfidence: fRes.isLowConfidence,
          );
          if (tx != null) newTxs.add(tx);
        }
      }

      await widget.repository.setLastCheckedSmsTimestamp(maxTimestamp);
      if (newTxs.isNotEmpty) {
        await widget.repository.insertNewFromScan(newTxs);
      }
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  void _openManualAdd({DateTime? initialDate}) {
    ManualAddSheet.show(
      context,
      repository: widget.repository,
      initialDate: initialDate,
      onSaved: () {
        if (_flowState != ShellFlowState.mainApp) {
          setState(() => _flowState = ShellFlowState.mainApp);
        }
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_flowState) {
      case ShellFlowState.permissionRequired:
        return SmsPermissionScreen(
          onAllowSms: _startScan,
          onAddManually: () => _openManualAdd(),
        );

      case ShellFlowState.permissionDenied:
        return SmsAccessOffScreen(
          onAddManually: () => _openManualAdd(),
          onRetryPermission: _startScan,
        );

      case ShellFlowState.scanning:
        return ImportScanningScreen(
          checked: _scanChecked,
          found: _scanFound,
          skipped: _scanSkipped,
        );

      case ShellFlowState.importComplete:
        final lowConfCount = _lastScanResult.transactions
            .where((t) => t.lowConfidence)
            .length;
        return ImportCompleteScreen(
          totalFound: _lastScanResult.transactionsFound,
          newCount: _lastInsertResult.inserted,
          alreadySavedCount: _lastInsertResult.alreadyExisting,
          lowConfidenceCount: lowConfCount,
          onReview: () => setState(() {
            _currentTabIndex = 0;
            _flowState = ShellFlowState.mainApp;
          }),
          onLater: () => setState(() => _flowState = ShellFlowState.mainApp),
        );

      case ShellFlowState.unreadableMessages:
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Unreadable Messages'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => setState(() => _flowState = ShellFlowState.mainApp),
            ),
          ),
          body: UnreadableMessagesView(
            messages: _lastScanResult.unreadableMessages,
            onAddManuallyWithDate: (date) {
              setState(() => _flowState = ShellFlowState.mainApp);
              _openManualAdd(initialDate: date);
            },
          ),
        );

      case ShellFlowState.mainApp:
        return StreamBuilder<List<ParsedTransaction>>(
          stream: widget.repository.watchAll(
            statusFilter: TransactionStatus.pending,
          ),
          builder: (context, snapshot) {
            final pendingCount = (snapshot.data ?? []).length;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: IndexedStack(
                index: _currentTabIndex,
                children: [
                  ReviewListScreen(
                    repository: widget.repository,
                    popupController: _popupController,
                    onScanAgain: _startScan,
                    onAddManual: () => _openManualAdd(),
                    onShowPopup: () => _popupController.markDismissed(),
                    onOpenUnreadable: () => setState(
                      () => _flowState = ShellFlowState.unreadableMessages,
                    ),
                  ),
                  TransactionsScreen(
                    repository: widget.repository,
                    onAddManual: () => _openManualAdd(),
                  ),
                ],
              ),
              bottomNavigationBar: FinSightBottomNav(
                currentIndex: _currentTabIndex,
                pendingCount: pendingCount,
                onTap: (index) => setState(() => _currentTabIndex = index),
              ),
            );
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: _buildContent(context),
    );
  }
}
