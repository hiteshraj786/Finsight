import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../services/auth/pin_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/backend/profile_service.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _waitingForGoogle = false;
  bool _showOAuthEscapeHatch = false;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    // Route resolution can be almost instant with a cached session. Keep the
    // brand animation visible long enough to be perceived as a splash screen.
    final minimumSplashDisplay = Future<void>.delayed(
      const Duration(milliseconds: 1600),
    );
    // A Google OAuth callback can relaunch the app before its session is
    // persisted. Do not fall through to onboarding while that callback is
    // still being delivered: the global auth listener and this screen would
    // otherwise race each other and briefly show the sign-up flow.
    final isWaitingForGoogle = await AuthService.hasPendingOAuthCallback();
    if (isWaitingForGoogle && mounted) {
      setState(() => _waitingForGoogle = true);
      Future<void>.delayed(const Duration(seconds: 10), () {
        if (mounted && _waitingForGoogle) {
          setState(() => _showOAuthEscapeHatch = true);
        }
      });
    }
    await AuthService.waitForPendingOAuthCallback();
    await minimumSplashDisplay;
    if (!mounted) return;

    if (!AuthService.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    try {
      final profile = await ProfileService.load();
      AppTheme.setPreference(profile.preferences.theme);
    } on ProfileException {
      // A missing preferences row should not block a valid signed-in user.
    }

    final hasPin = await PinService.hasPin();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacementNamed(
      hasPin ? AppRoutes.unlockPin : AppRoutes.setupAccount,
    );
  }

  Future<void> _cancelGoogleSignIn() async {
    await AuthService.cancelPendingOAuthCallback();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8B47FF), Color(0xFF7F3DFF), Color(0xFF7231E6)],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect behind the "n"
                      Positioned(
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: _glowAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pinkAccent.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 60,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Logo text
                      Text(
                        'Finsight',
                        style: GoogleFonts.inter(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textWhite,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (_waitingForGoogle && _showOAuthEscapeHatch)
                        Positioned(
                          bottom: -92,
                          child: TextButton(
                            onPressed: _cancelGoogleSignIn,
                            child: Text(
                              'Having trouble? Return to sign in',
                              style: GoogleFonts.inter(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
