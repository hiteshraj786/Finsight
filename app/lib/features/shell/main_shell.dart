import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/preferences/language_service.dart';
import '../../services/preferences/currency_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screens.dart';

import '../../data/repositories/transaction_repository.dart';
import '../../data/models/parsed_transaction.dart';
import '../../data/models/transaction_status.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/sms/payment_popup.dart';
import '../../services/sms/sms_sync_service.dart';
import '../sms/screens/manual_add_sheet.dart';
import '../sms/screens/new_transaction_popup_sheet.dart';
import '../sms/screens/sms_shell_screen.dart';
import '../sms/screens/transaction_detail_sheet.dart';
import '../sms/screens/transactions_screen.dart';
import '../sms/theme/sms_theme.dart' as sms;
import '../sms/filters/transaction_filter.dart';
import '../../core/constants/app_routes.dart';

enum _ActivityAction { scanSms, reviewSms, addManual, categories, deleteAll }

/// Activity tab: this month's transactions with filters, plus a top-right
/// menu for SMS import, review, manual entry and categories.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TransactionRepository _repository = TransactionRepository();

  void _openSms({bool scan = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmsShellScreen(repository: _repository, startScan: scan),
      ),
    );
  }

  void _addManual() {
    ManualAddSheet.show(context, repository: _repository, onSaved: () {});
  }

  void _onAction(_ActivityAction action) {
    switch (action) {
      case _ActivityAction.scanSms:
        _openSms(scan: true);
      case _ActivityAction.reviewSms:
        _openSms();
      case _ActivityAction.addManual:
        _addManual();
      case _ActivityAction.categories:
        Navigator.of(context).pushNamed(AppRoutes.categories);
      case _ActivityAction.deleteAll:
        _confirmDeleteAll();
    }
  }

  Future<void> _confirmDeleteAll() async {
    final count = (await _repository.getAll()).length;
    if (!mounted) return;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no transactions to delete.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: Text('Delete all $count transactions?'),
        content: const Text(
          'Your categories and learned merchant categories are kept. Use '
          '"Scan SMS inbox" to import SMS transactions again.\n\n'
          'Transactions you added manually cannot be imported again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleted = await _repository.deleteAllTransactions();
    SmsSyncService.instance.popups.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted $deleted transactions.'),
        action: SnackBarAction(
          label: 'Scan SMS',
          onPressed: () => _openSms(scan: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    sms.AppColors.rebuildOnThemeChange(context);
    return StreamBuilder<List<ParsedTransaction>>(
      stream: _repository.watchAll(statusFilter: TransactionStatus.pending),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.length ?? 0;
        return TransactionsScreen(
          repository: _repository,
          onAddManual: _addManual,
          title: 'Activity'.tr(),
          initialFilter: TransactionFilter.thisMonth,
          actions: [_buildActionsMenu(pendingCount)],
          header: pendingCount == 0
              ? null
              : _ReviewBanner(
                  count: pendingCount,
                  onTap: () => _openSms(),
                ),
        );
      },
    );
  }

  Widget _buildActionsMenu(int pendingCount) {
    PopupMenuItem<_ActivityAction> item(
      _ActivityAction value,
      IconData icon,
      String title,
      String subtitle, {
      Widget? trailing,
    }) => PopupMenuItem(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title.tr()),
        subtitle: Text(subtitle.tr()),
        trailing: trailing,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<_ActivityAction>(
        tooltip: 'More actions'.tr(),
        onSelected: _onAction,
        position: PopupMenuPosition.under,
        icon: Badge(
          isLabelVisible: pendingCount > 0,
          backgroundColor: AppColors.secondary,
          smallSize: 9,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        itemBuilder: (_) => [
          item(
            _ActivityAction.scanSms,
            Icons.sync_rounded,
            'Scan SMS inbox',
            'Import bank messages now',
          ),
          item(
            _ActivityAction.reviewSms,
            Icons.sms_rounded,
            'Review SMS transactions',
            'Confirm or ignore imported ones',
            trailing: pendingCount > 0
                ? Badge(
                    label: Text('$pendingCount'),
                    backgroundColor: AppColors.secondary,
                  )
                : null,
          ),
          item(
            _ActivityAction.addManual,
            Icons.edit_note_rounded,
            'Add manually',
            'Record a cash or other expense',
          ),
          const PopupMenuDivider(),
          item(
            _ActivityAction.categories,
            Icons.category_outlined,
            'Categories',
            'Create or edit your categories',
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _ActivityAction.deleteAll,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
              ),
              title: Text(
                'Delete all transactions'.tr(),
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: Text('You can import SMS ones again'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

/// "N transactions to review" strip shown above the Activity summary.
class _ReviewBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ReviewBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: sms.AppColors.pendingBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.sms_rounded, color: sms.AppColors.pendingText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count == 1
                        ? '1 SMS transaction to review'
                        : '$count SMS transactions to review',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sms.AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: sms.AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder screen for Insights tab.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights_rounded, size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Insights'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your spending insights will appear here'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility typedef
typedef BudgetScreen = InsightsScreen;

/// The unified app shell that wraps all four main tabs with a single,
/// shared bottom navigation bar. This ensures consistent navigation
/// from any tab and instant language / currency reactivity everywhere.
class MainShellScreen extends StatefulWidget {
  /// Optional initial tab index (0=Home, 1=Activity, 2=Insights, 3=Profile).
  final int initialTab;
  const MainShellScreen({super.key, this.initialTab = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  final SmsSyncService _sync = SmsSyncService.instance;
  bool _popupOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    // Import new SMS automatically from here on: live while the app is open,
    // and as a catch-up whenever the app returns to the foreground.
    _sync.popups.addListener(_onPopupQueueChanged);
    _sync.attach();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onPopupQueueChanged();
      _maybeOfferPaymentPopups();
    });
  }

  /// Asks once, after SMS access is granted, whether to show payment popups
  /// over other apps (it needs a separate Android permission).
  Future<void> _maybeOfferPaymentPopups() async {
    if (!await Permission.sms.isGranted) return;
    if (!await PaymentPopup.isEnabled() || await PaymentPopup.hasPermission()) {
      return;
    }
    if (!await PaymentPopup.takePromptTurn() || !mounted) return;
    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.picture_in_picture_alt_rounded),
        title: const Text('Show payment popups?'),
        content: const Text(
          'After you pay in GPay, PhonePe or any app, FinSight can show a small '
          'card on top of it 5 seconds later so you can categorise the payment '
          'right there. Android will ask you to allow "Display over other apps".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (allow == true) await PaymentPopup.requestPermission();
  }

  @override
  void dispose() {
    _sync.popups.removeListener(_onPopupQueueChanged);
    _sync.detach();
    super.dispose();
  }

  /// Shows queued "new transaction" popups one at a time, on top of whichever
  /// tab or screen is open.
  void _onPopupQueueChanged() {
    final popups = _sync.popups;
    final tx = popups.currentPopup;
    if (!mounted || _popupOpen || !popups.isShowing || tx == null) return;
    _popupOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await _showNewTransactionPopup(tx);
      _popupOpen = false;
      // Swiping the sheet away counts as "decide later".
      if (identical(popups.currentPopup, tx)) popups.markDismissed();
      _onPopupQueueChanged();
    });
  }

  Future<void> _showNewTransactionPopup(ParsedTransaction tx) {
    final repository = _sync.repository;
    final popups = _sync.popups;
    return NewTransactionPopupSheet.show(
      context,
      transaction: tx,
      onConfirm: (category) async {
        if (tx.id != null) {
          await repository.updatePartyAndCategory(tx.id!, category: category);
          await repository.updateStatus(tx.id!, TransactionStatus.confirmed);
        }
        popups.markDismissed();
      },
      onIgnore: () async {
        if (tx.id != null) {
          await repository.updateStatus(tx.id!, TransactionStatus.ignored);
        }
        popups.markDismissed();
      },
      onEdit: () {
        popups.markDismissed();
        TransactionDetailSheet.show(
          context,
          transaction: tx,
          repository: repository,
          onSaved: () {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // React to language + currency changes so the bottom bar labels update.
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.selectedLanguage,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: CurrencyService.selected,
        builder: (context, _, __) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: IndexedStack(
              key: ValueKey('shell_stack_${LanguageService.current}_${CurrencyService.current}'),
              index: _currentIndex,
              children: const [
                HomeScreen(),
                ActivityScreen(),
                InsightsScreen(),
                ProfileScreen(),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    top: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.home_rounded, 'Home'.tr(), scheme),
                    _navItem(1, Icons.receipt_long_outlined, 'Activity'.tr(), scheme),
                    _navItem(2, Icons.insights_rounded, 'Insights'.tr(), scheme),
                    _navItem(3, Icons.person_outline_rounded, 'Profile'.tr(), scheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, ColorScheme scheme) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.primary : scheme.onSurfaceVariant,
              size: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                color: active ? AppColors.primary : scheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
