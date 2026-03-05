import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:naijasingles/common/constants/app_colors.dart';
import 'package:naijasingles/common/constants/theme.dart';

/// Golden tests for the AfroPeep design system.
///
/// These tests call [MyThemes.buildLightTheme] / [MyThemes.buildDarkTheme]
/// with a plain [TextTheme] (no GoogleFonts) so we validate the *exact same*
/// production factory methods — colors, brightness, inputDecoration, appBar,
/// buttons, card/divider colors — without triggering font downloads.
///
/// Generate baselines:
///   flutter test --update-goldens test/golden/
///
/// Subsequent CI runs compare against those baselines.

void main() {
  // ─── Build production themes with system fonts for testing ────────
  // These call the SAME factory methods used by production code.
  // The only difference is the TextTheme (system font vs Montserrat).
  late ThemeData testLight;
  late ThemeData testDark;

  setUpAll(() {
    // Wrap the default LocalFileComparator with 0.5% pixel tolerance.
    // CI (Linux) renders fonts/anti-aliasing slightly differently from macOS,
    // producing ~0.3% diffs that are not visually meaningful.
    final current = goldenFileComparator;
    if (current is LocalFileComparator) {
      goldenFileComparator = _TolerantLocalFileComparator(
        current.basedir,
        tolerance: 0.005,
      );
    }

    const lightText = TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    );
    const darkText = TextTheme(
      displayLarge: TextStyle(
        color: AppColors.darkTextPrimary,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
      bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
    );

    testLight = MyThemes.buildLightTheme(lightText);
    testDark = MyThemes.buildDarkTheme(darkText);
  });

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
      await tester.pumpWidget(themed(testLight, buildSwatch()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/light_theme_swatch.png'),
      );
    });

    testWidgets('Dark theme swatch', (tester) async {
      await tester.pumpWidget(themed(testDark, buildSwatch()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dark_theme_swatch.png'),
      );
    });
  });

  // ─── Unit assertions on production theme factories ────────────────
  // These call buildLightTheme / buildDarkTheme (the SAME code path as
  // production) with a plain TextTheme to avoid GoogleFonts font loading.
  group('Design system – production theme factory assertions', () {
    test('buildLightTheme produces Brightness.light', () {
      expect(testLight.brightness, Brightness.light);
    });

    test('buildDarkTheme produces Brightness.dark', () {
      expect(testDark.brightness, Brightness.dark);
    });

    test('Light scaffold background matches AppColors.backgroundColor', () {
      expect(testLight.scaffoldBackgroundColor, AppColors.backgroundColor);
    });

    test('Dark scaffold background matches AppColors.darkBackground', () {
      expect(testDark.scaffoldBackgroundColor, AppColors.darkBackground);
    });

    test('Dark background differs from light background', () {
      expect(
        testDark.scaffoldBackgroundColor,
        isNot(equals(testLight.scaffoldBackgroundColor)),
      );
    });

    test('Light colorScheme.primary is AppColors.primaryGreen', () {
      expect(testLight.colorScheme.primary, AppColors.primaryGreen);
    });

    test('Dark colorScheme.primary is AppColors.primaryGreenLight', () {
      expect(testDark.colorScheme.primary, AppColors.primaryGreenLight);
    });

    test('Light and dark colorScheme primaries differ', () {
      expect(
        testLight.colorScheme.primary,
        isNot(equals(testDark.colorScheme.primary)),
      );
    });

    test('Dark card color matches AppColors.darkCard', () {
      expect(testDark.cardColor, AppColors.darkCard);
    });

    test('Light card color matches AppColors.cardColor', () {
      expect(testLight.cardColor, AppColors.cardColor);
    });

    test('Dark divider matches AppColors.darkDivider', () {
      expect(testDark.dividerColor, AppColors.darkDivider);
    });

    test('Light appBar background matches AppColors.backgroundColor', () {
      expect(
        testLight.appBarTheme.backgroundColor,
        AppColors.backgroundColor,
      );
    });

    test('Dark appBar background matches AppColors.darkSurface', () {
      expect(testDark.appBarTheme.backgroundColor, AppColors.darkSurface);
    });
  });

  // ─── AppColors token sanity checks ────────────────────────────────
  group('Design system – AppColors token values', () {
    test('Dark tokens have correct hex values', () {
      expect(AppColors.darkBackground, const Color(0xFF121212));
      expect(AppColors.darkSurface, const Color(0xFF1E1E1E));
      expect(AppColors.darkCard, const Color(0xFF2C2C2C));
      expect(AppColors.darkTextPrimary, const Color(0xFFE0E0E0));
      expect(AppColors.darkTextSecondary, const Color(0xFFA0A0A0));
    });

    test('Light tokens have correct values', () {
      expect(AppColors.backgroundColor, Colors.white);
      expect(AppColors.surfaceColor, Colors.white);
      expect(AppColors.cardColor, Colors.white);
      expect(AppColors.primaryGreen, const Color(0xFF008037));
    });

    test('Nav colors are defined', () {
      expect(AppColors.navSelected, AppColors.primaryGreen);
      expect(AppColors.navUnselected, const Color(0xFF666666));
    });
  });
}

/// Golden file comparator that tolerates small pixel differences caused by
/// cross-platform font rendering (macOS vs Linux CI).
class _TolerantLocalFileComparator extends LocalFileComparator {
  _TolerantLocalFileComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent <= tolerance) {
      debugPrint(
        'Golden "$golden": ${result.diffPercent}% diff '
        '(within ${tolerance * 100}% tolerance)',
      );
      return true;
    }
    return result.passed;
  }
}
