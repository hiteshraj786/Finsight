import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/finance_data_service.dart';
import 'core/services/pin_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/language_service.dart';
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
import 'features/profile/profile_screens.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  await CurrencyService.initialize();
  await LanguageService.initialize();
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
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.selectedLanguage,
      builder: (context, _, child) => ValueListenableBuilder<String>(
        valueListenable: CurrencyService.selected,
        builder: (context, _, child2) => ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeMode,
          builder: (context, themeMode, _) => MaterialApp(
            title: 'FinSight',
            navigatorKey: _navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case AppRoutes.splash:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case AppRoutes.onboarding:
              return MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              );
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
                builder: (_) => AuthGuard(
                  child: SetupPinScreen(
                    isChangingPin: settings.arguments == true,
                  ),
                ),
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
                builder: (_) => const AuthGuard(child: MainShellScreen()),
              );
            case AppRoutes.activity:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: MainShellScreen(initialTab: 1)),
              );
            case AppRoutes.budget:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: MainShellScreen(initialTab: 2)),
              );
            case AppRoutes.profile:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: MainShellScreen(initialTab: 3)),
              );
            case AppRoutes.accounts:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: AccountsScreen()),
              );
            case AppRoutes.accountEditor:
              final account = settings.arguments as FinanceAccount?;
              return MaterialPageRoute(
                builder: (_) =>
                    AuthGuard(child: AccountEditorScreen(account: account)),
              );
            case AppRoutes.accountDetail:
              final accountId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) =>
                    AuthGuard(child: AccountDetailScreen(accountId: accountId)),
              );
            case AppRoutes.settings:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: SettingsScreen()),
              );
            case AppRoutes.currency:
            case AppRoutes.language:
            case AppRoutes.theme:
            case AppRoutes.security:
              // A profile route may be restored by Android without its prior
              // route arguments. Start from safe defaults instead of crashing.
              final preferences =
                  settings.arguments as ProfilePreferences? ??
                  const ProfilePreferences();
              final kind = switch (settings.name) {
                AppRoutes.currency => PreferenceKind.currency,
                AppRoutes.language => PreferenceKind.language,
                AppRoutes.theme => PreferenceKind.theme,
                _ => PreferenceKind.security,
              };
              return MaterialPageRoute(
                builder: (_) => AuthGuard(
                  child: PreferencePickerScreen(
                    kind: kind,
                    preferences: preferences,
                  ),
                ),
              );
            case AppRoutes.notifications:
              return MaterialPageRoute(
                builder: (_) => AuthGuard(
                  child: NotificationSettingsScreen(
                    preferences:
                        settings.arguments as ProfilePreferences? ??
                        const ProfilePreferences(),
                  ),
                ),
              );
            case AppRoutes.exportData:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: ExportDataScreen()),
              );
            case AppRoutes.about:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: AboutScreen()),
              );
            case AppRoutes.help:
              return MaterialPageRoute(
                builder: (_) => const AuthGuard(child: HelpScreen()),
              );
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    ),
    ),
    );
  }
}
