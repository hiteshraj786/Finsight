import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class EmailSentScreen extends StatelessWidget {
  final String? email;

  const EmailSentScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    final displayEmail = (email != null && email!.isNotEmpty)
        ? email!
        : 'your inbox';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Pure Flutter Flying Mail Illustration (No PNG image!)
              const _FlyingMailIllustration(),

              const SizedBox(height: 36),

              // Title
              Text(
                'Your email is on the way',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Check your email $displayEmail and follow the instructions to reset your password',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Back to Login button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                },
                child: const Text('Back to Login'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pure Flutter Illustration of a Flying Envelope with Motion Trails
class _FlyingMailIllustration extends StatelessWidget {
  const _FlyingMailIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient soft purple circular glow
          Container(
            width: 180,
            height: 180,
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

          // Speed Lines / Motion trails
          Positioned(
            left: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMotionLine(
                  width: 50,
                  color: const Color(0xFFFC8B3D),
                  angle: -0.25,
                ),
                const SizedBox(height: 10),
                _buildMotionLine(
                  width: 65,
                  color: const Color(0xFFFCAC12),
                  angle: -0.2,
                ),
                const SizedBox(height: 10),
                _buildMotionLine(
                  width: 45,
                  color: const Color(0xFFFC8B3D),
                  angle: -0.15,
                ),
              ],
            ),
          ),

          // Flying Envelope (Tilted)
          Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 170,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(8, 16),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Envelope Flap (Top purple triangle/arc)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 55,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF8B47FF), Color(0xFF7F3DFF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  // Bottom Body
                  Positioned(
                    bottom: 12,
                    left: 18,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 45,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Sparkle
          Positioned(
            top: 25,
            right: 25,
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

  Widget _buildMotionLine({
    required double width,
    required Color color,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
