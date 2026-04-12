import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:naijasingles/common/constants/app_colors.dart';

/// Layout contract aligned with [AccountSettingsScreen] (section rhythm, row
/// heights, horizontal inset). Uses **system fonts only** so goldens run in
/// `flutter test` without bundling Montserrat (production hub uses GoogleFonts).
///
/// Regenerate baselines after intentional spacing changes:
///   flutter test --update-goldens test/golden/account_settings_hub_golden_test.dart
void main() {
  testWidgets('Account Settings hub layout contract (light) matches golden',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const sectionGap = 18.0;
    const rowH = 54.0;
    const padH = 16.0;

    TextStyle sectionLabel(BuildContext c) => TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Theme.of(c).brightness == Brightness.dark
              ? Colors.grey.shade400
              : AppColors.textSecondary,
        );

    TextStyle rowTitle(BuildContext c) => TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Theme.of(c).brightness == Brightness.dark
              ? Colors.white
              : AppColors.textPrimary,
        );

    TextStyle rowSub(BuildContext c) => TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: Theme.of(c).brightness == Brightness.dark
              ? Colors.grey.shade400
              : AppColors.textSecondary,
        );

    Widget sectionHeader(BuildContext c, String label) => Padding(
          padding: const EdgeInsets.fromLTRB(padH, 0, padH, 8),
          child: Text(label.toUpperCase(), style: sectionLabel(c)),
        );

    Widget row(
      BuildContext c, {
      required String title,
      String? subtitle,
    }) {
      final hasSub = subtitle != null && subtitle.isNotEmpty;
      return SizedBox(
        height: hasSub ? 76 : rowH,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: padH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: rowTitle(c)),
              if (hasSub) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: rowSub(c), maxLines: 2),
              ],
            ],
          ),
        ),
      );
    }

    Widget consequence(BuildContext c, String text) => Padding(
          padding: const EdgeInsets.fromLTRB(padH, 0, padH, 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Theme.of(c).brightness == Brightness.dark
                  ? Colors.grey.shade500
                  : AppColors.textSecondary,
            ),
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.backgroundColor,
        ),
        home: RepaintBoundary(
          key: const ValueKey('account_settings_hub_layout_golden'),
          child: Scaffold(
            backgroundColor: AppColors.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundColor,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                Builder(
                  builder: (c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sectionHeader(c, 'Account'),
                      row(c, title: 'Edit profile', subtitle: 'Photos and info'),
                      const Divider(height: 1),
                      row(
                        c,
                        title: 'Phone & email',
                        subtitle: 'Sign-in contact details',
                      ),
                      const Divider(height: 1),
                      row(
                        c,
                        title: 'Connected accounts',
                        subtitle: 'Google, Apple, and more',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: sectionGap),
                Builder(
                  builder: (c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sectionHeader(c, 'Notifications'),
                      row(
                        c,
                        title: 'Push notifications',
                        subtitle: 'Matches, messages, likes',
                      ),
                      const Divider(height: 1),
                      row(
                        c,
                        title: 'Email notifications',
                        subtitle: 'Product updates and tips',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: sectionGap),
                Builder(
                  builder: (c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      sectionHeader(c, 'Subscription'),
                      consequence(
                        c,
                        'Manage your plan or restore purchases from the '
                        'App Store or Google Play.',
                      ),
                      row(c, title: 'Upgrade', subtitle: 'See plans and benefits'),
                      const Divider(height: 1),
                      row(
                        c,
                        title: 'Manage subscription',
                        subtitle: 'Open store subscriptions',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('account_settings_hub_layout_golden')),
      matchesGoldenFile('goldens/account_settings_hub_light.png'),
    );
  });
}
