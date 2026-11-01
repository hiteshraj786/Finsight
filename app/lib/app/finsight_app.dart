import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/pin_service.dart';
import '../services/preferences/currency_service.dart';
import '../services/preferences/language_service.dart';
import 'app_router.dart';

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
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
