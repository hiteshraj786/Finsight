import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../core/utils/currency_formatter.dart';
import '../../data/models/parsed_transaction.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/transaction_status.dart';
import '../../data/models/transaction_type.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../services/categories/category_registry.dart';
import '../../services/sms/payment_popup.dart';
import '../sms/theme/sms_theme.dart';
import '../sms/widgets/category_widgets.dart';
import '../sms/widgets/masking_helpers.dart';
import '../sms/widgets/payment_method_widgets.dart';

/// Root of the separate Flutter engine that draws the payment popup over
/// other apps. Started from `overlayMain` in main.dart.
class PaymentOverlayApp extends StatelessWidget {
  const PaymentOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.current,
      home: const Material(
        color: Colors.transparent,
        child: PaymentOverlay(),
      ),
    );
  }
}

class PaymentOverlay extends StatefulWidget {
  const PaymentOverlay({super.key});

  @override
  State<PaymentOverlay> createState() => _PaymentOverlayState();
}

class _PaymentOverlayState extends State<PaymentOverlay> {
  /// Closes the popup if the user does not touch it.
  static const _autoClose = Duration(seconds: 20);

  final TransactionRepository _repository = TransactionRepository();
  StreamSubscription<dynamic>? _messages;
  Timer? _closeTimer;
  ParsedTransaction? _tx;
  String _category = 'Uncategorized';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // The engine is reused between popups; each new one sends a message.
    _messages = FlutterOverlayWindow.overlayListener.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _messages?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent,
        PaymentPopup.heightDp,
        false, // no window drag: it would swallow chip scrolling
      );
    } catch (_) {}
    await CategoryRegistry.instance.load();
    final id = int.tryParse(
      await _repository.getAppState(PaymentPopup.pendingTransactionKey) ?? '',
    );
    final tx = id == null ? null : await _repository.findById(id);
    if (!mounted) return;
    if (tx == null) {
      await _close();
      return;
    }
    setState(() {
      _tx = tx;
      _category = CategoryMeta.sanitize(tx.category);
      _saving = false;
    });
    _closeTimer?.cancel();
    _closeTimer = Timer(_autoClose, _close);
  }

  Future<void> _close() async {
    _closeTimer?.cancel();
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  Future<void> _finish(TransactionStatus status) async {
    final tx = _tx;
    if (tx?.id == null || _saving) return;
    setState(() => _saving = true);
    if (status == TransactionStatus.confirmed && _category != tx!.category) {
      await _repository.updatePartyAndCategory(tx.id!, category: _category);
    }
    await _repository.updateStatus(tx!.id!, status);
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    final tx = _tx;
    if (tx == null) return const SizedBox.shrink();
    final isCredit = tx.type == TransactionType.credit;
    final details = [
      if (tx.paymentMethod != PaymentMethod.unknown) tx.paymentMethod.label,
      if (tx.accountLast4 != null) maskAccount(tx.accountLast4),
    ].join(' · ');

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: GestureDetector(
          // Any touch keeps the popup open a little longer.
          onTapDown: (_) {
            _closeTimer?.cancel();
            _closeTimer = Timer(_autoClose, _close);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isCredit
                          ? AppColors.creditLight
                          : AppColors.primaryContainer,
                      child: Icon(
                        tx.paymentMethod.icon,
                        color: isCredit ? AppColors.credit : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatIndianRupees(tx.amountPaise)} '
                            '${isCredit ? 'received' : 'paid'}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isCredit
                                  ? AppColors.credit
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            [
                              '${isCredit ? 'from' : 'to'} ${tx.party}',
                              if (details.isNotEmpty) details,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _close,
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final category in _categoryChoices(tx))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: CategoryChip(
                            category: category,
                            showIcon: true,
                            isSelected: category == _category,
                            onTap: () => setState(() => _category = category),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _finish(TransactionStatus.ignored),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Ignore'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _close,
                      child: const Text('Later'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _finish(TransactionStatus.confirmed),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The suggested category first, then every other category.
  List<String> _categoryChoices(ParsedTransaction tx) {
    final suggested = CategoryMeta.sanitize(tx.category);
    return [
      suggested,
      for (final name in CategoryMeta.validCategories)
        if (name != suggested) name,
    ];
  }
}
