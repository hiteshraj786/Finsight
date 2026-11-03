import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/pin_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
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
  late Animation<Offset> _finSlideAnimation;
  late Animation<Offset> _sightSlideAnimation;
  late Animation<double> _sparkleAnimation;
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

    _finSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.62, curve: Curves.easeOutCubic),
      ),
    );

    _sightSlideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.92, curve: Curves.easeOutBack),
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
    Navigator.of(context).pushReplacementNamed(
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
      backgroundColor: AppColors.splashBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.splashBackground,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _AnimatedFinSightLogo(
                    finAnimation: _finSlideAnimation,
                    sightAnimation: _sightSlideAnimation,
                    sparkleAnimation: _sparkleAnimation,
                    escapeHatch: _waitingForGoogle && _showOAuthEscapeHatch
                        ? TextButton(
                            onPressed: _cancelGoogleSignIn,
                            child: Text(
                              'Having trouble? Return to sign in',
                              style: GoogleFonts.inter(
                                color: AppColors.splashPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
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

class _AnimatedFinSightLogo extends StatelessWidget {
  final Animation<Offset> finAnimation;
  final Animation<Offset> sightAnimation;
  final Animation<double> sparkleAnimation;
  final Widget? escapeHatch;

  const _AnimatedFinSightLogo({
    required this.finAnimation,
    required this.sightAnimation,
    required this.sparkleAnimation,
    this.escapeHatch,
  });

  @override
  Widget build(BuildContext context) {
    final logoStyle = GoogleFonts.inter(
      fontSize: 64,
      fontWeight: FontWeight.w800,
      letterSpacing: -4,
      height: 0.95,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideTransition(
                  position: finAnimation,
                  child: Text(
                    'fin',
                    style: logoStyle.copyWith(color: AppColors.splashForeground),
                  ),
                ),
                SlideTransition(
                  position: sightAnimation,
                  child: Text(
                    'sight',
                    style: logoStyle.copyWith(color: AppColors.splashPrimary),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -18,
              left: 138,
              child: FadeTransition(
                opacity: sparkleAnimation,
                child: ScaleTransition(
                  scale: sparkleAnimation,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 28,
                    color: AppColors.splashPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (escapeHatch != null) ...[
          const SizedBox(height: 52),
          escapeHatch!,
        ],
      ],
    );
  }
}
