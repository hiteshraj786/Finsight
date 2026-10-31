import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/language_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screens.dart';

import '../sms/data/transaction_repository.dart';
import '../sms/models/parsed_transaction.dart';
import '../sms/models/transaction_status.dart';
import '../sms/presentation/screens/manual_add_sheet.dart';
import '../sms/presentation/screens/sms_shell_screen.dart';

/// Activity tab screen dedicated to SMS transactions review, scanning, and sync.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TransactionRepository _repository = TransactionRepository();

  void _openSmsReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmsShellScreen(repository: _repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Activity'.tr(),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add manual transaction'.tr(),
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              ManualAddSheet.show(
                context,
                repository: _repository,
                onSaved: () => setState(() {}),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<ParsedTransaction>>(
          stream: _repository.watchAll(statusFilter: TransactionStatus.pending),
          builder: (context, snapshot) {
            final pendingTxs = snapshot.data ?? [];
            final pendingCount = pendingTxs.length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // SMS Transactions Review Card (from Home)
                _buildSmsCard(scheme, pendingCount),
                const SizedBox(height: 20),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.sync_rounded,
                        title: 'Scan SMS'.tr(),
                        subtitle: 'Import new messages'.tr(),
                        color: AppColors.primary,
                        onTap: _openSmsReview,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.edit_note_rounded,
                        title: 'Add Manual'.tr(),
                        subtitle: 'Record an expense'.tr(),
                        color: AppColors.secondary,
                        onTap: () {
                          ManualAddSheet.show(
                            context,
                            repository: _repository,
                            onSaved: () => setState(() {}),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmsCard(ColorScheme scheme, int pendingCount) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.sms_rounded, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMS transactions',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pendingCount > 0 ? AppColors.secondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: _openSmsReview,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pendingCount > 0 ? 'Review' : 'Import',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
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
