import 'package:flutter/material.dart';
import '../theme/sms_theme.dart';
import '../widgets/pill_buttons.dart';
import '../widgets/stat_counter.dart';

class ImportCompleteScreen extends StatelessWidget {
  final int totalFound;
  final int newCount;
  final int alreadySavedCount;
  final int lowConfidenceCount;
  final VoidCallback onReview;
  final VoidCallback onLater;

  const ImportCompleteScreen({
    super.key,
    required this.totalFound,
    required this.newCount,
    required this.alreadySavedCount,
    required this.lowConfidenceCount,
    required this.onReview,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.creditLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: AppColors.credit,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$totalFound transactions found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan completed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              // Results card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StatCounter(
                          label: 'New',
                          value: '$newCount',
                          valueColor: AppColors.primary,
                        ),
                        Container(width: 1, height: 36, color: AppColors.border),
                        StatCounter(
                          label: 'Already saved',
                          value: '$alreadySavedCount',
                          valueColor: AppColors.textSecondary,
                        ),
                        Container(width: 1, height: 36, color: AppColors.border),
                        StatCounter(
                          label: 'Low confidence',
                          value: '$lowConfidenceCount',
                          valueColor: AppColors.pendingText,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryPillButton(
                label: 'Review transactions',
                icon: Icons.checklist_rounded,
                onPressed: onReview,
              ),
              const SizedBox(height: 10),
              SecondaryPillButton(
                label: 'Later',
                outlined: true,
                onPressed: onLater,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Messages are processed on this phone. We don\'t save message text.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

