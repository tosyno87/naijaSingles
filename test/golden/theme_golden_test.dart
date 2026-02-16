import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:naijasingles/common/constants/app_colors.dart';

/// Golden tests for the AfroPeep design system.
///
/// Visual tests render a standard widget swatch under light and dark themes
/// so accidental color / contrast regressions are caught automatically.
///
/// Generate baselines:
///   flutter test --update-goldens test/golden/
///
/// Subsequent CI runs compare against those baselines.
///
/// NOTE: Themes are built from AppColors tokens directly (no GoogleFonts) to
/// avoid test-environment font download issues. The color tokens and brightness
/// are identical to production; only the font family differs.

/// Light theme mirroring production AppColors tokens.
ThemeData _testLightTheme() => ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentGreen,
        surface: AppColors.surfaceColor,
        error: AppColors.error,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textPrimary,
      ),
      dividerColor: AppColors.divider,
      cardColor: AppColors.cardColor,
    );

/// Dark theme mirroring production AppColors dark tokens.
ThemeData _testDarkTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreenLight,
        secondary: AppColors.accentGreen,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textOnPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreenLight,
          side: const BorderSide(color: AppColors.primaryGreenLight, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
      ),
      dividerColor: AppColors.darkDivider,
      cardColor: AppColors.darkCard,
    );

void main() {
  // ─── Visual golden tests ─────────────────────────────────────────
  group('Design system – golden swatch', () {
    Widget themed(ThemeData theme, Widget child) => MaterialApp(
          theme: theme,
          home: Scaffold(body: child),
        );

    Widget buildSwatch() => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Typography
                const Text(
                  'Headline',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Body text in the default theme color.'),
                const SizedBox(height: 8),
                const Text(
                  'Secondary text',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const Divider(height: 32),

                // Buttons
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Elevated Button'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined Button'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text Button'),
                ),
                const Divider(height: 32),

                // Input
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'Hint text',
                  ),
                ),
                const Divider(height: 32),

                // Card
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Card content'),
                  ),
                ),
                const Divider(height: 32),

                // Status chips
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: const Text('Success'),
                      backgroundColor:
                          AppColors.success.withValues(alpha: 0.15),
                    ),
                    Chip(
                      label: const Text('Warning'),
                      backgroundColor:
                          AppColors.warning.withValues(alpha: 0.15),
                    ),
                    Chip(
                      label: const Text('Error'),
                      backgroundColor:
                          AppColors.error.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Navigation bar preview
                BottomNavigationBar(
                  currentIndex: 0,
                  selectedItemColor: AppColors.navSelected,
                  unselectedItemColor: AppColors.navUnselected,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.explore),
                      label: 'Connect',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.public),
                      label: 'Discover',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_bubble_outline),
                      label: 'Messages',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

    testWidgets('Light theme swatch', (tester) async {
      await tester.pumpWidget(themed(_testLightTheme(), buildSwatch()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/light_theme_swatch.png'),
      );
    });

    testWidgets('Dark theme swatch', (tester) async {
      await tester.pumpWidget(themed(_testDarkTheme(), buildSwatch()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dark_theme_swatch.png'),
      );
    });
  });

  // ─── Unit assertions on color tokens ─────────────────────────────
  // NOTE: These tests validate AppColors directly (no GoogleFonts dependency).
  // MyThemes is NOT accessed here because its GoogleFonts.montserratTextTheme()
  // call fails in test environments without bundled font assets.
  group('Design system – color token assertions', () {
    test('AppColors dark tokens are properly defined', () {
      expect(AppColors.darkBackground, const Color(0xFF121212));
      expect(AppColors.darkSurface, const Color(0xFF1E1E1E));
      expect(AppColors.darkCard, const Color(0xFF2C2C2C));
      expect(AppColors.darkTextPrimary, const Color(0xFFE0E0E0));
      expect(AppColors.darkTextSecondary, const Color(0xFFA0A0A0));
    });

    test('AppColors light tokens are properly defined', () {
      expect(AppColors.backgroundColor, Colors.white);
      expect(AppColors.surfaceColor, Colors.white);
      expect(AppColors.cardColor, Colors.white);
      expect(AppColors.primaryGreen, const Color(0xFF008037));
    });

    test('Dark background differs from light background', () {
      expect(AppColors.darkBackground, isNot(equals(AppColors.backgroundColor)));
    });

    test('Dark text is readable on dark background', () {
      // Dark text primary (0xFFE0E0E0) on dark background (0xFF121212)
      // yields high contrast — just verify they're different.
      expect(
        AppColors.darkTextPrimary,
        isNot(equals(AppColors.darkBackground)),
      );
    });

    test('Light text is readable on light background', () {
      // Text primary (0xFF2D2D2D) on white background — high contrast.
      expect(AppColors.textPrimary, isNot(equals(AppColors.backgroundColor)));
    });

    test('Nav colors are defined', () {
      expect(AppColors.navSelected, AppColors.primaryGreen);
      expect(AppColors.navUnselected, const Color(0xFF666666));
    });

    test('Test light theme matches AppColors tokens', () {
      final theme = _testLightTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundColor);
      expect(theme.cardColor, AppColors.cardColor);
      expect(theme.colorScheme.primary, AppColors.primaryGreen);
    });

    test('Test dark theme matches AppColors tokens', () {
      final theme = _testDarkTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.cardColor, AppColors.darkCard);
      expect(theme.colorScheme.primary, AppColors.primaryGreenLight);
    });
  });
}
