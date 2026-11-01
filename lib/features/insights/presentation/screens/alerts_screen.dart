import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/insights_repository_provider.dart';
import '../../domain/models.dart';
import 'budgets_screen.dart';
import 'category_analytics_screen.dart';
import 'recurring_payments_screen.dart';
import 'savings_goals_screen.dart';
import 'unusual_transactions_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  String _selectedFilter = 'all'; // 'all', 'budgets', 'recurring', 'unusual'
  bool _loading = true;
  List<AlertItem> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getAlerts(filter: _selectedFilter);
    if (mounted) {
      setState(() {
        _alerts = data;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await _repo.markAllAlertsRead();
    _loadData();
  }

  void _handleAlertTap(AlertItem alert) async {
    await _repo.markAlertRead(alert.id);
    if (!mounted) return;

    Widget nextScreen;
    switch (alert.type) {
      case AlertType.budget:
        nextScreen = const BudgetsScreen();
        break;
      case AlertType.recurring:
        nextScreen = const RecurringPaymentsScreen();
        break;
      case AlertType.unusual:
        nextScreen = const UnusualTransactionsScreen();
        break;
      case AlertType.goal:
        nextScreen = const SavingsGoalsScreen();
        break;
      case AlertType.trend:
        nextScreen = const CategoryAnalyticsScreen();
        break;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => nextScreen));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF212325)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alerts',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F3DFF)))
          : Column(
              children: [
                // Sub-header with unread count & Mark all read
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$unreadCount unread notifications',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF91919F),
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7F3DFF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Row(
                          children: [
                            const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF7F3DFF)),
                            const SizedBox(width: 4),
                            Text(
                              'Mark all read',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7F3DFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Filter Pills (All | Budgets | Recurring | Unusual)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _filterTab('All', 'all'),
                      const SizedBox(width: 8),
                      _filterTab('Budgets', 'budgets'),
                      const SizedBox(width: 8),
                      _filterTab('Recurring', 'recurring'),
                      const SizedBox(width: 8),
                      _filterTab('Unusual', 'unusual'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Alerts list
                Expanded(
                  child: _alerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_off_outlined, size: 48, color: Color(0xFF91919F)),
                              const SizedBox(height: 12),
                              Text(
                                'No alerts right now',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF212325)),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _alerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final alert = _alerts[i];
                            return _buildAlertCard(alert);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterTab(String label, String value) {
    final selected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7F3DFF) : const Color(0xFFF1F1FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF91919F),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (alert.type) {
      case AlertType.budget:
        icon = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFFD3C4A);
        iconBg = const Color(0xFFFFECEF);
        break;
      case AlertType.recurring:
        icon = Icons.calendar_today_outlined;
        iconColor = const Color(0xFF7F3DFF);
        iconBg = const Color(0xFFEEE5FF);
        break;
      case AlertType.unusual:
        icon = Icons.flag_outlined;
        iconColor = const Color(0xFFFD3C4A);
        iconBg = const Color(0xFFFFECEF);
        break;
      case AlertType.goal:
        icon = Icons.trending_up_rounded;
        iconColor = const Color(0xFF00A86B);
        iconBg = const Color(0xFFE6F7F0);
        break;
      case AlertType.trend:
        icon = Icons.restaurant_rounded;
        iconColor = const Color(0xFF7F3DFF);
        iconBg = const Color(0xFFEEE5FF);
        break;
    }

    return InkWell(
      onTap: () => _handleAlertTap(alert),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F1FA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212325),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF91919F),
                    ),
                  ),
                  if (alert.actionLabel != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _handleAlertTap(alert),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F3DFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          alert.actionLabel!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!alert.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF7F3DFF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
