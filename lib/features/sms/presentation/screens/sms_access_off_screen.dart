import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/finsight_logo.dart';
import '../widgets/pill_buttons.dart';

class SmsAccessOffScreen extends StatelessWidget {
  final VoidCallback onAddManually;
  final VoidCallback? onRetryPermission;

  const SmsAccessOffScreen({
    super.key,
    required this.onAddManually,
    this.onRetryPermission,
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
                  decoration: const BoxDecoration(
                    color: AppColors.pendingBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.sms_failed_rounded,
                    size: 42,
                    color: AppColors.pendingText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SMS Access is Off',
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
                'Messages are processed on this phone to build your ledger. Without SMS permission, automatic transaction detection cannot run.',
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
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'You can still add entries by hand anytime, or enable SMS permission in settings to automate tracking.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryPillButton(
                label: 'Open settings',
                icon: Icons.settings_rounded,
                onPressed: () => openAppSettings(),
              ),
              if (onRetryPermission != null) ...[
                const SizedBox(height: 10),
                SecondaryPillButton(
                  label: 'Check permission again',
                  onPressed: onRetryPermission,
                ),
              ],
              const SizedBox(height: 10),
              SecondaryPillButton(
                label: 'Add manually',
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
}

