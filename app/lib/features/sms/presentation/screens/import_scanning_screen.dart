import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_counter.dart';

class ImportScanningScreen extends StatelessWidget {
  final int checked;
  final int found;
  final int skipped;
  final double? progress; // null = indeterminate

  const ImportScanningScreen({
    super.key,
    required this.checked,
    required this.found,
    required this.skipped,
    this.progress,
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
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scanning Inbox',
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
              const Text(
                'Reading banking and payment SMS messages…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: progress != null
                    ? LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      )
                    : const LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
              // Counters card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatCounter(
                      label: 'Checked',
                      value: '$checked',
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border,
                    ),
                    StatCounter(
                      label: 'Found',
                      value: '$found',
                      valueColor: AppColors.credit,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.border,
                    ),
                    StatCounter(
                      label: 'Skipped',
                      value: '$skipped',
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Privacy info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Processing happens on this phone. We don\'t save message text.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'You can leave this screen. We\'ll keep going.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

