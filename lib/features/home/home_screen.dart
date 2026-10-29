import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/finance_data_service.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<FinanceDashboardData> _dashboard;
  bool _showBalance = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboard = FinanceDataService.loadDashboard();
  }

  Future<void> _refresh() async {
    setState(() => _dashboard = FinanceDataService.loadDashboard());
    await _dashboard;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF8F7FA),
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
        bottomNavigationBar: _bottomNavigation(),
      );

  Widget _header(String name) => Row(children: [
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your finances', style: _text(13, AppColors.textSecondary, FontWeight.w500)),
          const SizedBox(height: 2),
          Text('Hi, $name', style: _text(20, AppColors.textPrimary, FontWeight.w800)),
        ])),
        IconButton(
          onPressed: _refresh,
          tooltip: 'Refresh',
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ]);

  Widget _usableBalanceCard(FinanceDashboardData data) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9A62FF), AppColors.primary, Color(0xFF5B1FCC)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Current usable balance', style: _text(14, Colors.white70, FontWeight.w600)),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _showBalance = !_showBalance),
              icon: Icon(_showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white),
            ),
          ]),
          Text(
            _showBalance ? _currency(data.usableBalance) : '₹ ••••••••',
            style: _text(34, Colors.white, FontWeight.w800, letterSpacing: -1.1),
          ),
          const SizedBox(height: 4),
          Text('Across ${data.accounts.where((a) => a.isDepositAccount).length} active deposit account${data.accounts.where((a) => a.isDepositAccount).length == 1 ? '' : 's'}', style: _text(12.5, Colors.white70, FontWeight.w500)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              const Icon(Icons.trending_down_rounded, color: Colors.white, size: 19),
              const SizedBox(width: 9),
              Expanded(child: Text('${_currency(data.monthSpend)} spent this month', style: _text(13, Colors.white, FontWeight.w600))),
            ]),
          ),
        ]),
      );

  Widget _sectionHeader(String title) => Text(title, style: _text(19, AppColors.textPrimary, FontWeight.w800));

  Widget _transactions(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) return const _NoRecords(label: 'No transactions have been synced yet.');
    return Column(children: transactions.map((transaction) => _TransactionRow(transaction: transaction)).toList());
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

  Widget _creditDue(double amount) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFFF2ED), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const Icon(Icons.credit_card_rounded, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(child: Text('Credit card balance reported', style: _text(14, AppColors.textPrimary, FontWeight.w700))),
          Text(_currency(amount), style: _text(14, AppColors.textPrimary, FontWeight.w800)),
        ]),
      );

  Widget _bottomNavigation() => SafeArea(
        top: false,
        child: Container(
          height: 76,
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(0, Icons.home_rounded, 'Home'),
            _navItem(1, Icons.receipt_long_outlined, 'Activity'),
            _navItem(2, Icons.pie_chart_outline_rounded, 'Insights'),
            _navItem(3, Icons.person_outline_rounded, 'Profile'),
          ]),
        ),
      );

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(width: 66, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: active ? AppColors.primary : AppColors.textLight, size: 23),
        const SizedBox(height: 4),
        Text(label, style: _text(10.5, active ? AppColors.primary : AppColors.textSecondary, active ? FontWeight.w700 : FontWeight.w500)),
      ])),
    );
  }

  TextStyle _text(double size, Color color, FontWeight weight, {double? letterSpacing}) =>
      GoogleFonts.inter(fontSize: size, color: color, fontWeight: weight, letterSpacing: letterSpacing);
}

class _TransactionRow extends StatelessWidget {
  final FinanceTransaction transaction;
  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final credited = transaction.direction == TransactionDirection.credit;
    final date = transaction.occurredAt;
    final time = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        CircleAvatar(backgroundColor: (credited ? AppColors.success : AppColors.warning).withValues(alpha: .14), child: Icon(credited ? Icons.south_west_rounded : Icons.north_east_rounded, color: credited ? AppColors.success : AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(transaction.merchant, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          Text(transaction.category?.isNotEmpty == true ? '${transaction.category} · $time' : time, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        Text('${credited ? '+' : '-'} ${_currency(transaction.amount)}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: credited ? AppColors.success : AppColors.textPrimary)),
      ]),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final FinanceAccount account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) => Container(
        width: 236,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: account.isCreditCard ? const Color(0xFFFFE4D2) : const Color(0xFFE8DEFF), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(account.isCreditCard ? Icons.credit_card_rounded : Icons.account_balance_rounded, color: AppColors.primary),
          const Spacer(),
          Text(account.providerName, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          Text('${account.displayType} · ${account.maskedAccountNumber}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(account.latestBalance == null ? 'Balance unavailable' : '${_currency(account.latestBalance!)}${account.isCreditCard ? ' reported' : ''}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.account_balance_outlined, size: 52, color: AppColors.primary),
          const SizedBox(height: 16),
          Text('No accounts yet', style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Your accounts and transactions will appear here once available.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.4)),
        ]),
      ));
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text('We could not load your data', style: GoogleFonts.inter(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      ));
}

class _NoRecords extends StatelessWidget {
  final String label;
  const _NoRecords({required this.label});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary)),
      );
}

String _currency(double value) => '₹ ${value.toStringAsFixed(2)}';
