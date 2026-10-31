import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/finance_data_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/language_service.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../sms/data/transaction_repository.dart';
import '../sms/models/parsed_transaction.dart';
import '../sms/models/transaction_status.dart';
import '../sms/presentation/screens/sms_shell_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<FinanceDashboardData> _dashboard;
  late final TransactionRepository _smsRepository;
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();
    _smsRepository = TransactionRepository();
    _dashboard = FinanceDataService.loadDashboard();
  }

  Future<void> _refresh() async {
    setState(() => _dashboard = FinanceDataService.loadDashboard());
    await _dashboard;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: LanguageService.selectedLanguage,
    builder: (context, _, __) => ValueListenableBuilder<String>(
      valueListenable: CurrencyService.selected,
      builder: (context, _, child) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      child: FutureBuilder<FinanceDashboardData>(
        future: _dashboard,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return _ErrorState(onRetry: _refresh);
          final data = snapshot.data!;
          if (data.accounts.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _header(data.firstName),
                      const SizedBox(height: 26),
                      _usableBalanceCard(data),
                      const SizedBox(height: 20),
                      _smsTransactionsCard(),
                      const SizedBox(height: 28),
                      _sectionHeader('Recent transactions'),
                      const SizedBox(height: 12),
                      _transactions(data.transactions),
                      const SizedBox(height: 28),
                      _sectionHeader('Accounts'),
                      const SizedBox(height: 12),
                      _accounts(data.accounts),
                      if (data.creditCardDue > 0) ...[
                        const SizedBox(height: 20),
                        _creditDue(data.creditCardDue),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
    ),
    ),
  );

  Widget _smsTransactionsCard() {
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<ParsedTransaction>>(
      stream: _smsRepository.watchAll(statusFilter: TransactionStatus.pending),
      builder: (context, snapshot) {
        final pendingCount = (snapshot.data ?? []).length;
        final subtitle = pendingCount > 0 ? '$pendingCount to review' : 'Import from SMS';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMS transactions', style: _text(16, scheme.onSurface, FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: _text(
                        13,
                        pendingCount > 0 ? AppColors.secondary : AppColors.textSecondary,
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SmsShellScreen(repository: _smsRepository),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pendingCount > 0 ? 'Review' : 'Import', style: _text(13, AppColors.primary, FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(String name) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.auto_graph_rounded, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your finances'.tr(),
              style: _text(13, scheme.onSurfaceVariant, FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              '${'Hi,'.tr()} $name',
              style: _text(20, scheme.onSurface, FontWeight.w800),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: _refresh,
        tooltip: 'Refresh',
        style: IconButton.styleFrom(backgroundColor: scheme.surfaceContainer),
        icon: const Icon(Icons.refresh_rounded),
      ),
      ],
    );
  }

  Widget _usableBalanceCard(FinanceDashboardData data) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF9A62FF), AppColors.primary, Color(0xFF5B1FCC)],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Usable Balance'.tr(),
              style: _text(14, Colors.white70, FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _showBalance = !_showBalance),
              icon: Icon(
                _showBalance
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          _showBalance
              ? _currency(data.usableBalance)
              : '${CurrencyService.symbolFor(CurrencyService.current)} ••••••••',
          style: _text(34, Colors.white, FontWeight.w800, letterSpacing: -1.1),
        ),
        const SizedBox(height: 4),
        Text(
          'Across ${data.accounts.where((a) => a.isDepositAccount).length} active deposit account${data.accounts.where((a) => a.isDepositAccount).length == 1 ? '' : 's'}',
          style: _text(12.5, Colors.white70, FontWeight.w500),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_down_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '${_currency(data.monthSpend)} spent this month',
                  style: _text(13, Colors.white, FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title) => Text(
    title.tr(),
    style: _text(
      19,
      Theme.of(context).colorScheme.onSurface,
      FontWeight.w800,
    ),
  );

  Widget _transactions(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty)
      return const _NoRecords(label: 'No transactions have been synced yet.');
    return Column(
      children: transactions
          .map((transaction) => _TransactionRow(transaction: transaction))
          .toList(),
    );
  }

  Widget _accounts(List<FinanceAccount> accounts) => SizedBox(
    height: 154,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: accounts.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, index) => _AccountCard(account: accounts[index]),
    ),
  );

  Widget _creditDue(double amount) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2ED),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.credit_card_rounded, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Credit card balance reported',
            style: _text(14, scheme.onSurface, FontWeight.w700),
          ),
        ),
        Text(
          _currency(amount),
          style: _text(14, scheme.onSurface, FontWeight.w800),
        ),
      ],
    ),
    );
  }


  TextStyle _text(
    double size,
    Color color,
    FontWeight weight, {
    double? letterSpacing,
  }) => GoogleFonts.inter(
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}

class _TransactionRow extends StatelessWidget {
  final FinanceTransaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final credited = transaction.direction == TransactionDirection.credit;
    final scheme = Theme.of(context).colorScheme;
    final date = transaction.occurredAt;
    final time =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (credited ? AppColors.success : AppColors.warning)
                .withValues(alpha: .14),
            child: Icon(
              credited ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: credited ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchant,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                Text(
                  transaction.category?.isNotEmpty == true
                      ? '${transaction.category} · $time'
                      : time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${credited ? '+' : '-'} ${_currency(transaction.amount)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: credited ? AppColors.success : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final FinanceAccount account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
    width: 236,
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: account.isCreditCard
          ? scheme.secondaryContainer
          : scheme.primaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          account.isCreditCard
              ? Icons.credit_card_rounded
              : Icons.account_balance_rounded,
          color: AppColors.primary,
        ),
        const Spacer(),
        Text(
          account.providerName,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        Text(
          '${account.displayType} · ${account.maskedAccountNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          account.latestBalance == null
              ? 'Balance unavailable'
              : '${_currency(account.latestBalance!)}${account.isCreditCard ? ' reported' : ''}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 52,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts yet'.tr(),
            style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a bank, wallet, or credit card to start tracking your finances.'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addAccount),
            icon: const Icon(Icons.add),
            label: Text('Add new account'.tr()),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'We could not load your data',
            style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _NoRecords extends StatelessWidget {
  final String label;
  const _NoRecords({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

String _currency(double value) => CurrencyService.format(value);
