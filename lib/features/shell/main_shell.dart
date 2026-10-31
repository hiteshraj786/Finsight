import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/language_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screens.dart';

import '../sms/data/transaction_repository.dart';
import '../sms/presentation/screens/manual_add_sheet.dart';
import '../sms/presentation/screens/transactions_screen.dart';

/// Activity tab screen with transactions list and manual add capability.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final TransactionRepository _repository = TransactionRepository();

  @override
  Widget build(BuildContext context) {
    return TransactionsScreen(
      repository: _repository,
      onAddManual: () {
        ManualAddSheet.show(
          context,
          repository: _repository,
          onSaved: () {},
        );
      },
    );
  }
}

/// Placeholder screen for Budget / Insights tab.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

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
              Icon(Icons.pie_chart_outline_rounded, size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Budget'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your budget insights will appear here'.tr(),
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

/// The unified app shell that wraps all four main tabs with a single,
/// shared bottom navigation bar. This ensures consistent navigation
/// from any tab and instant language / currency reactivity everywhere.
class MainShellScreen extends StatefulWidget {
  /// Optional initial tab index (0=Home, 1=Activity, 2=Budget, 3=Profile).
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
                BudgetScreen(),
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
                    _navItem(2, Icons.pie_chart_outline_rounded, 'Budget'.tr(), scheme),
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
