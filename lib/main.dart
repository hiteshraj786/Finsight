import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/pin_service.dart';
import 'core/widgets/auth_guard.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/verification_screen.dart';
import 'features/auth/screens/sign_up_success_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/email_sent_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/enter_pin_screen.dart';
import 'features/setup/screens/setup_account_screen.dart';
import 'features/setup/screens/setup_pin_screen.dart';
import 'features/setup/screens/add_account_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const FinSightApp());
}

class FinSightApp extends StatefulWidget {
  const FinSightApp({super.key});

  @override
  State<FinSightApp> createState() => _FinSightAppState();
}

class _FinSightAppState extends State<FinSightApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;
  String? _routedSessionToken;

  @override
  void initState() {
    super.initState();
    _authSubscription = AuthService.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  Future<void> _onAuthStateChanged(AuthState state) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onAuthStateChanged(state);
      });
      return;
    }
    if (state.event == AuthChangeEvent.passwordRecovery) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.resetPassword, (_) => false);
      return;
    }
    if (state.event == AuthChangeEvent.signedOut) {
      _routedSessionToken = null;
      return;
    }
    if (state.event == AuthChangeEvent.signedIn) {
      final token = state.session?.accessToken;
      if (token != null && token == _routedSessionToken) return;
      _routedSessionToken = token;
      FocusManager.instance.primaryFocus?.unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final hasPin = await PinService.hasPin();
      if (mounted) {
        navigator.pushNamedAndRemoveUntil(
          hasPin ? AppRoutes.unlockPin : AppRoutes.setupAccount,
          (_) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSight',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.splash:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case AppRoutes.signUp:
            return MaterialPageRoute(builder: (_) => const SignUpScreen());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case AppRoutes.verification:
            final email = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => VerificationScreen(email: email),
            );
          case AppRoutes.signUpSuccess:
            return MaterialPageRoute(
              builder: (_) => const SignUpSuccessScreen(),
            );
          case AppRoutes.forgotPassword:
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case AppRoutes.emailSent:
            final email = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => EmailSentScreen(email: email),
            );
          case AppRoutes.resetPassword:
            return MaterialPageRoute(
              builder: (_) => const ResetPasswordScreen(),
            );
          case AppRoutes.setupAccount:
            return MaterialPageRoute(
              builder: (_) => const AuthGuard(child: SetupAccountScreen()),
            );
          case AppRoutes.setupPin:
            return MaterialPageRoute(
              builder: (_) => const AuthGuard(child: SetupPinScreen()),
            );
          case AppRoutes.unlockPin:
            return MaterialPageRoute(
              builder: (_) => const AuthGuard(child: EnterPinScreen()),
            );
          case AppRoutes.addAccount:
            return MaterialPageRoute(
              builder: (_) => const AuthGuard(child: AddAccountScreen()),
            );
          case AppRoutes.home:
            return MaterialPageRoute(
              builder: (_) => const AuthGuard(child: HomeScreen()),
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
