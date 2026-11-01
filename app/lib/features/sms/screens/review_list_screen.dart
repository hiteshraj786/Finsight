import 'package:flutter/material.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/parsed_transaction.dart';
import '../../../data/models/transaction_status.dart';
import '../../../services/sms/popup_queue_controller.dart';
import '../theme/sms_theme.dart';
import '../widgets/finsight_app_bar.dart';
import '../widgets/transaction_card.dart';
import 'empty_states.dart';
import 'transaction_detail_sheet.dart';

class ReviewListScreen extends StatefulWidget {
  final TransactionRepository repository;
  final PopupQueueController popupController;
  final VoidCallback onScanAgain;
  final VoidCallback onAddManual;
  final VoidCallback onShowPopup;
  final VoidCallback onOpenUnreadable;

  const ReviewListScreen({
    super.key,
    required this.repository,
    required this.popupController,
    required this.onScanAgain,
    required this.onAddManual,
    required this.onShowPopup,
    required this.onOpenUnreadable,
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  bool _hideLowConfidence = true;

  Future<void> _updateStatus(ParsedTransaction tx, TransactionStatus status) async {
    if (tx.id == null) return;
    final oldStatus = tx.status;
    await widget.repository.updateStatus(tx.id!, status);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked "${tx.party}" as ${status.name}.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            widget.repository.updateStatus(tx.id!, oldStatus);
          },
        ),
      ),
    );
  }

  Future<void> _confirmAllVisible(List<ParsedTransaction> visible) async {
    final pendingItems = visible
        .where((tx) => tx.status == TransactionStatus.pending && tx.id != null)
        .toList();
    if (pendingItems.isEmpty) return;

    final ids = pendingItems.map((e) => e.id!).toList();
    await widget.repository.confirmAllVisible(ids);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Confirmed ${ids.length} visible transaction(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FinSightAppBar(
        title: 'Review',
        actions: [
          IconButton(
            icon: Icon(Icons.sync_rounded, color: AppColors.primary),
            tooltip: 'Scan inbox',
            onPressed: widget.onScanAgain,
          ),
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
            tooltip: 'Unreadable messages',
            onPressed: widget.onOpenUnreadable,
          ),
        ],
      ),
      body: StreamBuilder<List<ParsedTransaction>>(
        stream: widget.repository.watchAll(
          statusFilter: TransactionStatus.pending,
          hideLowConfidence: _hideLowConfidence,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final visible = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sticky Header Bar: Title, subtitle & status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.credit,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${visible.length} pending · Listening while app is open',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Queue Banner (visible only when popups are queued)
              ListenableBuilder(
                listenable: widget.popupController,
                builder: (context, _) {
                  final bannerCount = widget.popupController.bannerReviewCount;
                  if (bannerCount <= 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withAlpha(64)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$bannerCount new transaction(s) to review',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onShowPopup,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Show',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Controls Row: Hide low confidence switch & Confirm all visible
              FutureBuilder<List<ParsedTransaction>>(
                future: widget.repository.getAll(),
                builder: (context, allSnapshot) {
                  final all = allSnapshot.data ?? [];
                  final pendingAll = all.where((t) => t.status == TransactionStatus.pending).toList();
                  final hiddenCount = pendingAll.where((t) => t.lowConfidence).length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _hideLowConfidence,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _hideLowConfidence = val);
                                },
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _hideLowConfidence && hiddenCount > 0
                                    ? 'Hide low confidence ($hiddenCount hidden)'
                                    : 'Hide low confidence',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (visible.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _confirmAllVisible(visible),
                              icon: const Icon(Icons.done_all_rounded, size: 16),
                              label: Text(
                                'Confirm all visible (${visible.length})',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Divider(height: 8, color: AppColors.border),
              // Scrolling transaction list
              Expanded(
                child: visible.isEmpty
                    ? EmptyTransactionsView(
                        onScanAgain: widget.onScanAgain,
                        onAddManually: widget.onAddManual,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = visible[index];
                          return TransactionCard(
                            transaction: tx,
                            showActions: true,
                            onTap: () {
                              TransactionDetailSheet.show(
                                context,
                                transaction: tx,
                                repository: widget.repository,
                                onSaved: () => setState(() {}),
                              );
                            },
                            onStatusChanged: (status) => _updateStatus(tx, status),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
