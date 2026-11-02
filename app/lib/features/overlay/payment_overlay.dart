import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../../features/sms/data/transaction_repository.dart';
import '../../features/sms/models/parsed_transaction.dart';
import '../../features/sms/models/transaction_status.dart';
import '../../features/sms/services/payment_popup.dart';
import '../../features/sms/presentation/theme/app_theme.dart';
import '../../features/sms/presentation/widgets/amount_text.dart';
import '../../features/sms/presentation/widgets/category_widgets.dart';
import '../../services/categories/category_registry.dart';

class PaymentOverlayApp extends StatelessWidget {
  const PaymentOverlayApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Material(
          color: Colors.transparent,
          child: PaymentOverlay(),
        ),
      );
}

class PaymentOverlay extends StatefulWidget {
  const PaymentOverlay({super.key});

  @override
  State<PaymentOverlay> createState() => _PaymentOverlayState();
}

class _PaymentOverlayState extends State<PaymentOverlay> {
  final _repository = TransactionRepository();
  StreamSubscription<dynamic>? _messages;
  Timer? _closeTimer;
  ParsedTransaction? _transaction;
  String _category = 'Uncategorized';

  @override
  void initState() {
    super.initState();
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
        false,
      );
    } catch (_) {}
    await CategoryRegistry.instance.load();
    final id = int.tryParse(
      await _repository.getAppState(PaymentPopup.pendingTransactionKey) ?? '',
    );
    final transaction = id == null ? null : await _repository.findById(id);
    if (!mounted) return;
    if (transaction == null) {
      await _close();
      return;
    }
    setState(() {
      _transaction = transaction;
      _category = transaction.category;
    });
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(seconds: 20), _close);
  }

  Future<void> _close() async {
    _closeTimer?.cancel();
    try {
      await FlutterOverlayWindow.closeOverlay();
    } catch (_) {}
  }

  Future<void> _finish(TransactionStatus status) async {
    final transaction = _transaction;
    if (transaction?.id == null) return;
    if (status == TransactionStatus.confirmed &&
        _category != transaction!.category) {
      await _repository.updatePartyAndCategory(
        transaction.id!,
        category: _category,
      );
    }
    await _repository.updateStatus(transaction!.id!, status);
    await _close();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    if (transaction == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Card(
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.party,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          AmountText(
                            amountPaise: transaction.amountPaise,
                            type: transaction.type,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            transaction.paymentMethod.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _close,
                      icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final category in CategoryRegistry.instance.names)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: CategoryChip(
                            category: category,
                            isSelected: category == _category,
                            showIcon: true,
                            onTap: () => setState(() => _category = category),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _finish(TransactionStatus.ignored),
                      child: const Text('Ignore'),
                    ),
                    const Spacer(),
                    TextButton(onPressed: _close, child: const Text('Later')),
                    FilledButton(
                      onPressed: () => _finish(TransactionStatus.confirmed),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
