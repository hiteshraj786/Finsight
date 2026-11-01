import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/parsed_transaction.dart';
import '../../../data/models/transaction_status.dart';
import '../../../services/sms/sms_pipeline.dart';
import '../../../services/sms/popup_queue_controller.dart';
import '../../../services/sms/sms_sync_service.dart';
import '../theme/sms_theme.dart';
import '../widgets/bottom_nav.dart';
import 'empty_states.dart';
import 'import_complete_screen.dart';
import 'import_scanning_screen.dart';
import 'manual_add_sheet.dart';
import 'review_list_screen.dart';
import 'sms_access_off_screen.dart';
import 'sms_permission_screen.dart';
import 'transactions_screen.dart';

enum ShellFlowState {
  permissionRequired,
  permissionDenied,
  scanning,
  importComplete,
  mainApp,
  unreadableMessages,
}

/// SMS review and transaction list. Listening for new SMS and catching up
/// after the app was in the background is handled app-wide by
/// [SmsSyncService]; this screen only runs a full import on request.
class SmsShellScreen extends StatefulWidget {
  final TransactionRepository repository;

  /// Start a full inbox import as soon as the screen opens.
  final bool startScan;

  SmsShellScreen({
    super.key,
    TransactionRepository? repository,
    this.startScan = false,
  }) : repository = repository ?? SmsSyncService.instance.repository;

  @override
  State<SmsShellScreen> createState() => _SmsShellScreenState();
}

class _SmsShellScreenState extends State<SmsShellScreen> {
  ShellFlowState _flowState = ShellFlowState.mainApp;
  int _currentTabIndex = 0; // 0 = Review, 1 = Transactions
  PopupQueueController get _popupController => SmsSyncService.instance.popups;

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
    if (widget.startScan) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
    } else {
      _checkInitialPermission();
    }
  }

  Future<void> _checkInitialPermission() async {
    final status = await Permission.sms.status;
    if (!mounted) return;
    if (status.isPermanentlyDenied) {
      setState(() => _flowState = ShellFlowState.permissionDenied);
    } else if (!status.isGranted) {
      // Check if any transactions already exist in database
      final existing = await widget.repository.getAll();
      if (existing.isEmpty && mounted) {
        setState(() => _flowState = ShellFlowState.permissionRequired);
      }
    }
  }

  Future<void> _startScan() async {
    final status = await Permission.sms.request();
    if (!mounted) return;
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
      final sync = SmsSyncService.instance;
      final result = await sync.importFullInbox();
      // Permission was just granted: start live listening and auto-sync.
      await sync.refresh();

      if (mounted) {
        setState(() {
          _lastScanResult = result.scan;
          _lastInsertResult = result.insert;
          _scanChecked = result.scan.messagesChecked;
          _scanFound = result.scan.transactionsFound;
          _scanSkipped = result.scan.skipped;
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
    AppColors.rebuildOnThemeChange(context);
    return Theme(
      data: AppTheme.current,
      child: _buildContent(context),
    );
  }
}
