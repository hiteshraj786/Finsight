import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeMode,
      builder: (context, _, _) {
        final dark = AppTheme.isDark(context);
        return IconButton(
          tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: () => AppTheme.setPreference(dark ? 'light' : 'dark'),
          style: IconButton.styleFrom(backgroundColor: scheme.surfaceContainer),
          icon: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
        );
      },
    );
  }
}
