import 'package:flutter/material.dart';
import '../theme/sms_theme.dart';
import '../widgets/finsight_logo.dart';
import '../widgets/pill_buttons.dart';

class SmsPermissionScreen extends StatelessWidget {
  final VoidCallback onAllowSms;
  final VoidCallback onAddManually;

  const SmsPermissionScreen({
    super.key,
    required this.onAllowSms,
    required this.onAddManually,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Center(child: FinSightLogo(size: 40, fontSize: 22)),
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.security_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Instant Expense Tracking',
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
                'FinSight converts your bank and UPI SMS into a private, organized financial overview.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      Icons.mark_email_read_rounded,
                      'Only bank and payment messages are used',
                    ),
                    Divider(height: 20, color: AppColors.border),
                    _buildFeatureRow(
                      Icons.phonelink_lock_rounded,
                      'Your messages and transactions stay on this phone',
                    ),
                    Divider(height: 20, color: AppColors.border),
                    _buildFeatureRow(
                      Icons.touch_app_rounded,
                      'Nothing is finalized without your tap',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryPillButton(
                label: 'Allow SMS access',
                icon: Icons.check_circle_outline_rounded,
                onPressed: onAllowSms,
              ),
              const SizedBox(height: 12),
              SecondaryPillButton(
                label: 'Add transactions manually',
                outlined: true,
                onPressed: onAddManually,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

