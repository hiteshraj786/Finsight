import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Pure Flutter Illustration 1: "Gain total control of your money"
/// Inspired by Onboarding 1 concept (Money in hand & financial power)
class ControlMoneyIllustration extends StatelessWidget {
  const ControlMoneyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient radial glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.8),
                  AppColors.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Background secondary tilted card
          Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 190,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFC4A8FF), const Color(0xFF9E72FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),

          // Main Hero Card (Premium Wallet / Card)
          Transform.rotate(
            angle: 0.06,
            child: Container(
              width: 210,
              height: 135,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B47FF),
                    Color(0xFF7F3DFF),
                    Color(0xFF5B1FCC),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'FinSight',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.contactless_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹ 1,48,250',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Floating Badge: "+ ₹5,000 Income"
          Positioned(
            top: 25,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Color(0xFF00A86B),
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+ ₹5,000',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00A86B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Badge: Secure / In Control Shield
          Positioned(
            bottom: 25,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),

          // Floating Star / Sparkle
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFCAC12).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFCAC12),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure Flutter Illustration 2: "Know where your money goes"
/// Inspired by Onboarding 2 concept (Receipt roll, bills, categories)
class ExpenseTrackingIllustration extends StatelessWidget {
  const ExpenseTrackingIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.8),
                  AppColors.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Stylized Receipt Card
          Container(
            width: 200,
            height: 230,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    Text(
                      'Report',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item 1: Food
                _buildCategoryRow(
                  icon: Icons.restaurant,
                  color: const Color(0xFFFD3C4A),
                  name: 'Food & Dining',
                  amount: '-₹ 3,200',
                ),
                const SizedBox(height: 12),

                // Item 2: Shopping
                _buildCategoryRow(
                  icon: Icons.shopping_bag,
                  color: const Color(0xFFFCAC12),
                  name: 'Shopping',
                  amount: '-₹ 8,400',
                ),
                const SizedBox(height: 12),

                // Item 3: Travel
                _buildCategoryRow(
                  icon: Icons.directions_car,
                  color: const Color(0xFF0077B6),
                  name: 'Transport',
                  amount: '-₹ 1,150',
                ),

                const Spacer(),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Spent',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₹ 12,750',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating Pie Chart Badge
          Positioned(
            top: 20,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pie_chart_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),

          // Floating Analytics Badge
          Positioned(
            bottom: 20,
            left: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B47FF), Color(0xFF7F3DFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insights, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Categorized',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required IconData icon,
    required Color color,
    required String name,
    required String amount,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFD3C4A),
          ),
        ),
      ],
    );
  }
}

/// Pure Flutter Illustration 3: "Planning ahead"
/// Inspired by Onboarding 3 concept (Clipboard plan, checklist, budget control)
class BudgetPlanningIllustration extends StatelessWidget {
  const BudgetPlanningIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.8),
                  AppColors.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // Clipboard Board Base
          Transform.rotate(
            angle: -0.04,
            child: Container(
              width: 210,
              height: 240,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Clipboard Clamp
                  Center(
                    child: Container(
                      width: 70,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'PLAN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Checklist Item 1
                  _buildChecklistItem(
                    title: 'Food Budget',
                    isDone: true,
                    progress: 0.65,
                    color: const Color(0xFFFCAC12),
                  ),
                  const SizedBox(height: 16),

                  // Checklist Item 2
                  _buildChecklistItem(
                    title: 'Savings Goal',
                    isDone: true,
                    progress: 0.85,
                    color: const Color(0xFF00A86B),
                  ),
                  const SizedBox(height: 16),

                  // Checklist Item 3
                  _buildChecklistItem(
                    title: 'Emergency Fund',
                    isDone: true,
                    progress: 0.45,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Floating Success Target Badge
          Positioned(
            top: 25,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A86B).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00A86B),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'On Track',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00A86B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Target Bullseye
          Positioned(
            bottom: 25,
            left: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isDone,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF00A86B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
