import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/pin_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _FinSightLogo(
                    escapeHatch: _waitingForGoogle && _showOAuthEscapeHatch
                        ? TextButton(
                            onPressed: _cancelGoogleSignIn,
                            child: Text(
                              'Having trouble? Return to sign in',
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.primary,
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

class _FinSightLogo extends StatelessWidget {
  final Widget? escapeHatch;

  const _FinSightLogo({
    this.escapeHatch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/finsight_logo.png',
          width: 156,
          height: 156,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        if (escapeHatch != null) ...[
          const SizedBox(height: 52),
          escapeHatch!,
        ],
      ],
    );
  }
}
