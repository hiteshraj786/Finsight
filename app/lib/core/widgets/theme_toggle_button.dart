import 'package:flutter/material.dart';

import '../../services/backend/profile_service.dart';
import '../theme/app_theme.dart';

/// One-tap switch between light and dark mode. The choice is saved on the
/// device and, when signed in, to the user's profile.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  Future<void> _toggle(BuildContext context) async {
    final next = AppTheme.isDark(context) ? 'light' : 'dark';
    AppTheme.setPreference(next);
    try {
      await ProfileService.updateTheme(next);
    } catch (_) {
      // Already applied and saved locally; the profile syncs next time.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, _, _) {
        final dark = AppTheme.isDark(context);
        return IconButton(
          tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: () => _toggle(context),
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainer,
          ),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                RotationTransition(turns: animation, child: child),
            child: Icon(
              dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(dark),
            ),
          ),
        );
      },
    );
  }
}
